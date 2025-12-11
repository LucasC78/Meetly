import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleLike(String postId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = _firestore.collection('posts').doc(postId);
    final postSnap = await postRef.get();

    final likes = List<String>.from(postSnap['likes'] ?? []);

    if (likes.contains(userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  Future<void> addComment(String postId, String commentText) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final comment = {
      'userId': userId,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([comment])
    });
  }
}
