import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:client/config/api_config.dart';
import 'package:client/screens/Farmer/order_details_screen.dart';
import 'package:client/utils/auth_client.dart';
import 'package:client/widgets/custom_snackbar.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Initialize local notifications settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            _handleNotificationTapWithData(data);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing local notification payload: $e');
            }
          }
        }
      },
    );

    // Create the high importance channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    _messaging.onTokenRefresh.listen(_updateTokenOnServer);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      final hasToken = await AuthClient.getAuthToken() != null;
      if (hasToken) {
        final url = ApiConfig.getUpdateFcmTokenUrl();
        final response = await AuthClient.putWithAuth(
          url,
          jsonEncode({'fcm_token': token}),
        );
        if (kDebugMode) {
          print('FCM token updated on server: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM token on server: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground Message: ${message.notification?.title}');
    }

    // Show native local notification banner in foreground
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }

    final context = navigatorKey.currentContext;
    if (context != null) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';

      CustomSnackBar.info(
        context,
        '$title: $body',
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationTap(message),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationTapWithData(message.data);
  }

  void _handleNotificationTapWithData(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('Notification Tapped. Data: $data');
    }

    final screen = data['screen'] ?? data['reference_type'];
    final refIdStr = data['crop_id'] ?? data['reference_id'] ?? data['order_id'];

    if ((screen == 'order_detail' ||
            screen == 'order' ||
            screen == 'crop' ||
            screen == 'pickup') &&
        refIdStr != null) {
      final cropId = int.tryParse(refIdStr.toString());
      if (cropId != null) {
        _navigateToOrderDetail(cropId);
      }
    }
  }

  void _navigateToOrderDetail(int cropId) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(cropId: cropId),
        ),
      );
    }
  }
}
