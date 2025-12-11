import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init(BuildContext context) async {
    // 🔔 Permission pour iOS/Android 13+
    await _firebaseMessaging.requestPermission();

    // 🔔 Initialisation du plugin local
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // 🎯 Notifications en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 🎯 Tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 👉 Navigue vers une page spécifique (si tu veux)
      Navigator.pushNamed(context, '/notifications');
    });

    // 🎯 Token pour envoyer des messages
    final token = await _firebaseMessaging.getToken();
    print("🔑 FCM Token: $token");
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = notification?.android;

    if (notification != null && android != null) {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
      );
    }
  }
}
