import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Meetly/config/theme.dart';
import 'package:Meetly/services/cloudinary_service.dart';
import 'package:Meetly/services/post_service.dart';
import 'package:Meetly/widgets/custom_bottom_nav_bar.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final PostService _postService = PostService();

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _uploadedImageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (kIsWeb) {
      _imageBytes = await pickedFile.readAsBytes();
      _imageFile = null;
    } else {
      _imageFile = File(pickedFile.path);
      _imageBytes = null;
    }

    setState(() {});
    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    String? url;

    try {
      if (kIsWeb && _imageBytes != null) {
        url = await _cloudinaryService.uploadImageWeb(_imageBytes!);
      } else if (_imageFile != null) {
        url = await _cloudinaryService.uploadImage(_imageFile!);
      }
    } catch (_) {
      url = null;
    }

    if (!mounted) return;

    if (url != null) {
      setState(() => _uploadedImageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploadée avec succès !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'upload de l'image")),
      );
    }
  }

  Future<void> _submitPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _postService.createPost(text, _uploadedImageUrl ?? '');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post ajouté !')),
      );

      _postController.clear();
      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _uploadedImageUrl = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'ajout du post")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ plus de dégradé
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ajouter un Post',
          style: theme.textTheme.displayLarge?.copyWith(
            color: isDark ? darkAccent1 : lightAccent1,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // IMAGE PICKER
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _uploadedImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: kIsWeb
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          )
                        : Icon(
                            Icons.add,
                            size: 40,
                            color: theme.colorScheme.secondary,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // CAPTION
              TextField(
                controller: _postController,
                style: theme.textTheme.bodyLarge,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Écris une légende...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // SUBMIT
              _isLoading
                  ? const CircularProgressIndicator()
                  : _buildGradientButton(
                      label: 'Partager',
                      onPressed: _submitPost,
                    ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // ✅ BOTTOM BAR
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/search');
          if (index == 2) return;
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? darkButtonGradient : lightButtonGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? darkGlowShadow : lightSoftShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
