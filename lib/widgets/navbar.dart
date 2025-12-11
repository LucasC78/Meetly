import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetly',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavBar(), // Utiliser NavBar personnalisé
      body: Center(
        child: Text('Page d\'accueil'),
      ),
    );
  }
}

// Assurer que NavBar implémente PreferredSizeWidget
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize; // Définir la taille de l'AppBar

  NavBar({super.key}) : preferredSize = Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Meetly'),
      backgroundColor: Colors.deepPurple, // Choisir la couleur que tu veux
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer(); // Ouvre le Drawer (menu burger)
        },
      ),
      actions: [
        // Icône plus (+) pour ajouter un post
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, '/addpost');
          },
        ),

        IconButton(
          icon: const Icon(Icons.message),
          onPressed: () {
            // Naviguer vers la page des conversations
            Navigator.pushNamed(context, '/conversations');
          },
        ),
      ],
    );
  }
}
