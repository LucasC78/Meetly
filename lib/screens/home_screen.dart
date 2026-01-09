import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:Meetly/widgets/burger_menu.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/widgets/custom_bottom_nav_bar.dart';

import 'package:Meetly/services/saved_posts_service.dart';
import 'package:Meetly/widgets/post_card.dart';

// ✅ AJOUT
import 'package:Meetly/services/block_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userEmail = 'Email non disponible';
  String userName = "Nom de l'utilisateur";
  String? userProfilePicture;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _showCommentInputFor = {};
  final Map<String, int> _visibleCommentCounts = {};

  User? currentUser;

  final SavedPostsService _savedPostsService = SavedPostsService();

  // ✅ AJOUT
  final BlockService _blockService = BlockService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      userEmail = currentUser!.email ?? 'Email non disponible';
    });

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        userName = (userDoc.data()?['pseudo'] ?? 'Nom inconnu').toString();
        userProfilePicture = userDoc.data()?['profilepicture'];
      });
    }
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('pseudo', isGreaterThanOrEqualTo: query)
        .where('pseudo', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _searchResults = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'pseudo': (doc.data()['pseudo'] ?? '').toString(),
                'email': (doc.data()['email'] ?? '').toString(),
              })
          .toList();
    });
  }

  // ------------------ COMMENTAIRES ------------------ //

  void _addComment(String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (content.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'content': content.trim(),
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentControllers[postId]?.clear();
  }

  Widget _buildCommentInput(String postId) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _commentControllers[postId],
        onSubmitted: (value) => _addComment(postId, value),
        decoration: InputDecoration(
          hintText: "Ajouter un commentaire...",
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          suffixIcon: GestureDetector(
            onTap: () => _addComment(postId, _commentControllers[postId]!.text),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: pinkGradient,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentList(String postId) {
    final visibleCount = _visibleCommentCounts[postId] ?? 3;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final comments = snapshot.data!.docs;
        final totalComments = comments.length;
        final limitedComments = comments.take(visibleCount).toList();

        return Column(
          children: [
            ...limitedComments.map((comment) {
              final data = comment.data() as Map<String, dynamic>;
              final userId = (data['userId'] ?? '').toString();
              final content = (data['content'] ?? '').toString();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  final name =
                      userSnapshot.data?.get('pseudo') ?? 'Utilisateur';

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "$name : ",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(content,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            if (visibleCount < totalComments)
              TextButton(
                onPressed: () {
                  setState(() {
                    _visibleCommentCounts[postId] =
                        (visibleCount + 3).clamp(0, totalComments);
                  });
                },
                child: Text(
                  (totalComments - visibleCount == 1)
                      ? 'Charger 1 commentaire'
                      : 'Charger plus de commentaires',
                ),
              ),
            if (visibleCount > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    _visibleCommentCounts[postId] =
                        (visibleCount - 3).clamp(3, totalComments);
                  });
                },
                child: const Text('Réduire les commentaires'),
              ),
          ],
        );
      },
    );
  }

  // ------------------ BUILD ------------------ //

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: BurgerMenu(
        userId: currentUid,
        onNavigate: (route) => Navigator.pushNamed(context, route),
        onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.secondary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Meetly',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: theme.colorScheme.secondary.withOpacity(0.8),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.secondary),
            onPressed: () => Navigator.pushNamed(context, '/addpost'),
          ),
          IconButton(
            icon: Icon(Icons.message, color: theme.colorScheme.secondary),
            onPressed: () => Navigator.pushNamed(context, '/conversations'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_searchResults[index]['pseudo']),
                  subtitle: Text(_searchResults[index]['email']),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/profiledetail',
                    arguments: _searchResults[index]['id'],
                  ),
                ),
              ),
            )
          else
            // ✅ 1) stream blocked
            Expanded(
              child: StreamBuilder<Set<String>>(
                stream: _blockService.blockedIdsStream(currentUid),
                builder: (context, blockedSnap) {
                  final blocked = blockedSnap.data ?? <String>{};

                  // ✅ 2) stream blockedBy
                  return StreamBuilder<Set<String>>(
                    stream: _blockService.blockedByIdsStream(currentUid),
                    builder: (context, blockedBySnap) {
                      final blockedBy = blockedBySnap.data ?? <String>{};

                      // ✅ 3) stream posts
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final posts = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              final data = post.data() as Map<String, dynamic>;

                              final isHidden =
                                  (data['isHidden'] ?? false) as bool;
                              if (isHidden) return const SizedBox.shrink();

                              final postId = post.id;
                              final content =
                                  (data['content'] ?? '').toString();
                              final imageUrl =
                                  (data['imageUrl'] ?? '').toString();
                              final authorId =
                                  (data['userId'] ?? '').toString();

                              // ✅ FILTRE BLOCAGE (les 2 sens)
                              // - si je l'ai bloqué : je ne vois pas ses posts
                              // - si il m'a bloqué : je ne vois pas ses posts non plus
                              if (blocked.contains(authorId) ||
                                  blockedBy.contains(authorId)) {
                                return const SizedBox.shrink();
                              }

                              _commentControllers.putIfAbsent(
                                postId,
                                () => TextEditingController(),
                              );
                              _visibleCommentCounts.putIfAbsent(
                                  postId, () => 3);

                              final likes =
                                  List<String>.from(data['likes'] ?? []);
                              final isLiked = likes.contains(currentUid);
                              final isInputVisible =
                                  _showCommentInputFor.contains(postId);

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(authorId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData ||
                                      userSnapshot.data == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final userData = (userSnapshot.data!.data()
                                          as Map<String, dynamic>?) ??
                                      {};
                                  final pseudo =
                                      (userData['pseudo'] ?? 'Utilisateur')
                                          .toString();
                                  final profilePicture =
                                      (userData['profilepicture'] ?? '')
                                          .toString();

                                  return PostCard(
                                    postId: postId,
                                    userId: authorId,
                                    username: pseudo,
                                    imageUrl: imageUrl,
                                    description: content,
                                    likeCount: likes.length,
                                    isLiked: isLiked,
                                    userProfilePicture: profilePicture,
                                    onLikePressed: () async {
                                      final postRef = FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(postId);

                                      await FirebaseFirestore.instance
                                          .runTransaction((transaction) async {
                                        final freshSnap =
                                            await transaction.get(postRef);
                                        final updatedLikes = List<String>.from(
                                            (freshSnap.data()?['likes'] ?? [])
                                                as List);

                                        if (updatedLikes.contains(currentUid)) {
                                          updatedLikes.remove(currentUid);
                                        } else {
                                          updatedLikes.add(currentUid);
                                        }

                                        transaction.update(
                                            postRef, {'likes': updatedLikes});
                                      });
                                    },
                                    onCommentIconPressed: () {
                                      setState(() {
                                        if (isInputVisible) {
                                          _showCommentInputFor.remove(postId);
                                        } else {
                                          _showCommentInputFor.add(postId);
                                        }
                                      });
                                    },
                                    onToggleSave: () =>
                                        _savedPostsService.toggleSave(postId),
                                    isSavedStream:
                                        _savedPostsService.isSaved(postId),
                                    commentInput: isInputVisible
                                        ? _buildCommentInput(postId)
                                        : null,
                                    commentsList: isInputVisible
                                        ? _buildCommentList(postId)
                                        : null,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 0) return;
          if (index == 1) Navigator.pushNamed(context, '/search');
          if (index == 2) Navigator.pushNamed(context, '/addpost');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}
