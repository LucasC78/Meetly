import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'routes.dart';

import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/services/push_service.dart';

// ✅ AJOUT : ton écran verify email
import 'package:Meetly/screens/verify_email_screen.dart'; // <-- crée ce fichier si pas encore fait

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await PushService.init();

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'dzvqcdfdg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseRoutes = Routes.getRoutes();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetly',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/splash',

      // ✅ On garde tes routes, et on ajoute verify-email
      routes: {
        ...baseRoutes,
        '/verify-email': (context) => const VerifyEmailScreen(),
      },

      // ✅ BLOQUAGE : interception des navigations
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final user = FirebaseAuth.instance.currentUser;

        // Routes libres (tu peux en ajouter si besoin)
        const freeRoutes = <String>{
          '/splash',
          '/login',
          '/signup',
          '/rgpd',
          '/verify-email',
        };

        // 1) Si non connecté -> pas accès à home et aux écrans protégés
        final isProtected = !freeRoutes.contains(name);
        if (isProtected && user == null) {
          return MaterialPageRoute(
            builder: (_) => baseRoutes['/login']!(context),
            settings: const RouteSettings(name: '/login'),
          );
        }

        // 2) Si connecté MAIS email non vérifié -> redirection vers verify-email
        // (uniquement pour les routes protégées)
        if (isProtected && user != null && !user.emailVerified) {
          return MaterialPageRoute(
            builder: (_) => const VerifyEmailScreen(),
            settings: const RouteSettings(name: '/verify-email'),
          );
        }

        // 3) Sinon -> route normale
        final pageBuilder = baseRoutes[name];
        if (pageBuilder != null) {
          return MaterialPageRoute(
            builder: (_) => pageBuilder(context),
            settings: settings,
          );
        }

        // 4) fallback
        return MaterialPageRoute(
          builder: (_) => baseRoutes['/splash']!(context),
          settings: const RouteSettings(name: '/splash'),
        );
      },
    );
  }
}
