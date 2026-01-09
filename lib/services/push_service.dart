import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PushService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'meetly_high',
    'Meetly Notifications',
    description:
        'Notifications Meetly (messages, likes, follows, commentaires)',
    importance: Importance.high,
  );

  /// À appeler UNE FOIS au démarrage (après Firebase.initializeApp)
  static Future<void> init() async {
    // 1) Permissions (surtout iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) iOS : comment afficher en foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        // on gérera le click plus tard (étape 3)
      },
    );

    // 4) Android channel (obligatoire pour high importance)
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5) Listener: message reçu en foreground => on affiche une notif locale
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notif = message.notification;
      if (notif == null) return;

      await _localNotif.show(
        notif.hashCode,
        notif.title ?? 'Meetly',
        notif.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    });
  }
}
