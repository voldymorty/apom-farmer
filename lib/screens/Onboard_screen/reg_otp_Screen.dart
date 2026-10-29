import 'dart:async';
import 'package:client/screens/Onboard_screen/farmer_photo_upload.dart';
import 'package:client/screens/Farmer/farmer_bottom_nav_bar.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/repository/welcome_repository.dart';
import 'package:client/screens/Onboard_screen/account_deactivated_screen.dart';
import 'package:client/screens/Onboard_screen/login.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:client/repository/verifyotp_repository.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;

  const OTPVerificationScreen({super.key, required this.mobileNumber});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
        (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _keyListenerNodes = List.generate(4, (_) => FocusNode());
  final _verifyOtpRepository = VerifyOtpRepository();

  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var node in _keyListenerNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _verifyOTP() async {
    if (_otp.length != 4) {
      CustomSnackBar.show(context, "Please enter complete 4-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mobileForFlow = widget.mobileNumber.startsWith("+91")
          ? widget.mobileNumber.substring(3)
          : widget.mobileNumber;

      final fcmToken = await FirebaseMessaging.instance.getToken();

      final response = await _verifyOtpRepository.verifyOtp(
        mobileNumber: mobileForFlow,
        otp: _otp,
        fcmToken: fcmToken ?? "",
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Show success message
        CustomSnackBar.success(context, "OTP Verified! Welcome to the app.");

        if (!mounted) return;
        setState(() => _isLoading = false);

        try {
          final details = await ProfileRepository().getProfileDetails();
          if (!mounted) return;

          if (details.data.profileComplete) {
            final profile = details.data.profile;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FarmerBottomNav(
                  initialLandPartitions:
                  profile.landSegments.map((e) => e.toJson()).toList(),
                  totalLand: double.tryParse(profile.totalLand) ?? 0,
                  landUnit: profile.landUnit,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FarmerPhotoUploadScreen(mobile: mobileForFlow),
              ),
            );
          }
        } catch (_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FarmerPhotoUploadScreen(mobile: mobileForFlow),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (response['account_deactivated'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AccountDeactivatedScreen(
                message: response['message'] ??
                    "Your account has been deactivated. Access is restricted. Please contact administrator.",
              ),
            ),
          );
        } else {
          CustomSnackBar.show(
            context,
            response['message'] ?? "OTP Verification Failed",
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackBar.show(context, "An error occurred: $e");
    }
  }

  void _resendOTP() {
    if (!_canResend) return;

    // TODO: Call backend to resend OTP
    CustomSnackBar.show(context, "OTP resent! Check your messages.");
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGreen),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen())),
        ),
        backgroundColor: AppColors.loginBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  "assets/images/apom_farmer_c.png",
                  height: 240,
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),

              Text(
                "Enter OTP sent to",
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mobileNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 50,
                      height: 60,
                      child: KeyboardListener(
                        focusNode: _keyListenerNodes[index],
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace) {
                            if (_otpControllers[index].text.isEmpty && index > 0) {
                              _otpControllers[index - 1].clear();
                              _focusNodes[index - 1].requestFocus();
                            }
                          }
                        },
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 3) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus();
                              }
                            } else {
                              if (index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    "Verify OTP",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive OTP? ",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: _canResend ? _resendOTP : null,
                    child: Text(
                      _canResend
                          ? "Resend OTP"
                          : "Resend in $_resendCountdown s",
                      style: TextStyle(
                        color: _canResend
                            ? AppColors.primaryGreen
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
