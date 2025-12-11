import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF72585),
                    Color(0xFF7209B7),
                  ], // même que ton thème
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.pinkAccent,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userData!['pseudo'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  style: Theme.of(context).textTheme.bodyMedium,
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
                // 🔹 Bouton Abonnement
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF00FF), Color(0xFF9B30FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF9B30FF),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12), // 🧱 Espace entre les boutons
                // 🔹 Bouton Message
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF00FF), Color(0xFF9B30FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF9B30FF),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
                      icon: const Icon(Icons.message, color: Colors.pinkAccent),
                      label: const Text(
                        "Message privé",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
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
            Expanded(child: _buildUserPosts()),
          ],
        ),
      ),
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

  Widget _buildUserPosts() {
    return StreamBuilder<QuerySnapshot>(
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
          print("⚠️ Aucun post trouvé pour userId: ${widget.userId}");
          return const Center(child: Text('Aucun post disponible.'));
        }

        final docs = snapshot.data!.docs;

        print("✅ ${docs.length} posts trouvés pour userId: ${widget.userId}");

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final post = docs[index];
            final postId = post.id;
            final content = post['content'] ?? '';
            final imageUrl = post['imageUrl'] ?? '';
            final userId = post['userId']; // <- important ici
            final likes = List<String>.from(post['likes'] ?? []);
            final isLiked = likes.contains(currentUserId);

            _commentControllers.putIfAbsent(
              postId,
              () => TextEditingController(),
            );
            _visibleCommentCounts.putIfAbsent(postId, () => 3);
            final isInputVisible = _showCommentInputFor.contains(postId);

            // ✅ récupère les infos de l’auteur du post
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();

                final userDoc = userSnapshot.data!;
                final rawData = userDoc.data();
                final userData =
                    (rawData is Map<String, dynamic>) ? rawData : {};

                final username = userData['pseudo'] ?? 'Utilisateur';
                final userProfilePicture = userData['profilepicture'] ?? '';

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
                    await FirebaseFirestore.instance.runTransaction((
                      transaction,
                    ) async {
                      final freshSnap = await transaction.get(postRef);
                      List<dynamic> updatedLikes = List.from(
                        freshSnap['likes'] ?? [],
                      );
                      if (updatedLikes.contains(currentUserId)) {
                        updatedLikes.remove(currentUserId);
                      } else {
                        updatedLikes.add(currentUserId);
                      }
                      transaction.update(postRef, {'likes': updatedLikes});
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
                  commentInput:
                      isInputVisible ? _buildCommentInput(postId) : null,
                  commentsList:
                      isInputVisible ? _buildCommentList(postId) : null,
                );
              },
            );
          },
        );
      },
    );
  }

  // 🔽 Ajout : méthode pour écrire un commentaire
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
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // 🔽 Ajout : méthode pour afficher les commentaires
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
                child: const Text('Charger plus de commentaires'),
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
                child: const Text('Réduire les commentaires'),
              ),
          ],
        );
      },
    );
  }

  // 🔽 Ajout : méthode pour ajouter un commentaire dans Firestore
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
