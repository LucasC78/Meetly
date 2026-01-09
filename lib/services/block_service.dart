import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedRef(String uid) =>
      _db.collection('users').doc(uid).collection('blocked');

  CollectionReference<Map<String, dynamic>> _blockedByRef(String uid) =>
      _db.collection('users').doc(uid).collection('blockedBy');

  Future<void> blockUser(String currentUid, String targetUid) async {
    if (currentUid == targetUid) return;

    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    // A) moi -> blocked
    batch.set(_blockedRef(currentUid).doc(targetUid), {'blockedAt': now});

    // B) l'autre -> blockedBy (pour qu’il sache qu’il est bloqué)
    batch.set(_blockedByRef(targetUid).doc(currentUid), {'blockedAt': now});

    await batch.commit();
  }

  Future<void> unblockUser(String currentUid, String targetUid) async {
    if (currentUid == targetUid) return;

    final batch = _db.batch();

    batch.delete(_blockedRef(currentUid).doc(targetUid));
    batch.delete(_blockedByRef(targetUid).doc(currentUid));

    await batch.commit();
  }

  // ===== streams bool =====
  Stream<bool> isBlocked(String currentUid, String targetUid) {
    return _blockedRef(currentUid)
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> isBlockedBy(String currentUid, String otherUid) {
    return _blockedByRef(currentUid)
        .doc(otherUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ===== streams list =====
  Stream<Set<String>> blockedIdsStream(String currentUid) {
    return _blockedRef(currentUid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  Stream<Set<String>> blockedByIdsStream(String currentUid) {
    return _blockedByRef(currentUid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }
}
