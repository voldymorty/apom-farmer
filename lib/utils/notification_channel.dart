import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannelHelper {
  static const String welcomeChannelId = 'welcome_channel';
  static const String welcomeChannelName = 'Welcome Notifications';
  static const String welcomeChannelDescription = 'Notifications for welcome messages';

  static Future<void> createNotificationChannels(
      FlutterLocalNotificationsPlugin notifications,
      ) async {
    if (await notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled() ??
        false) {
      const androidChannel = AndroidNotificationChannel(
        welcomeChannelId,
        welcomeChannelName,
        description: welcomeChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }
}
