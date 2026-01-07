import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Meetly/config/theme.dart';
import 'package:Meetly/widgets/burger_menu.dart';
import 'package:Meetly/widgets/custom_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userEmail;
  String? userBio;
  String? userPseudo;
  String? userProfilePicture;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    final data = snapshot.data();

    setState(() {
      userEmail = data != null && data.containsKey('email')
          ? data['email']
          : 'Email non disponible';
      userPseudo = data != null && data.containsKey('pseudo')
          ? data['pseudo']
          : 'Pseudo non disponible';
      userProfilePicture = (data != null && data['profilepicture'] != null)
          ? data['profilepicture']
          : null;
      userBio = data != null && data.containsKey('bio')
          ? data['bio']
          : 'Bio non disponible';
    });
  }

  Future<void> _deletePost(String postId) async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Supprimer le post',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ce post ?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post supprimé')),
      );
    }
  }

  Widget _buildUserPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return Center(
            child: Text(
              "Aucun post disponible.",
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final imageUrl = post['imageUrl'] ?? '';
            final postId = post.id;

            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: double.infinity,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: pinkGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.6),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextButton(
                          onPressed: () => _deletePost(postId),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final theme = Theme.of(context);
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> following = data['following'] ?? [];

        if (following.isEmpty) {
          return Center(
            child: Text(
              'Aucun utilisateur suivi.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: following.length,
          itemBuilder: (context, index) {
            final id = following[index];

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();

                final user = snap.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilepicture'] != null
                        ? NetworkImage(user['profilepicture'])
                        : const AssetImage('assets/images/default_images.jpg')
                            as ImageProvider,
                  ),
                  title: Text(user['pseudo'] ?? 'Utilisateur inconnu'),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFollowersList() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final theme = Theme.of(context);
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> followers = data['followers'] ?? [];

        if (followers.isEmpty) {
          return Center(
            child: Text(
              'Aucun follower.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final id = followers[index];

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();

                final user = snap.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilepicture'] != null
                        ? NetworkImage(user['profilepicture'])
                        : const AssetImage('assets/images/default_images.jpg')
                            as ImageProvider,
                  ),
                  title: Text(user['pseudo'] ?? 'Utilisateur inconnu'),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        drawer: BurgerMenu(
          userId: FirebaseAuth.instance.currentUser!.uid,
          onNavigate: (route) => Navigator.pushNamed(context, route),
          onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
        ),

        body: userPseudo == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: Icon(
                                Icons.menu,
                                color: theme.colorScheme.secondary,
                              ),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          Icon(
                            Icons.circle_outlined,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // AVATAR
                      Container(
                        width: 150,
                        height: 150,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: pinkGradient,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          child: userProfilePicture != null &&
                                  userProfilePicture!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    userProfilePicture!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 64,
                                  color: theme.colorScheme.secondary,
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        userPseudo!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        userBio ?? '',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // EDIT PROFILE BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: pinkGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.6),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          width: 180,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/editprofile');
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TABS
                      TabBar(
                        indicatorColor: theme.colorScheme.secondary,
                        labelColor: theme.colorScheme.secondary,
                        unselectedLabelColor:
                            theme.colorScheme.onBackground.withOpacity(0.6),
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Followers'),
                          Tab(text: 'Following'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 500,
                        child: TabBarView(
                          children: [
                            _buildUserPosts(),
                            _buildFollowersList(),
                            _buildFollowingList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

        // ✅ BOTTOM BAR ICI
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: 3, // ✅ PROFIL
          onItemTapped: (index) {
            if (index == 0) Navigator.pushNamed(context, '/home');
            if (index == 1) Navigator.pushNamed(context, '/search');
            if (index == 2) Navigator.pushNamed(context, '/addpost');
            if (index == 3) return;
          },
        ),
      ),
    );
  }
}
