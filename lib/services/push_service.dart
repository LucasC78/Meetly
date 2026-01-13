import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static Future<void> init() async {
    // 1) Permissions (Android 13+ & iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) iOS foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Local notifications init
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotif.initialize(initSettings);

    // 4) Android channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5) Foreground message → notif locale
    FirebaseMessaging.onMessage.listen((message) async {
      final title =
          message.notification?.title ?? message.data['title'] ?? 'Meetly';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      if (title.isEmpty && body.isEmpty) return;

      await _localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
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
      );
    });

    // 6) Click notif (background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // navigation plus tard
    });

    // 7) Click notif (app fermée)
    await FirebaseMessaging.instance.getInitialMessage();
  }
}
