import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final StorageService storageService;

  const ProfileImagePicker({super.key, required this.storageService});

  @override
  _ProfileImagePickerState createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      String? imageUrl = await widget.storageService.uploadImage(_image!);
      if (imageUrl != null) {
        // Enregistrez l'URL de l'image dans votre base de données ou utilisez-la selon vos besoins
        print('Image téléchargée avec succès : $imageUrl');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _image != null
                ? FileImage(_image!)
                : AssetImage('assets/default_image.jpg') as ImageProvider,
          ),
        ),
        ElevatedButton(
          onPressed: _uploadImage,
          child: Text('Télécharger l\'image'),
        ),
      ],
    );
  }
}
