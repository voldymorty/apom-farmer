import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Check and request notification permission
  static Future<bool> checkAndRequestNotificationPermission() async {
    // For Android 13+ (API 33+)
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
