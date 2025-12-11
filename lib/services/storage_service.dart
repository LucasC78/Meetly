import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Importation pour détecter la plateforme

class StorageService {
  final String cloudName = 'dzvqcdfdg'; // Remplacez par votre Cloud Name
  final String uploadPreset =
      'flutter_profile_pictures'; // Remplacez par votre Upload Preset

  // Méthode pour uploader une image vers Cloudinary
  Future<String?> uploadImage(File image) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      // Si on est sur une plateforme mobile (Android/iOS), on utilise MultipartRequest
      if (!kIsWeb) {
        // kIsWeb est une constante qui permet de détecter si on est sur le Web
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseData);
          return jsonResponse['secure_url'];
        } else {
          print('Échec de l\'upload de l\'image. Code: ${response.statusCode}');
          return null;
        }
      } else {
        // Pour le Web, on utilise une autre approche compatible avec http.Request
        var request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset;

        // Crée un fichier avec le chemin pour l'upload sur le Web
        var bytes = await image.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes('file', bytes,
            filename: image.uri.pathSegments.last);

        request.files.add(multipartFile);

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = json.decode(responseData);
          return jsonResponse['secure_url'];
        } else {
          print('Échec de l\'upload de l\'image. Code: ${response.statusCode}');
          return null;
        }
      }
    } catch (e) {
      print("Erreur lors de l'upload de l'image : $e");
      rethrow;
    }
  }
}
