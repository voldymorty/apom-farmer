import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static const _storage = FlutterSecureStorage();
  static const _onboardingSeenKey = 'onboarding_seen';

  static Future<void> setOnboardingSeen(bool seen) async {
    await _storage.write(key: _onboardingSeenKey, value: seen ? "1" : "0");
  }

  static Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _onboardingSeenKey);
    return value == "1" || value?.toLowerCase() == "true";
  }
}

