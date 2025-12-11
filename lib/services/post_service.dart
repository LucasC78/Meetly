import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost(String content, String imageUrl) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("Aucun utilisateur connecté !");
        return;
      }
      String userId = currentUser.uid;
      await _firestore.collection('posts').add({
        'userId': userId,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [], // Champ likes avec une liste vide par défaut
      });
    } catch (e) {
      print("Erreur lors de la création du post: $e");
    }
  }

  // Ajouter un commentaire à un post
  Future<void> addComment(String postId, String content) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Aucun utilisateur connecté !");
      return;
    }

    // Ajouter un commentaire sous un post spécifique
    await _firestore
        .collection('posts')
        .doc(postId) // Identifiant du post
        .collection('comments') // Sous-collection des commentaires
        .add({
      'userId': currentUser.uid, // String
      'content': content, // String
      'timestamp': FieldValue.serverTimestamp(), // Timestamp
    });
  }
}
