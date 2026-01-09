import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/widgets/burger_menu.dart';
import 'package:Meetly/screens/saved_posts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openSavedPosts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedPostsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: BurgerMenu(
        userId: FirebaseAuth.instance.currentUser!.uid,
        onNavigate: (route) => Navigator.pushNamed(context, route),
        onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Paramètres',
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
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSettingTile(
              context,
              icon: Icons.person_outline,
              label: 'Modifier le compte',
              onTap: () => Navigator.pushNamed(context, '/editprofile'),
            ),

            // ✅ Posts enregistrés (route directe, plus de pushNamed)
            _buildSettingTile(
              context,
              icon: Icons.bookmark_outline,
              label: 'Posts enregistrés',
              onTap: () => _openSavedPosts(context),
            ),

            _buildSettingTile(
              context,
              icon: Icons.lock_outline,
              label: 'Changer le mot de passe',
              onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            ),
            _buildSettingTile(
              context,
              icon: Icons.info_outline,
              label: 'À propos',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Meetly',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 Meetly',
                );
              },
            ),
            _buildSettingTile(
              context,
              icon: Icons.logout,
              label: 'Se déconnecter',
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121429),
        borderRadius: BorderRadius.circular(24),
        boxShadow: darkGlowShadow,
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: pinkGradient,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor ?? darkTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: darkTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
