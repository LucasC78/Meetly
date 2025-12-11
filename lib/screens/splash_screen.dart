import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

    // Initialisation des notifications
    FirebaseNotifications.init(context);

    // Redirection après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
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
