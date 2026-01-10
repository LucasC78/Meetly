import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/screens/chat_screen.dart';
import 'package:Meetly/widgets/post_card.dart';
import 'package:Meetly/services/saved_posts_service.dart';
import 'package:Meetly/services/block_service.dart';

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

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final SavedPostsService _savedPostsService = SavedPostsService();

  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _showCommentInputFor = {};
  final Map<String, int> _visibleCommentCounts = {};
  final BlockService _blockService = BlockService();

  // ✅ BLOCK STATES
  bool _loadingBlockStatus = true;
  bool _iBlockedHim = false; // currentUser -> other
  bool _heBlockedMe = false; // other -> currentUser
  bool get _blockedEitherWay => _iBlockedHim || _heBlockedMe;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([
      fetchUserData(),
      fetchCurrentUserImage(),
      checkIfFollowing(),
      _checkBlockStatus(),
    ]);
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // -----------------------
  // BLOCK REFS
  // -----------------------
  DocumentReference<Map<String, dynamic>> _myBlockRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(widget.userId);
  }

  DocumentReference<Map<String, dynamic>> _hisBlockRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('blocked')
        .doc(currentUserId);
  }

  Future<void> _checkBlockStatus() async {
    setState(() => _loadingBlockStatus = true);

    try {
      final my = await _myBlockRef().get();
      final his = await _hisBlockRef().get();

      if (!mounted) return;
      setState(() {
        _iBlockedHim = my.exists;
        _heBlockedMe = his.exists;
        _loadingBlockStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBlockStatus = false);
    }
  }

  Future<void> _blockUser() async {
    try {
      await _blockService.blockUser(currentUserId, widget.userId);

      if (!mounted) return;
      setState(() => _iBlockedHim = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur bloqué.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur blocage: $e")),
      );
    }
  }

  Future<void> _unblockUser() async {
    try {
      await _blockService.unblockUser(currentUserId, widget.userId);

      if (!mounted) return;
      setState(() => _iBlockedHim = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur débloqué.")),
      );

      await _initAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur déblocage: $e")),
      );
    }
  }

  void _openBlockMenu() {
    final theme = Theme.of(context);

    // Pas de menu blocage si tu regardes ton propre profil
    if (widget.userId == currentUserId) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: theme.brightness == Brightness.dark
                ? darkGlowShadow
                : lightSoftShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_iBlockedHim)
                ListTile(
                  leading:
                      Icon(Icons.lock_open, color: theme.colorScheme.secondary),
                  title: Text(
                    "Débloquer @${userData?['pseudo'] ?? ''}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _unblockUser();
                  },
                )
              else
                ListTile(
                  leading:
                      Icon(Icons.block, color: theme.colorScheme.secondary),
                  title: Text(
                    "Bloquer @${userData?['pseudo'] ?? ''}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  subtitle: const Text(
                      "Tu ne verras plus ses posts / messages (et inversement côté UX)."),
                  onTap: () async {
                    Navigator.pop(context);
                    await _blockUser();
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.close, color: theme.colorScheme.primary),
                title: Text("Annuler", style: theme.textTheme.titleMedium),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------
  // DATA
  // -----------------------
  Future<void> fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        isFollowing = following.contains(widget.userId);
      });
    }
  }

  Future<void> toggleFollow() async {
    // ✅ blocage -> pas follow
    if (_blockedEitherWay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Action impossible : utilisateur bloqué.")),
      );
      return;
    }

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

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (userData == null || _loadingBlockStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Si bloqué dans un sens ou l'autre => écran spécial
    if (_blockedEitherWay) {
      return _buildBlockedProfileScreen(theme);
    }

    final String? profileImageUrl = userData!['profilepicture'];

    return Scaffold(
      appBar: AppBar(
        title: Text("${userData!['pseudo']}"),
        actions: [
          // ✅ menu blocage (3 points)
          IconButton(
            onPressed: _openBlockMenu,
            icon: Icon(Icons.more_horiz, color: theme.colorScheme.primary),
          ),

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
                    final data = post.data() as Map<String, dynamic>;
                    final isHidden = (data['isHidden'] ?? false) as bool;
                    if (isHidden) return const SizedBox.shrink();

                    final postId = post.id;

                    final content = (post['content'] ?? '').toString();
                    final imageUrl = (post['imageUrl'] ?? '').toString();
                    final userId = (post['userId'] ?? '').toString();

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

                        final raw = userSnapshot.data!.data();
                        final ud = (raw is Map<String, dynamic>)
                            ? raw
                            : <String, dynamic>{};

                        final username =
                            (ud['pseudo'] ?? 'Utilisateur').toString();
                        final userProfilePicture =
                            (ud['profilepicture'] ?? '').toString();

                        return PostCard(
                          postId: postId,
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
                              final updatedLikes =
                                  List<String>.from(freshSnap['likes'] ?? []);

                              if (updatedLikes.contains(currentUserId)) {
                                updatedLikes.remove(currentUserId);
                              } else {
                                updatedLikes.add(currentUserId);
                              }

                              transaction.update(postRef, {
                                'likes': updatedLikes,
                              });
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
                          isSavedStream: _savedPostsService.isSaved(postId),
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

  // ✅ Profil bloqué : bouton Débloquer seulement si TU l’as bloqué
  Widget _buildBlockedProfileScreen(ThemeData theme) {
    final msg = _heBlockedMe
        ? "Cet utilisateur t'a bloqué."
        : "Tu as bloqué cet utilisateur.";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          // ✅ si tu l'as bloqué, tu peux aussi débloquer via menu
          if (_iBlockedHim)
            IconButton(
              onPressed: _openBlockMenu,
              icon: Icon(Icons.more_horiz, color: theme.colorScheme.primary),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 64, color: theme.colorScheme.secondary),
              const SizedBox(height: 12),
              Text(
                "Profil bloqué",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (_iBlockedHim)
                ElevatedButton.icon(
                  onPressed: _unblockUser,
                  icon: const Icon(Icons.lock_open),
                  label: const Text("Débloquer cet utilisateur"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Retour"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // HEADER PROFIL
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
            gradient: pinkGradient,
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
          (userData?['pseudo'] ?? '').toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        if (userData?['bio'] != null &&
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
            // ✅ Follow (désactivé si blocage)
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
                  onPressed: _blockedEitherWay ? null : toggleFollow,
                  child: Text(
                    isFollowing ? 'Se désabonner' : 'S\'abonner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _blockedEitherWay
                          ? Colors.grey
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ✅ Message (désactivé si blocage)
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
                  onPressed: _blockedEitherWay
                      ? null
                      : () {
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
                  icon: Icon(
                    Icons.message,
                    color: _blockedEitherWay
                        ? Colors.grey
                        : theme.colorScheme.secondary,
                  ),
                  label: Text(
                    "Message privé",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _blockedEitherWay
                          ? Colors.grey
                          : theme.colorScheme.secondary,
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
  // Commentaires
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
                gradient: pinkGradient,
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
        final visibleComments = comments.take(visibleCount).toList();

        return Column(
          children: [
            ...visibleComments.map((comment) {
              final data = comment.data() as Map<String, dynamic>;
              final uid = (data['userId'] ?? '').toString();
              final content = (data['content'] ?? '').toString();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
                builder: (context, snap) {
                  final name = snap.data?.get('pseudo') ?? 'Utilisateur';
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
