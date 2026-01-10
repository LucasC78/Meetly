import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // refs
  CollectionReference<Map<String, dynamic>> _blockedRef(String uid) =>
      _db.collection('users').doc(uid).collection('blocked');

  CollectionReference<Map<String, dynamic>> _blockedByRef(String uid) =>
      _db.collection('users').doc(uid).collection('blockedBy');

  /// BLOQUER
  Future<void> blockUser(String currentUid, String targetUid) async {
    if (currentUid == targetUid) return;

    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    // current -> blocked
    batch.set(
      _blockedRef(currentUid).doc(targetUid),
      {
        'blockedUid': targetUid,
        'blockedAt': now,
      },
    );

    // target -> blockedBy
    batch.set(
      _blockedByRef(targetUid).doc(currentUid),
      {
        'blockedUid': currentUid,
        'blockedAt': now,
      },
    );

    await batch.commit();
  }

  /// DÉBLOQUER
  Future<void> unblockUser(String currentUid, String targetUid) async {
    final batch = _db.batch();

    batch.delete(_blockedRef(currentUid).doc(targetUid));
    batch.delete(_blockedByRef(targetUid).doc(currentUid));

    await batch.commit();
  }

  /// streams pour HOME
  Stream<Set<String>> blockedIdsStream(String uid) {
    return _blockedRef(uid).snapshots().map(
          (s) => s.docs.map((d) => d.id).toSet(),
        );
  }

  Stream<Set<String>> blockedByIdsStream(String uid) {
    return _blockedByRef(uid).snapshots().map(
          (s) => s.docs.map((d) => d.id).toSet(),
        );
  }
}
