import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId:
                  '489198651862-a7imvgmhhb7mr3op9h2jqv0kfgf1ov24.apps.googleusercontent.com',
            )
          : GoogleSignIn();

      // 🔑 force une session propre
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 🔐 AUTH FIREBASE
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      // 🧠 Firestore : création si premier login
      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final doc = await userDoc.get();

        if (!doc.exists) {
          await userDoc.set({
            'email': user.email,
            'pseudo': user.displayName ?? 'Utilisateur',
            'profilepicture': user.photoURL ?? '',
            'bio': '',
            'following': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } on FirebaseAuthException {
      rethrow; // 🔥 OBLIGATOIRE pour bloquer les doubles comptes
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}




















// // lib/services/auth_service.dart
// // import 'package:firebase_auth/firebase_auth.dart';

// // class AuthService {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   User? get currentUser => _auth.currentUser;

// //   String? get currentUserId => _auth.currentUser?.uid;
// // }

// // lib/services/auth_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       // Étape 1 : Authentification Google
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) return null; // L'utilisateur a annulé

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Étape 2 : Connexion Firebase
//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;

//       // Étape 3 : Vérifie si le document utilisateur existe
//       if (user != null) {
//         DocumentReference userDoc =
//             _firestore.collection('users').doc(user.uid);
//         DocumentSnapshot docSnapshot = await userDoc.get();

//         if (!docSnapshot.exists) {
//           // 🔧 Document inexistant, on le crée
//           await userDoc.set({
//             'email': user.email,
//             'pseudo': user.displayName ?? 'Utilisateur',
//             'profilepicture': user.photoURL ?? '',
//             'bio': '',
//             'following': [],
//           });
//         }
//       }

//       return userCredential;
//     } catch (e) {
//       print('Erreur lors de la connexion Google : $e');
//       return null;
//     }
//   }
// }