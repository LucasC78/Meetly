import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedPostsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _savedRef(String postId) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('savedPosts')
        .doc(postId);
  }

  Future<void> toggleSave(String postId) async {
    final ref = _savedRef(postId);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'savedAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<bool> isSaved(String postId) {
    return _savedRef(postId).snapshots().map((doc) => doc.exists);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> savedPosts() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('savedPosts')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .cast<QuerySnapshot<Map<String, dynamic>>>();
  }
}
