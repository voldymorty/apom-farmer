import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/config/api_config.dart';
import 'package:client/utils/token_storage.dart';

class VerifyOtpRepository {
  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
    required String fcmToken,
  }) async {
    final url = ApiConfig.getAuthVerifyOtpUrl();
    final body = {
      "mobile_number": mobileNumber,
      "otp_code": otp,
      "fcm_token": fcmToken,
    };

    print("DEBUG: Sending OTP: $otp for mobile: $mobileNumber");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      print("DEBUG [VerifyOTP]: Status Code = ${response.statusCode}");
      print("DEBUG [VerifyOTP]: Raw Body = ${response.body}");

      // Token is nested inside data['data']['token']
      final nestedData = data['data'];
      final token = nestedData != null ? nestedData['token'] : null;
      print("DEBUG [VerifyOTP]: Extracted token = $token");

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true &&
          token != null) {
        await TokenStorage.saveToken(accessToken: token);
        print("DEBUG [VerifyOTP]: Token saved successfully!");
      } else {
        print("DEBUG [VerifyOTP]: Token NOT saved. token=$token, success=${data['success']}");
      }

      return data;
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
