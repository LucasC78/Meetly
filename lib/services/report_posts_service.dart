import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPostsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _postRef(String postId) {
    return _db.collection('posts').doc(postId);
  }

  DocumentReference<Map<String, dynamic>> _reportRef(String postId) {
    return _db.collection('posts').doc(postId).collection('reports').doc(_uid);
  }

  /// Signale un post (1 seule fois par user)
  /// Si reportCount >= 2 -> isHidden = true
  Future<void> reportPost(String postId) async {
    final postRef = _postRef(postId);
    final reportRef = _reportRef(postId);

    await _db.runTransaction((tx) async {
      final reportSnap = await tx.get(reportRef);
      if (reportSnap.exists) {
        // déjà signalé -> on ne fait rien
        return;
      }

      // crée le report doc
      tx.set(reportRef, {
        'reportedAt': FieldValue.serverTimestamp(),
        'userId': _uid,
      });

      // met à jour le post
      final postSnap = await tx.get(postRef);
      final data = postSnap.data() ?? {};
      final currentCount = (data['reportCount'] ?? 0) as int;

      final newCount = currentCount + 1;
      final shouldHide = newCount >= 2;

      tx.update(postRef, {
        'reportCount': newCount,
        'isHidden': shouldHide,
      });
    });
  }

  Stream<bool> isReportedByMe(String postId) {
    return _reportRef(postId).snapshots().map((d) => d.exists);
  }
}
