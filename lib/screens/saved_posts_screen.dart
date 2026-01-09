import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Meetly/services/saved_posts_service.dart';
import 'package:Meetly/widgets/post_card.dart';

class SavedPostsScreen extends StatelessWidget {
  SavedPostsScreen({super.key});

  final SavedPostsService _savedPostsService = SavedPostsService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _removeIfDeleted(String postId) async {
    // si le post n'existe plus, on supprime l'enregistrement
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('savedPosts')
        .doc(postId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Posts enregistrés',
          style: theme.textTheme.displayLarge?.copyWith(
            color: theme.colorScheme.secondary,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: theme.colorScheme.secondary,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _savedPostsService.savedPosts(),
        builder: (context, savedSnap) {
          if (savedSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final savedDocs = savedSnap.data?.docs ?? [];
          if (savedDocs.isEmpty) {
            return Center(
              child: Text(
                "Aucun post enregistré.",
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView.builder(
            itemCount: savedDocs.length,
            itemBuilder: (context, index) {
              final postId = savedDocs[index].id;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
                builder: (context, postSnap) {
                  if (!postSnap.hasData) {
                    return const SizedBox.shrink();
                  }

                  // ✅ Post supprimé => on retire le saved
                  if (!postSnap.data!.exists) {
                    Future.microtask(() => _removeIfDeleted(postId));
                    return const SizedBox.shrink();
                  }

                  final data = postSnap.data!.data()!;
                  final isHidden = (data['isHidden'] ?? false) as bool;
                  if (isHidden) return const SizedBox.shrink();
                  final authorId = (data['userId'] ?? '').toString();
                  final imageUrl = (data['imageUrl'] ?? '').toString();
                  final content = (data['content'] ?? '').toString();
                  final likes = List<String>.from(data['likes'] ?? []);
                  final currentUid =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  final isLiked = likes.contains(currentUid);

                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(authorId)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox.shrink();

                      final userData = userSnap.data!.data() ?? {};
                      final pseudo =
                          (userData['pseudo'] ?? 'Utilisateur').toString();
                      final profilePicture = userData['profilepicture'];

                      return PostCard(
                        postId: postId,
                        username: pseudo,
                        imageUrl: imageUrl,
                        description: content,
                        likeCount: likes.length,
                        isLiked: isLiked,

                        // ✅ Tu peux brancher le like plus tard si tu veux
                        onLikePressed: () {},

                        // ✅ Idem commentaires (tu peux ouvrir une page post detail ensuite)
                        onCommentIconPressed: () {},

                        userProfilePicture: profilePicture,
                        userId: authorId,

                        // ✅ C’EST ÇA QUE TU VEUX :
                        // icône déjà cochée + clic => unsave
                        onToggleSave: () =>
                            _savedPostsService.toggleSave(postId),
                        isSavedStream: _savedPostsService.isSaved(postId),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
