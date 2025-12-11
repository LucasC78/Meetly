import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Meetly/widgets/burger_menu.dart';
import 'package:Meetly/config/theme.dart';
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
  Map<String, TextEditingController> _commentControllers = {};
  Set<String> _showCommentInputFor = {};
  Map<String, int> _visibleCommentCounts = {};
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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
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
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('pseudo', isGreaterThanOrEqualTo: query)
        .where('pseudo', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    setState(() {
      _searchResults = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'pseudo': doc['pseudo'],
              'email': doc['email'],
            },
          )
          .toList();
    });
  }

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
                gradient: const LinearGradient(
                  colors: [Color(0xFFF72585), Color(0xFF7209B7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 3),
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
    int visibleCount = _visibleCommentCounts[postId] ?? 3;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final comments = snapshot.data!.docs;
        final totalComments = comments.length;
        final visibleComments = comments.take(visibleCount).toList();

        return Column(
          children: [
            ...visibleComments.map((comment) {
              final data = comment.data() as Map<String, dynamic>;
              final userId = data['userId'] ?? '';
              final content = data['content'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {
                  final name = snapshot.data?.get('pseudo') ?? 'Utilisateur';
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
                    _visibleCommentCounts[postId] = (visibleCount + 3).clamp(
                      0,
                      totalComments,
                    );
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
                    _visibleCommentCounts[postId] = (visibleCount - 3).clamp(
                      3,
                      totalComments,
                    );
                  });
                },
                child: Text(
                  (visibleCount - 3 <= 0)
                      ? 'Réduire les commentaires'
                      : 'Réduire les commentaires',
                ),
              ),
          ],
        );
      },
    );
  }

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
            icon: const Icon(Icons.menu, color: Colors.pinkAccent),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Meetly',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
            shadows: [Shadow(blurRadius: 12, color: Colors.pinkAccent)],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.pinkAccent),
            onPressed: () => Navigator.pushNamed(context, '/addpost'),
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.pinkAccent),
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
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var post = snapshot.data!.docs[index];
                      final postId = post.id;
                      _commentControllers.putIfAbsent(
                        postId,
                        () => TextEditingController(),
                      );
                      _visibleCommentCounts.putIfAbsent(postId, () => 3);
                      String content = post['content'] ?? '';
                      String imageUrl = post['imageUrl'] ?? '';
                      String userId = post['userId'] ?? '';
                      List likes = post['likes'] ?? [];
                      bool isLiked = likes.contains(
                        FirebaseAuth.instance.currentUser?.uid,
                      );
                      final isInputVisible = _showCommentInputFor.contains(
                        postId,
                      );
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          final pseudo =
                              userSnapshot.data?.get('pseudo') ?? 'Utilisateur';
                          final profilePicture =
                              userSnapshot.data?.data().toString().contains(
                                            'profilepicture',
                                          ) ==
                                      true
                                  ? userSnapshot.data!['profilepicture']
                                  : null;

                          return PostCard(
                            userId: userId,
                            username: pseudo,
                            imageUrl: imageUrl,
                            content: content,
                            likeCount: likes.length,
                            userProfilePicture: profilePicture, // ✅ ici !
                            isLiked: isLiked,
                            onLikePressed: () async {
                              final userUid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (userUid != null) {
                                final postRef = FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postId);
                                await FirebaseFirestore.instance.runTransaction(
                                  (transaction) async {
                                    final freshSnap = await transaction.get(
                                      postRef,
                                    );
                                    List<dynamic> updatedLikes = List.from(
                                      freshSnap['likes'] ?? [],
                                    );
                                    if (updatedLikes.contains(userUid)) {
                                      updatedLikes.remove(userUid);
                                    } else {
                                      updatedLikes.add(userUid);
                                    }
                                    transaction.update(postRef, {
                                      'likes': updatedLikes,
                                    });
                                  },
                                );
                              }
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
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/search');
          if (index == 2) Navigator.pushNamed(context, '/addpost');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}

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
  final String? userProfilePicture; // 👈 ajoute cette ligne
  final String userId; // 👈 ajoute ça

  const PostCard({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentIconPressed,
    required this.userProfilePicture, // 👈 ajoute ça
    required this.userId, // 👈 n'oublie pas
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF72585), Color(0xFF7209B7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    backgroundImage: userProfilePicture != null &&
                            userProfilePicture!.isNotEmpty
                        ? NetworkImage(userProfilePicture!)
                        : null,
                    child: userProfilePicture == null ||
                            userProfilePicture!.isEmpty
                        ? const Icon(Icons.person, color: Colors.pinkAccent)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/profiledetail',
                      arguments: userId, // <- tu dois passer userId au PostCard
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3, // ou 3/2 selon ton besoin
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
                            ? Colors.pinkAccent
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      onPressed: onLikePressed,
                    ),
                    Text('$likeCount likes', style: theme.textTheme.bodyMedium),
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
