import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Meetly/config/theme.dart';

class BurgerMenu extends StatelessWidget {
  final String userId;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLogout;

  const BurgerMenu({
    required this.userId,
    this.onNavigate,
    this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [darkBackground, darkAccent3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [lightBackground, lightAccent3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;

                final photoUrl = data?['profilepicture'];
                final pseudo = data?['pseudo'] ?? 'Utilisateur';

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.secondary,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: theme.scaffoldBackgroundColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pseudo,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.textTheme.titleLarge?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            _buildNavItem(
              icon: Icons.home,
              label: 'Accueil',
              onTap: () => onNavigate?.call('/home'),
            ),
            _buildNavItem(
              icon: Icons.search,
              label: 'Recherche',
              onTap: () => onNavigate?.call('/search'),
            ),
            _buildNavItem(
              icon: Icons.message,
              label: 'Messages',
              onTap: () => onNavigate?.call('/conversations'),
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Profil',
              onTap: () => onNavigate?.call('/profile'),
            ),

            // SETTINGS (simple, en haut)
            _buildNavItem(
              icon: Icons.settings,
              label: 'Paramètres',
              onTap: () => onNavigate?.call('/settings'),
            ),

            const Spacer(),

            // Déconnexion (EN BAS avec le bouton dégradé)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isDark ? darkButtonGradient : lightButtonGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isDark ? darkGlowShadow : lightSoftShadow,
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  onLogout?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.pinkAccent, size: 26),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.pinkAccent,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
