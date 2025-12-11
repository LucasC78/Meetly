import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Configuration Firebase
import 'routes.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:Meetly/config/theme.dart'; // <== Ajouté pour accéder à tes thèmes personnalisés

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'dzvqcdfdg',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Par défaut, on démarre en mode clair
  bool _isDarkMode = false;

  // Méthode pour basculer entre les thèmes
  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetly',
      theme: lightTheme, // <-- Thème clair personnalisé
      darkTheme: darkTheme, // <-- Thème sombre personnalisé
      themeMode: ThemeMode.dark, // 👈 forcer le thème sombre
      initialRoute: '/splash',
      routes: Routes.getRoutes(),
      // Pour basculer le thème depuis une autre page,
      // tu peux exposer `toggleTheme()` via un Provider si besoin
    );
  }
}
