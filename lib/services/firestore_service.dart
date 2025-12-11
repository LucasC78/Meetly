import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📌 Ajouter un utilisateur dans Firestore
  Future<void> addUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  // 📌 Récupérer un utilisateur par son ID
  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // 📌 Ajouter un abonnement (suivre un utilisateur)
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _db.collection('users').doc(currentUserId).update({
      'abonnements': FieldValue.arrayUnion([targetUserId])
    });
    await _db.collection('users').doc(targetUserId).update({
      'abonnes': FieldValue.arrayUnion([currentUserId])
    });
  }

  // 📌 Supprimer un abonnement (se désabonner)
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _db.collection('users').doc(currentUserId).update({
      'abonnements': FieldValue.arrayRemove([targetUserId])
    });
    await _db.collection('users').doc(targetUserId).update({
      'abonnes': FieldValue.arrayRemove([currentUserId])
    });
  }
}
