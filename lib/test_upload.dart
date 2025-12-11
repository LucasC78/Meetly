// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:mime/mime.dart';
// import 'package:http_parser/http_parser.dart';

// class CloudinaryUploadPage extends StatefulWidget {
//   const CloudinaryUploadPage({Key? key}) : super(key: key);

//   @override
//   State<CloudinaryUploadPage> createState() => _CloudinaryUploadPageState();
// }

// class _CloudinaryUploadPageState extends State<CloudinaryUploadPage> {
//   File? _image;
//   String? _uploadedImageUrl;

//   final String cloudName = 'dzvqcdfdg'; // remplace par ton cloudName
//   final String uploadPreset = 'flutter_upload'; // ton upload preset

//   final ImagePicker _picker = ImagePicker();

//   Future<void> pickAndUploadImage() async {
//     try {
//       final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//       if (pickedFile == null) return;

//       setState(() {
//         _image = File(pickedFile.path);
//         _uploadedImageUrl = null;
//       });

//       final mimeTypeData = lookupMimeType(_image!.path)?.split('/');
//       if (mimeTypeData == null || mimeTypeData.length != 2) {
//         throw Exception('Impossible de détecter le type MIME');
//       }

//       final uri =
//           Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
//       var request = http.MultipartRequest('POST', uri);
//       request.fields['upload_preset'] = uploadPreset;
//       request.files.add(await http.MultipartFile.fromPath(
//         'file',
//         _image!.path,
//         contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
//       ));

//       final response = await request.send();
//       final respStr = await response.stream.bytesToString();

//       if (response.statusCode == 200) {
//         final secureUrl =
//             RegExp(r'"secure_url":"(.*?)"').firstMatch(respStr)?.group(1);
//         setState(() {
//           _uploadedImageUrl = secureUrl;
//         });
//       } else {
//         throw Exception(
//             'Erreur lors de l\'upload: ${response.statusCode} $respStr');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Upload image Cloudinary')),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (_image != null) Image.file(_image!, width: 200, height: 200),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: pickAndUploadImage,
//                 child: const Text('Choisir une image et uploader'),
//               ),
//               if (_uploadedImageUrl != null) ...[
//                 const SizedBox(height: 20),
//                 const Text('Image uploadée :'),
//                 const SizedBox(height: 10),
//                 Image.network(_uploadedImageUrl!, width: 200),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
