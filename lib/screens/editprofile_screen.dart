import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

            // ✅ 🔽 Ajoute ces lignes ici, depuis Firestore aussi
            _userEmail = userData['email'] ?? '';
            _userName = userData['pseudo'] ?? ''; // ou 'displayName' si tu l’as
          });
        }
      } catch (e) {
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
            .update({
          'bio': bio,
          'pseudo': pseudo,
          if (imageUrl != null) 'profilepicture': imageUrl,
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profile updated')));
      } catch (e) {
        print('Error updating profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_existingImageUrl != null) {
      imageProvider = NetworkImage(_existingImageUrl!);
    } else {
      imageProvider = AssetImage('assets/images/default_image.jpg');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.home),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFF72585), Color(0xFF7209B7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      backgroundImage: (_imageBytes != null ||
                              _imageFile != null ||
                              _existingImageUrl != null)
                          ? imageProvider
                          : null,
                      child: (_imageBytes == null &&
                              _imageFile == null &&
                              _existingImageUrl == null)
                          ? const Icon(Icons.person,
                              color: Colors.pinkAccent, size: 40)
                          : null,
                    ),
                    const Icon(
                      Icons.edit, // ou Icons.camera_alt si tu préfères
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              (_userEmail != null && _userEmail!.isNotEmpty)
                  ? _userEmail!
                  : "Email non défini",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _pseudoController,
              decoration: InputDecoration(labelText: 'Your Pseudo'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: 'Your Bio'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
