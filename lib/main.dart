import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'routes.dart';

import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:Meetly/config/theme.dart';
import 'package:Meetly/services/push_service.dart';

import 'package:Meetly/screens/verify_email_screen.dart';
import 'package:Meetly/screens/chat_screen.dart'; // ✅ IMPORTANT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await PushService.init(); // ✅ OK ici

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

      // ❌ IMPORTANT : on enlève routes: {...baseRoutes}
      // ✅ On gère TOUT ici pour supporter les arguments
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final user = FirebaseAuth.instance.currentUser;

        const freeRoutes = <String>{
          '/splash',
          '/login',
          '/signup',
          '/rgpd',
          '/verify-email',
        };

        final isProtected = !freeRoutes.contains(name);

        // 1) Pas connecté -> redirect login
        if (isProtected && user == null) {
          final loginBuilder = baseRoutes['/login'];
          return MaterialPageRoute(
            builder: (_) => loginBuilder!(context),
            settings: const RouteSettings(name: '/login'),
          );
        }

        // 2) Connecté mais email non vérifié -> verify-email (sauf routes libres)
        if (isProtected && user != null && !user.emailVerified) {
          return MaterialPageRoute(
            builder: (_) => const VerifyEmailScreen(),
            settings: const RouteSettings(name: '/verify-email'),
          );
        }

        // ✅ ROUTE SPECIALE : CHAT avec arguments
        if (name == '/chat') {
          final args = settings.arguments;

          if (args is Map<String, dynamic>) {
            final currentUserId = (args['currentUserId'] ?? '').toString();
            final otherUserId = (args['otherUserId'] ?? '').toString();

            if (currentUserId.isNotEmpty && otherUserId.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => ChatScreen(
                  currentUserId: currentUserId,
                  otherUserId: otherUserId,
                ),
                settings: settings,
              );
            }
          }

          // fallback si args manquants
          return MaterialPageRoute(
            builder: (_) => baseRoutes['/home']!(context),
            settings: const RouteSettings(name: '/home'),
          );
        }

        // ✅ VERIFY EMAIL
        if (name == '/verify-email') {
          return MaterialPageRoute(
            builder: (_) => const VerifyEmailScreen(),
            settings: settings,
          );
        }

        // 3) Route classique
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
