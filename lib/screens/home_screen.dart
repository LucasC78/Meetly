import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Meetly/widgets/burger_menu.dart';
import 'package:Meetly/config/theme.dart'; // ton theme.dart
import 'package:Meetly/widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userEmail = 'Email non disponible';
  String userName = 'Nom de l\'utilisateur';
  String? userProfilePicture;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _showCommentInputFor = {};
  final Map<String, int> _visibleCommentCounts = {};

  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        userEmail = currentUser!.email ?? 'Email non disponible';
      });

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['pseudo'] ?? 'Nom inconnu';
          userProfilePicture = userDoc['profilepicture'];
        });
      }
    }
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
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
                'pseudo': doc['pseudo'],
                'email': doc['email'],
              })
          .toList();
    });
  }

  // ------------------ COMMENTAIRES ------------------ //

  void _addComment(String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && content.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': content,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentControllers[postId]?.clear();
    }
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
                gradient: pinkGradient, // 🔥 dégradé orange global
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
              final userId = data['userId'] ?? '';
              final content = data['content'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  final name =
                      userSnapshot.data?.get('pseudo') ?? 'Utilisateur';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                          child: Text(
                            content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: BurgerMenu(
        userId: FirebaseAuth.instance.currentUser!.uid,
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
          // (optionnel) champ de recherche si tu veux l'afficher
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: TextField(
          //     controller: _searchController,
          //     onChanged: _searchUsers,
          //     decoration: const InputDecoration(
          //       hintText: 'Rechercher un utilisateur...',
          //     ),
          //   ),
          // ),
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final postId = post.id;

                      _commentControllers.putIfAbsent(
                        postId,
                        () => TextEditingController(),
                      );
                      _visibleCommentCounts.putIfAbsent(postId, () => 3);

                      final content = post['content'] ?? '';
                      final imageUrl = post['imageUrl'] ?? '';
                      final userId = post['userId'] ?? '';
                      final likes = List<String>.from(post['likes'] ?? []);
                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      final isLiked = likes.contains(currentUid);
                      final isInputVisible =
                          _showCommentInputFor.contains(postId);

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          final pseudo =
                              userSnapshot.data?.get('pseudo') ?? 'Utilisateur';
                          final profilePicture = userSnapshot.data != null &&
                                  (userSnapshot.data!.data()
                                              as Map<String, dynamic>?)
                                          ?.containsKey('profilepicture') ==
                                      true
                              ? userSnapshot.data!['profilepicture']
                              : null;

                          return PostCard(
                            userId: userId,
                            username: pseudo,
                            imageUrl: imageUrl,
                            content: content,
                            likeCount: likes.length,
                            userProfilePicture: profilePicture,
                            isLiked: isLiked,
                            onLikePressed: () async {
                              final userUid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (userUid == null) return;

                              final postRef = FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(postId);

                              await FirebaseFirestore.instance.runTransaction(
                                (transaction) async {
                                  final freshSnap =
                                      await transaction.get(postRef);
                                  final updatedLikes = List<String>.from(
                                      freshSnap['likes'] ?? []);

                                  if (updatedLikes.contains(userUid)) {
                                    updatedLikes.remove(userUid);
                                  } else {
                                    updatedLikes.add(userUid);
                                  }

                                  transaction
                                      .update(postRef, {'likes': updatedLikes});
                                },
                              );
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
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, // ✅ HOME = 0
        onItemTapped: (index) {
          if (index == 0) return; // ✅ déjà sur home
          if (index == 1) Navigator.pushNamed(context, '/search');
          if (index == 2) Navigator.pushNamed(context, '/addpost');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}

// ==================== POST CARD ==================== //

class PostCard extends StatelessWidget {
  final String username;
  final String imageUrl;
  final String content;
  final int likeCount;
  final bool isLiked;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentIconPressed;
  final Widget? commentInput;
  final Widget? commentsList;
  final String? userProfilePicture;
  final String userId;

  const PostCard({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentIconPressed,
    required this.userProfilePicture,
    required this.userId,
    this.commentInput,
    this.commentsList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? darkGlowShadow : lightSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER USER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: pinkGradient, // dégradé orange
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    backgroundImage: userProfilePicture != null &&
                            userProfilePicture!.isNotEmpty
                        ? NetworkImage(userProfilePicture!)
                        : null,
                    child: (userProfilePicture == null ||
                            userProfilePicture!.isEmpty)
                        ? Icon(Icons.person, color: theme.colorScheme.secondary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/profiledetail',
                      arguments: userId,
                    );
                  },
                  child: Text(
                    username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // IMAGE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    child: Center(child: Text('Image non disponible')),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // TEXTE + ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$username ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      TextSpan(
                        text: content,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? theme.colorScheme.secondary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      onPressed: onLikePressed,
                    ),
                    Text(
                      '$likeCount likes',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.comment,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: onCommentIconPressed,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.bookmark_border,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          if (commentsList != null) commentsList!,
          if (commentInput != null) commentInput!,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
