import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importer ton écran de login
import 'screens/home_screen.dart'; // Importer ton écran d'accueil
import 'screens/signup_screen.dart'; // Assure-toi d'importer le fichier
import 'screens/profile_screen.dart'; // Assure-toi d'importer le fichier
import 'screens/settings_screen.dart';
import 'screens/editprofile_screen.dart';
import 'screens/addpost_screen.dart';
import 'screens/detailprofile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/test_screen.dart';
import 'screens/search_user_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';

class Routes {
  // Définir les routes de ton application
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/login': (context) => LoginScreen(),
      '/signup': (context) => SignUpScreen(),
      '/splash': (context) => const SplashScreen(),
      '/home': (context) => HomeScreen(),
      '/settings': (context) => SettingsScreen(),
      '/profile': (context) => ProfileScreen(), // Route vers la page de profil
      '/editprofile': (context) => EditProfileScreen(),
      '/addpost': (context) => AddPostScreen(),
      '/forgot-password': (context) => const ForgotPasswordScreen(),
      '/test': (context) => UploadScreen(),
      '/search': (context) => const SearchUserScreen(),
      '/profiledetail': (context) {
        final route = ModalRoute.of(context);
        final args = route?.settings.arguments;

        if (args is! String || args.isEmpty) {
          // 🔁 Redirige proprement vers la home si l’argument est manquant ou invalide
          Future.microtask(
              () => Navigator.pushReplacementNamed(context, '/home'));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DetailProfilePage(userId: args);
      },

      '/chat': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, String>?;

        // Vérifie que les arguments sont bien présents et contiennent les clés nécessaires
        if (args == null ||
            !args.containsKey('currentUserId') ||
            !args.containsKey('otherUserId')) {
          // Gérer l'erreur ou afficher un message d'erreur si les arguments sont manquants
          return Scaffold(body: Center(child: Text('Arguments manquants')));
        }

        return ChatScreen(
          currentUserId: args['currentUserId']!,
          otherUserId: args['otherUserId']!,
        );
      },
      '/conversations': (context) => ConversationsScreen(),
      // Assure-toi que la route vers ConversationsScreen est bien ici
      // '/inbox': (context) {
      //   final args =
      //       ModalRoute.of(context)!.settings.arguments as Map<String, String>;
      //   return ChatScreen(
      //     currentUserId: args['currentUserId']!,
      //     otherUserId: args['otherUserId']!,
      //   );
      // },
      '/inbox': (context) {
        final route = ModalRoute.of(context);
        final args = route?.settings.arguments;

        if (args is! Map<String, String> ||
            !args.containsKey('currentUserId') ||
            !args.containsKey('otherUserId')) {
          // ⏳ Redirection safe avec SchedulerBinding (évite blocage)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/conversations');
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return ChatScreen(
          currentUserId: args['currentUserId']!,
          otherUserId: args['otherUserId']!,
        );
      },
    };
  }
}
