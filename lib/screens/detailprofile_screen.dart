import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Meetly/config/theme.dart'; // ✅ pour pinkGradient
import 'package:Meetly/screens/chat_screen.dart';
import 'package:Meetly/widgets/post_card.dart';

class DetailProfilePage extends StatefulWidget {
  final String userId;

  const DetailProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> {
  Map<String, dynamic>? userData;
  bool isFollowing = false;
  int followersCount = 0;
  int followingCount = 0;
  String? currentUserImageUrl;

  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _showCommentInputFor = {};
  final Map<String, int> _visibleCommentCounts = {};

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchCurrentUserImage();
    checkIfFollowing();
  }

  Future<void> fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        userData = data;
        followersCount = (data['followers'] as List?)?.length ?? 0;
        followingCount = (data['following'] as List?)?.length ?? 0;
      });
    }
  }

  Future<void> fetchCurrentUserImage() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        currentUserImageUrl = data?['profilepicture'];
      });
    }
  }

  Future<void> checkIfFollowing() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      final following = List<String>.from(data?['following'] ?? []);
      setState(() {
        isFollowing = following.contains(widget.userId);
      });
    }
  }

  Future<void> toggleFollow() async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);

    if (isFollowing) {
      await userRef.update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([widget.userId]),
      });
      setState(() {
        isFollowing = false;
        followersCount--;
      });
    } else {
      await userRef.update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([widget.userId]),
      });
      setState(() {
        isFollowing = true;
        followersCount++;
      });
    }
  }

  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.isAbsolute;
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final String? profileImageUrl = userData!['profilepicture'];

    return Scaffold(
      appBar: AppBar(
        title: Text("${userData!['pseudo']}"),
        actions: [
          if (currentUserImageUrl != null && currentUserImageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(currentUserImageUrl!),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildHeader(context, profileImageUrl),
                        const SizedBox(height: 24),
                        const Center(child: Text('Aucun post disponible.')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final docs = snapshot.data!.docs;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(context, profileImageUrl),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = docs[index];
                    final postId = post.id;
                    final content = post['content'] ?? '';
                    final imageUrl = post['imageUrl'] ?? '';
                    final userId = post['userId'];
                    final likes = List<String>.from(post['likes'] ?? []);
                    final isLiked = likes.contains(currentUserId);

                    _commentControllers.putIfAbsent(
                      postId,
                      () => TextEditingController(),
                    );
                    _visibleCommentCounts.putIfAbsent(postId, () => 3);
                    final isInputVisible =
                        _showCommentInputFor.contains(postId);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final userDoc = userSnapshot.data!;
                        final rawData = userDoc.data();
                        final ud =
                            (rawData is Map<String, dynamic>) ? rawData : {};

                        final username = ud['pseudo'] ?? 'Utilisateur';
                        final userProfilePicture = ud['profilepicture'] ?? '';

                        return PostCard(
                          userId: userId,
                          username: username,
                          imageUrl: imageUrl,
                          description: content,
                          likeCount: likes.length,
                          isLiked: isLiked,
                          userProfilePicture: userProfilePicture,
                          onLikePressed: () async {
                            final postRef = FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId);
                            await FirebaseFirestore.instance
                                .runTransaction((transaction) async {
                              final freshSnap = await transaction.get(postRef);
                              List<dynamic> updatedLikes =
                                  List.from(freshSnap['likes'] ?? []);
                              if (updatedLikes.contains(currentUserId)) {
                                updatedLikes.remove(currentUserId);
                              } else {
                                updatedLikes.add(currentUserId);
                              }
                              transaction
                                  .update(postRef, {'likes': updatedLikes});
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
                          commentInput: isInputVisible
                              ? _buildCommentInput(postId)
                              : null,
                          commentsList:
                              isInputVisible ? _buildCommentList(postId) : null,
                        );
                      },
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // HEADER PROFIL (orange)
  // =========================
  Widget _buildHeader(BuildContext context, String? profileImageUrl) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: pinkGradient, // ✅ orange
          ),
          child: CircleAvatar(
            backgroundColor: theme.scaffoldBackgroundColor,
            child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          userData!['pseudo'],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        if (userData!['bio'] != null &&
            userData!['bio'].toString().trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              userData!['bio'],
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCountColumn('Abonnés', followersCount),
            const SizedBox(width: 40),
            _buildCountColumn('Abonnements', followingCount),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Bouton Abonnement (orange)
            Container(
              decoration: BoxDecoration(
                gradient: pinkGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.55),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: toggleFollow,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Se désabonner' : 'S\'abonner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ✅ Bouton Message (orange)
            Container(
              decoration: BoxDecoration(
                gradient: pinkGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.55),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          currentUserId: currentUserId,
                          otherUserId: widget.userId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.message, color: theme.colorScheme.secondary),
                  label: Text(
                    "Message privé",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCountColumn(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  // =========================
  // Commentaires (orange)
  // =========================

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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: pinkGradient, // ✅ orange
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
        if (!snapshot.hasData) return const SizedBox.shrink();
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
                    _visibleCommentCounts[postId] =
                        (visibleCount + 3).clamp(0, totalComments);
                  });
                },
                child: const Text('Charger plus de commentaires'),
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
}
