import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/config/api_config.dart';

class LoginRepository {
  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    final url = ApiConfig.getAuthLoginUrl();
    final body = {
      "mobile_number": mobileNumber,
      "role": "farmer",
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Extract OTP if present in response (assuming 'otp' field)
        // Adjust field name based on actual backend response
        final otp = data['otp']?.toString() ?? "NOT_RETURNED";
        
        print("DEBUG: OTP received from backend: $otp");

        // 1. Send SMS
        final smsToken = "87c13d427e12b47a9f6535878483d96a";
        final credit = "2";
        final sender = "STSCBE";
        final messageText =
            "OTP for your Sai Techno Solutions Login Verification is $otp. Do Not Share this with anyone. - Sai Techno Solutions";

        final smsUrl =
              "http://sms.saitechnosolutions.net/sendsms/?token=$smsToken&credit=$credit&sender=$sender&message=$messageText&number=$mobileNumber";
            //"http://sms.saitechnosolutions.net/sendsms/?token=$smsToken&credit=$credit&sender=$sender&message=${Uri.encodeComponent(messageText)}&number=$mobileNumber";

        try {
          final smsResponse = await http.get(Uri.parse(smsUrl));
          if (smsResponse.statusCode == 200) {
            print("DEBUG: SMS Sent Successfully via Gateway");
          } else {
            print("DEBUG: Failed to send SMS via Gateway: ${smsResponse.statusCode}");
          }
        } catch (e) {
          print("DEBUG: Error calling SMS Gateway: $e");
        }

        return data;
      } else {

        final data = jsonDecode(response.body);

        return {
          "success": false,
          "message": data["message"] ?? "Failed to send OTP",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
