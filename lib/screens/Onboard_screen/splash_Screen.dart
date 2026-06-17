import 'dart:async';
import 'package:client/repository/welcome_repository.dart';
import 'package:client/screens/Farmer/farmer_bottom_nav_bar.dart';
import 'package:client/screens/Onboard_screen/farmer_photo_upload.dart';
import 'package:client/screens/Onboard_screen/login.dart';
import 'package:client/screens/Onboard_screen/onboarding_screen.dart';
import 'package:client/utils/app_storage.dart';
import 'package:client/utils/token_storage.dart';
import 'package:flutter/material.dart';

import '../../global/colortheme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _normalizeMobile(String mobile) {
    final trimmed = mobile.trim();
    if (trimmed.startsWith("+91")) return trimmed.substring(3);
    return trimmed;
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final hasSeenOnboarding = await AppStorage.hasSeenOnboarding();
    if (!mounted) return;
    if (!hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final hasToken = await TokenStorage.hasValidToken();
    if (!mounted) return;
    if (!hasToken) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final details = await ProfileRepository().getProfileDetails();
      if (!mounted) return;

      if (details.data.profileComplete) {
        final profile = details.data.profile;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => FarmerBottomNav(
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
            builder:
                (_) => FarmerPhotoUploadScreen(
                  mobile: _normalizeMobile(details.data.mobileNumber),
                ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                "assets/images/f_logo.png",
                width: 250,
                height: 250,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
