import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:client/utils/token_storage.dart';
import 'package:client/utils/subscription_exception.dart';
import 'package:client/utils/notification_service.dart';
import 'package:client/screens/Onboard_screen/account_deactivated_screen.dart';

class AuthClient {

  /// Centralized detection for the subscription paywall (HTTP 402).
  /// Returns null for any other status code. Repositories that call
  /// subscription-gated endpoints should check this BEFORE their generic
  /// `statusCode != 200` check, e.g.:
  ///
  ///   final subErr = AuthClient.subscriptionErrorFrom(response);
  ///   if (subErr != null) throw subErr;
  ///   if (response.statusCode != 200) throw Exception(...);
  ///
  /// This keeps 402 parsing in one place instead of duplicated per screen —
  /// pair with `widgets/subscription_required_view.dart` /
  /// `utils/subscription_error_handling.dart` on the UI side.
  static SubscriptionRequiredException? subscriptionErrorFrom(
      http.Response response) {
    if (response.statusCode != 402) return null;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body["data"] ?? const {}) as Map<String, dynamic>;
      final sub = data["subscription"] as Map<String, dynamic>?;

      return SubscriptionRequiredException(
        reason: (data["reason"] ?? '').toString(),
        message: (body["message"] ?? 'An active subscription is required.')
            .toString(),
        expiryDate: sub != null && sub["expiry_date"] != null
            ? DateTime.tryParse(sub["expiry_date"].toString())
            : null,
      );
    } catch (_) {
      // Response wasn't the shape we expected — still a 402, so still block,
      // just without the extra detail.
      return const SubscriptionRequiredException(
        reason: '',
        message: 'An active subscription is required.',
      );
    }
  }

  /// Centralized check for account deactivation (HTTP 403 / account_deactivated)
  static void _checkAccountDeactivated(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map &&
            (body["account_deactivated"] == true ||
                (body["message"]?.toString().toLowerCase().contains("deactivated") ?? false))) {
          TokenStorage.clearToken();
          final nav = NotificationService.navigatorKey.currentState;
          if (nav != null) {
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => AccountDeactivatedScreen(
                  message: body["message"]?.toString() ??
                      "Your account has been deactivated. Access is restricted. Please contact administrator.",
                ),
              ),
              (route) => false,
            );
          }
        }
      } catch (_) {}
    }
  }

  static Future<http.Response> postWithAuth(
      String url, Map<String, dynamic> body) async {

    final accessToken = await TokenStorage.getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body),
    );

    _checkAccountDeactivated(response);
    return response;
  }

  static Future<http.Response> getWithAuth(String url) async {

    final accessToken = await TokenStorage.getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    _checkAccountDeactivated(response);
    return response;
  }

  static Future<http.Response> putWithAuth(String url, String body) async {

    final accessToken = await TokenStorage.getToken();

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    _checkAccountDeactivated(response);
    return response;
  }

  static Future<http.Response> deleteWithAuth(
      String url,
      {Map<String, dynamic>? body}) async {

    final accessToken = await TokenStorage.getToken();

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    _checkAccountDeactivated(response);
    return response;
  }

  static Future<String?> getAuthToken() async {
    return await TokenStorage.getToken();
  }
}