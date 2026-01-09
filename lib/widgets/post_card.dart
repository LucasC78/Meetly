import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Meetly/config/theme.dart';

class PostCard extends StatelessWidget {
  final String postId;

  final String username;
  final String imageUrl;
  final String description;

  final int likeCount;
  final bool isLiked;
  final VoidCallback onLikePressed;

  final VoidCallback onCommentIconPressed;
  final Widget? commentInput;
  final Widget? commentsList;

  final String? userProfilePicture;
  final String userId;

  // ✅ Saved posts (bookmark)
  final VoidCallback onToggleSave;
  final Stream<bool> isSavedStream;

  // ✅ config report
  final int reportThreshold; // ex: 2

  const PostCard({
    super.key,
    required this.postId,
    required this.username,
    required this.imageUrl,
    required this.description,
    required this.likeCount,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentIconPressed,
    required this.userProfilePicture,
    required this.userId,
    required this.onToggleSave,
    required this.isSavedStream,
    this.commentInput,
    this.commentsList,
    this.reportThreshold = 2,
  });

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _reportDocRef() {
    final uid = _currentUid!;
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('reports')
        .doc(uid);
  }

  Future<void> _reportPost(BuildContext context) async {
    final uid = _currentUid;
    if (uid == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final reportRef = _reportDocRef();

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // ✅ 1) TOUS LES READS D'ABORD
        final reportSnap = await tx.get(reportRef);
        if (reportSnap.exists) {
          // déjà signalé -> on stop
          return;
        }

        final postSnap = await tx.get(postRef);
        final data = postSnap.data() as Map<String, dynamic>? ?? {};
        final currentCount =
            (data['reportCount'] is int) ? data['reportCount'] as int : 0;
        final newCount = currentCount + 1;
        final shouldHide = newCount >= reportThreshold;

        // ✅ 2) ENSUITE SEULEMENT LES WRITES
        tx.set(reportRef, {
          'userId': uid,
          'reportedAt': FieldValue.serverTimestamp(),
        });

        tx.update(postRef, {
          'reportCount': newCount,
          if (shouldHide) 'isHidden': true,
        });
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post signalé. Merci 🙏')),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'REPORT FirebaseException: code=${e.code} message=${e.message}',
      );

      if (!context.mounted) return;

      String msg;
      switch (e.code) {
        case 'permission-denied':
          msg = "Signalement refusé (rules Firestore).";
          break;
        case 'not-found':
          msg = "Post introuvable.";
          break;
        default:
          msg = "Erreur signalement (${e.code}) : ${e.message ?? ''}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e, st) {
      // ✅ AUTRES ERREURS (runtime, etc.)
      debugPrint('REPORT unknown error: $e\n$st');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur signalement: $e')),
      );
    }
  }

  void _openReportMenu(BuildContext context, bool alreadyReported) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final theme = Theme.of(context);

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
              ListTile(
                leading: Icon(
                  Icons.report_outlined,
                  color: alreadyReported
                      ? Colors.grey
                      : theme.colorScheme.secondary,
                ),
                title: Text(
                  alreadyReported ? 'Déjà signalé' : 'Signaler ce post',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: alreadyReported
                        ? Colors.grey
                        : theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle:
                    const Text('Si un post est signalé 2 fois, il est masqué.'),
                enabled: !alreadyReported,
                onTap: alreadyReported
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _reportPost(context);
                      },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.close, color: theme.colorScheme.primary),
                title: Text(
                  'Annuler',
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final uid = _currentUid;

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
          // ===== HEADER (avatar + pseudo cliquables + menu 3 points) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // avatar cliquable
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/profiledetail',
                    arguments: userId,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: pinkGradient,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      backgroundImage: (userProfilePicture != null &&
                              userProfilePicture!.isNotEmpty)
                          ? NetworkImage(userProfilePicture!)
                          : null,
                      child: (userProfilePicture == null ||
                              userProfilePicture!.isEmpty)
                          ? Icon(Icons.person,
                              color: theme.colorScheme.secondary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // pseudo cliquable
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/profiledetail',
                      arguments: userId,
                    ),
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ),

                // 3 points (report)
                if (uid != null)
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: _reportDocRef().get(),
                    builder: (context, snap) {
                      final alreadyReported = snap.data?.exists == true;

                      return IconButton(
                        onPressed: () =>
                            _openReportMenu(context, alreadyReported),
                        icon: Icon(
                          Icons.more_horiz,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  )
                else
                  IconButton(
                    onPressed: null,
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),

          // ===== IMAGE =====
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

          // ===== TEXTE + ACTIONS =====
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
                        text: description,
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
                    Text('$likeCount likes', style: theme.textTheme.bodyMedium),
                    const Spacer(),

                    IconButton(
                      icon:
                          Icon(Icons.comment, color: theme.colorScheme.primary),
                      onPressed: onCommentIconPressed,
                    ),

                    // ✅ BOOKMARK synchro (coché si saved)
                    StreamBuilder<bool>(
                      stream: isSavedStream,
                      builder: (context, snap) {
                        final saved = snap.data ?? false;
                        return IconButton(
                          onPressed: onToggleSave,
                          icon: Icon(
                            saved ? Icons.bookmark : Icons.bookmark_border,
                            color: saved
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.primary,
                          ),
                        );
                      },
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
