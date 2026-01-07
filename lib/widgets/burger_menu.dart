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

    // ✅ Intensité du dégradé (baisse si tu veux encore plus soft)
    const double intensity = 0.45;

    final Color darkSoftAccent =
        Color.lerp(darkBackground, darkAccent3, intensity)!;
    final Color lightSoftAccent =
        Color.lerp(lightBackground, lightAccent3, intensity)!;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          // ✅ Dégradé conservé, mais moins violent
          gradient: isDark
              ? LinearGradient(
                  colors: [darkBackground, darkSoftAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [lightBackground, lightSoftAccent],
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
                    // ✅ Avatar avec contour dégradé orange
                    Container(
                      width: 124,
                      height: 124,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: pinkGradient,
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 44,
                                color: theme.colorScheme.secondary,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pseudo,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onBackground,
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
              context: context,
              icon: Icons.home,
              label: 'Accueil',
              onTap: () => onNavigate?.call('/home'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.search,
              label: 'Recherche',
              onTap: () => onNavigate?.call('/search'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.message,
              label: 'Messages',
              onTap: () => onNavigate?.call('/conversations'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person,
              label: 'Profil',
              onTap: () => onNavigate?.call('/profile'),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.settings,
              label: 'Paramètres',
              onTap: () => onNavigate?.call('/settings'),
            ),

            const Spacer(),

            // ✅ Bouton déconnexion : gradient moins intense + contour blanc
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [
                          Color.lerp(darkAccent1, darkAccent2, 0.25)!,
                          Color.lerp(darkAccent2, darkAccent1, 0.25)!,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [
                          Color.lerp(lightAccent1, lightAccent2, 0.25)!,
                          Color.lerp(lightAccent2, lightAccent1, 0.25)!,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.2,
                ),
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
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.secondary,
              size: 26,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.secondary,
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
