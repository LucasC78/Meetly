import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Meetly/config/theme.dart'; // ✅ pour pinkGradient / couleurs thème
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  Uint8List? _imageBytes;

  final _bioController = TextEditingController();
  final _pseudoController = TextEditingController();

  final CloudinaryService _cloudinaryService = CloudinaryService();

  String? _existingImageUrl;
  String? _userEmail;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _pseudoController.text = userData['pseudo'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _existingImageUrl = userData['profilepicture'];

            _userEmail = userData['email'] ?? '';
            _userName = userData['pseudo'] ?? '';
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        _imageBytes = await pickedFile.readAsBytes();
        _imageFile = null;
      } else {
        _imageFile = File(pickedFile.path);
        _imageBytes = null;
      }
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    String bio = _bioController.text;
    String pseudo = _pseudoController.text;

    String? imageUrl;
    if (kIsWeb && _imageBytes != null) {
      imageUrl = await _cloudinaryService.uploadImageWeb(_imageBytes!);
    } else if (_imageFile != null) {
      imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
    } else {
      imageUrl = _existingImageUrl;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(
          {
            'bio': bio,
            'pseudo': pseudo,
            if (imageUrl != null) 'profilepicture': imageUrl,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } catch (e) {
        // ignore: avoid_print
        print('Error updating profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ImageProvider imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingImageUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/default_image.jpg');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon:
                    Icon(Icons.arrow_back, color: theme.colorScheme.secondary),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: Icon(Icons.home, color: theme.colorScheme.secondary),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Avatar (orange)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: pinkGradient, // ✅ orange
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      backgroundImage: imageProvider,
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.35),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              (_userEmail != null && _userEmail!.isNotEmpty)
                  ? _userEmail!
                  : "Email non défini",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // ✅ Pseudo (utilise ton InputDecorationTheme + couleurs thème)
            TextField(
              controller: _pseudoController,
              style: TextStyle(color: theme.colorScheme.onBackground),
              decoration: InputDecoration(
                labelText: 'Your Pseudo',
                labelStyle: TextStyle(color: theme.colorScheme.primary),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Bio
            TextField(
              controller: _bioController,
              style: TextStyle(color: theme.colorScheme.onBackground),
              decoration: InputDecoration(
                labelText: 'Your Bio',
                labelStyle: TextStyle(color: theme.colorScheme.primary),
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Bouton Save (orange)
            Container(
              decoration: BoxDecoration(
                gradient: pinkGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.45),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
