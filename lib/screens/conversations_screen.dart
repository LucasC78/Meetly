import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/widgets/custom_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:Meetly/widgets/burger_menu.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: BurgerMenu(
        userId: FirebaseAuth.instance.currentUser!.uid, // 👈 Obligatoire
        onNavigate: (route) => Navigator.pushNamed(context, route),
        onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Messages',
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: theme.colorScheme.secondary,
              size: 26,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // 👈 Ouvre le menu
            },
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Aucune conversation.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                ),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 150),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final participants = List<String>.from(
                data['participants'] ?? [],
              );
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
              );
              final lastMessage = data['lastMessage'] ?? '';
              final timestamp = data['lastTimestamp'] as Timestamp?;

              return InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/inbox',
                    arguments: {
                      'currentUserId': currentUserId,
                      'otherUserId': otherUserId,
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      NeonAvatar(userId: otherUserId),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: NeonUsername(userId: otherUserId),
                                ),
                                Text(
                                  formatRelativeTime(timestamp),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? darkMessageColor
                                        : theme.colorScheme.primary,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? darkMessageColor
                                    : theme.colorScheme.primary,
                                fontSize: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        // 👈 AJOUTÉ
        selectedIndex: 3, // 👈 Onglet actuel (ex: messages)
        onItemTapped: (index) {
          // 👇 Logique de navigation
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/search');
          if (index == 2) Navigator.pushNamed(context, '/addpost');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}

class NeonAvatar extends StatelessWidget {
  final String userId;
  const NeonAvatar({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final url = data?['profilepicture'];

        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.secondary, theme.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: CircleAvatar(
            backgroundColor: theme.scaffoldBackgroundColor,
            child: ClipOval(
              child: url != null
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Icon(Icons.person, color: theme.colorScheme.secondary),
            ),
          ),
        );
      },
    );
  }
}

class NeonUsername extends StatelessWidget {
  final String userId;
  const NeonUsername({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['pseudo'] ?? 'Utilisateur';

        return Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 25,
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );
  }
}

String formatRelativeTime(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final now = DateTime.now();
  final date = timestamp.toDate();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'À l’instant';
  } else if (difference.inMinutes < 60) {
    return 'Il y a ${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return 'Il y a ${difference.inHours} h';
  } else if (difference.inDays == 1) {
    return 'Hier';
  } else if (difference.inDays <= 7) {
    return 'Il y a ${difference.inDays} j';
  } else {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
