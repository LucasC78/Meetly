import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class CloudinaryService {
  final String cloudName = 'dzvqcdfdg';
  final String uploadPreset = 'flutter_upload';

  // Méthode pour mobile (Android/iOS) avec File
  Future<String?> uploadImage(File imageFile) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final url = RegExp('"secure_url":"(.*?)"').firstMatch(respStr)?.group(1);
      return url;
    } else {
      print('Erreur upload : ${response.statusCode}');
      return null;
    }
  }

  // Méthode pour Flutter Web avec Uint8List (bytes)
  Future<String?> uploadImageWeb(Uint8List imageBytes) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'upload.png',
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final url = RegExp('"secure_url":"(.*?)"').firstMatch(respStr)?.group(1);
      return url;
    } else {
      print('Erreur upload : ${response.statusCode}');
      return null;
    }
  }
}
