import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _normEmail(String email) => email.trim().toLowerCase();

  /// ✅ Empêche 2 docs Firestore d'avoir le même email
  /// -> collection: users_by_email/{emailLower} = { uid, email, createdAt }
  Future<void> reserveEmailOrThrow({
    required String uid,
    required String email,
  }) async {
    final emailKey = _normEmail(email);
    final ref = _db.collection('users_by_email').doc(emailKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (snap.exists) {
        final existingUid = (snap.data()?['uid'] ?? '').toString();

        // email déjà réservé par quelqu’un d’autre => on bloque
        if (existingUid.isNotEmpty && existingUid != uid) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: "Cet email est déjà utilisé par un autre compte.",
          );
        }

        // déjà réservé par toi => ok
        return;
      }

      tx.set(ref, {
        'uid': uid,
        'email': emailKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ✅ Crée / met à jour le profil user sans créer de doublon email
  Future<void> upsertUserProfile({
    required User user,
    required String pseudo,
    String? profilePicture,
  }) async {
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: "Email manquant.",
      );
    }

    // 1) réserve email (anti-doublon Firestore)
    await reserveEmailOrThrow(uid: user.uid, email: email);

    // 2) écrit le profil user
    final userRef = _db.collection('users').doc(user.uid);

    await userRef.set({
      'email': email.trim().toLowerCase(),
      'pseudo': pseudo.trim().isNotEmpty ? pseudo.trim() : 'Utilisateur',
      'profilepicture': profilePicture ?? user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt':
          FieldValue.serverTimestamp(), // merge => ne reset pas si existe
    }, SetOptions(merge: true));
  }

  /// Optionnel : quand tu supprimes un compte, tu peux libérer l’email
  Future<void> releaseEmail({required String email}) async {
    final emailKey = _normEmail(email);
    await _db.collection('users_by_email').doc(emailKey).delete();
  }
}
