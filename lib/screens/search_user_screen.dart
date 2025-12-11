import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Meetly/widgets/custom_bottom_nav_bar.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('pseudo', isGreaterThanOrEqualTo: query)
        .where('pseudo', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _results = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'pseudo': data['pseudo'],
          'profilepicture': data['profilepicture'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Recherche",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            shadows: [
              Shadow(color: theme.colorScheme.secondary, blurRadius: 5),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled:
                      false, // <= assure que le champ n'est pas rempli (donc pas de fond)
                  fillColor:
                      Colors.transparent, // <= au cas où, on force aussi ici
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.cyanAccent),
                  icon: Icon(Icons.search, color: Colors.cyanAccent),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];

                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/profiledetail',
                      arguments: user['id'],
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        NeonAvatarStatic(
                          profilePicture: user['profilepicture'],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user['pseudo'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 25,
                              color: theme.textTheme.titleLarge?.color,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        // 👈 AJOUTÉ
        selectedIndex: 3, // 👈 Onglet actuel (ex: messages)
        onItemTapped: (index) {
          // 👇 Logique de navigation
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/search');
          if (index == 2) Navigator.pushNamed(context, '/addpost');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}

class NeonAvatarStatic extends StatelessWidget {
  final String? profilePicture;
  const NeonAvatarStatic({required this.profilePicture, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.secondary, theme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: ClipOval(
          child: profilePicture != null
              ? Image.network(
                  profilePicture!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Icon(Icons.person, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }
}
