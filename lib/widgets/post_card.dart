import 'package:flutter/material.dart';
import 'package:Meetly/config/theme.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String imageUrl;
  final String description;
  final int likeCount;
  final VoidCallback onLikePressed;
  final bool isLiked;
  final VoidCallback onCommentIconPressed;
  final Widget? commentInput;
  final Widget? commentsList;
  final String? userProfilePicture;
  final String userId;

  const PostCard({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.description,
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
          // 🧑 Nom d'utilisateur
          // 🧑 Photo + Nom d'utilisateur
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
                  padding: const EdgeInsets.all(2), // pour faire la bordure
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
                Text(
                  username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
          ),

          // 🖼️ Image du post
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3, // ou 1.5, 16/9, selon ton image
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      "Image non disponible",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ❤️ Likes + description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📝 Description
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
                const SizedBox(height: 8),
                // ❤️ Like + Count
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
                    Icon(
                      Icons.bookmark_border,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                if (commentsList != null) commentsList!,
                if (commentInput != null) commentInput!,

                const SizedBox(height: 8),

                // 🔽 Voir les commentaires
              ],
            ),
          ),
        ],
      ),
    );
  }
}
