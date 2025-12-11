// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // Tu peux ajouter les autres si besoin :
      // case TargetPlatform.iOS:
      //   return ios;
      // case TargetPlatform.macOS:
      //   return macos;
      default:
        throw UnsupportedError('Cette plateforme n\'est pas supportée.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB184-Y6mVjutJuQJbYk2A3GJi00-rGpl8',
    appId: '1:489198651862:web:XXXXXXXXXX', // ✅ L'appId complet de ton app web
    messagingSenderId: '489198651862',
    projectId: 'meetly-d105b',
    authDomain: 'meetly-d105b.firebaseapp.com',
    databaseURL: 'https://meetly-d105b.firebaseio.com',
    storageBucket: 'meetly-d105b.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB184-Y6mVjutJuQJbYk2A3GJi00-rGpl8',
    appId: '1:489198651862:android:dd9a1f8c3769902547fc77',
    messagingSenderId: '489198651862',
    projectId: 'meetly-d105b',
    storageBucket: 'meetly-d105b.appspot.com',
  );
}
