import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  String? _uploadedImageUrl;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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

  Future<void> _uploadImage() async {
    String? url;
    if (kIsWeb && _imageBytes != null) {
      url = await _cloudinaryService.uploadImageWeb(_imageBytes!);
    } else if (_imageFile != null) {
      url = await _cloudinaryService.uploadImage(_imageFile!);
    }

    if (url != null) {
      setState(() {
        _uploadedImageUrl = url;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload réussi !')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur lors de l\'upload')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (kIsWeb)
              _imageBytes != null
                  ? Image.memory(_imageBytes!, height: 200)
                  : Placeholder(fallbackHeight: 200)
            else
              _imageFile != null
                  ? Image.file(_imageFile!, height: 200)
                  : Placeholder(fallbackHeight: 200),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: _pickImage, child: Text('Choisir une image')),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _uploadImage, child: Text('Uploader')),
            SizedBox(height: 20),
            if (_uploadedImageUrl != null)
              Column(
                children: [
                  Text('Image uploadée :'),
                  SizedBox(height: 10),
                  Image.network(_uploadedImageUrl!),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
