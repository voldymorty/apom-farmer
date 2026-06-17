import 'dart:async';
import 'dart:math';
import 'package:client/screens/Farmer/farmer_bottom_nav_bar.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/models/profile_detail_model.dart';
import 'package:client/repository/welcome_repository.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationSuccessScreen extends ConsumerStatefulWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  ConsumerState<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends ConsumerState<RegistrationSuccessScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  late AnimationController _animationController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _autoNavigateTimer;
  bool _hasNavigated = false;
  ProfileDetailsModel? _profileDetails;

  @override
  void initState() {
    super.initState();

    /// Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();

    /// Main Animation Controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    /// Scale Animation Controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    /// Fade Animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    /// Slide Animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );

    /// Scale Animation (Elastic effect)
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    /// Start animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  void _startAutoNavigateTimer(ProfileDetailsModel details) {
    _profileDetails ??= details;
    _autoNavigateTimer ??= Timer(const Duration(seconds: 5), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    if (_profileDetails == null) return;
    _hasNavigated = true;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (_) => FarmerBottomNav(
              initialLandPartitions:
                  _profileDetails!.data.profile.landSegments
                      .map((e) => e.toJson())
                      .toList(),
              totalLand:
                  double.tryParse(_profileDetails!.data.profile.totalLand) ?? 0,
              landUnit: _profileDetails!.data.profile.landUnit,
            ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    _autoNavigateTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            "$label: $value",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerCard(ProfileDetailsModel details) {
    final profile = details.data.profile;
    final profilePhotoRaw = profile.profilePhotoUrl;
    final profilePhotoUrl =
        (profilePhotoRaw is String && profilePhotoRaw.trim().isNotEmpty)
            ? profilePhotoRaw
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF3FAF5)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage:
                profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            child:
                profilePhotoUrl == null
                    ? Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: AppColors.primaryGreen,
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        profile.locationAddress,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoPill(
                      icon: Icons.landscape,
                      label: "Land",
                      value:
                          "${profile.totalLand} ${profile.landUnit}",
                    ),
                    _infoPill(
                      icon: Icons.grid_view,
                      label: "Partitions",
                      value: "${profile.landSegments.length}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final profileDataAsync = ref.watch(profileDetailsProvider);

    return profileDataAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Error loading profile:\n$err",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(profileDetailsProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (details) {
        _startAutoNavigateTimer(details);

        final fullName = details.data.profile.fullName.trim();
        final firstName =
            fullName.isEmpty ? "Farmer" : fullName.split(RegExp(r"\s+")).first;

        return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          /// Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.1,
              numberOfParticles: 30,
              maxBlastForce: 18,
              minBlastForce: 8,
              gravity: 0.3,
            ),
          ),

          SafeArea(
            child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSize.width * 0.08),
                    child: Column(
                      children: [
                        const Spacer(),

                  /// Animated Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: EdgeInsets.all(AppSize.width * 0.08),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: AppSize.width * 0.28,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Animated Text Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            "Welcome Aboard!",
                            style: TextStyle(
                              fontSize: AppSize.width * 0.075,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Hi $firstName 👋",
                            style: TextStyle(
                              fontSize: AppSize.width * 0.05,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Your farmer registration is successful. Let’s grow together!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSize.width * 0.043,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Animated Card
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildFarmerCard(details),
                    ),
                  ),

                  const Spacer(),

                  /// Animated Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _navigateToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
        );
      },
    );
  }
}
