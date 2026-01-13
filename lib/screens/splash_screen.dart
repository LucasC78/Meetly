import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Meetly/firebase_notifications.dart';
import 'package:Meetly/config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Initialisation des notifications
    FirebaseNotifications.init(context);

    // ✅ Decide où aller (home ou login)
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Petit délai pour laisser l’animation respirer
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;

    final user = FirebaseAuth.instance.currentUser;

    // ✅ si l’utilisateur veut rester connecté ET qu’il est encore authentifié
    if (stayLoggedIn && user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Optionnel : si tu veux forcer le logout quand stayLoggedIn = false
      // (ça évite qu’un user reste connecté sans l’avoir demandé)
      if (user != null && !stayLoggedIn) {
        await FirebaseAuth.instance.signOut();
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Center(
          child: Lottie.asset(
            'assets/animations/meetly_intro.json',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
