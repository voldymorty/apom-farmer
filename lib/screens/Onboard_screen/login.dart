import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:client/screens/Onboard_screen/reg_otp_Screen.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:client/repository/login_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _loginRepository = LoginRepository();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _requestOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mobile = _phoneController.text.trim();
    setState(() => _isLoading = true);

    try {
      final response = await _loginRepository.sendOtp(mobile);
      print("OTP:****************************************$response");

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        CustomSnackBar.success(context, "OTP sent to +91$mobile");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(mobileNumber: "+91$mobile"),
          ),
        );
      } else {
        CustomSnackBar.error(
          context,
          response['message'] ?? "Failed to send OTP",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackBar.show(context, "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: Stack(
        children: [
          // ── Rich layered background ──────────────────────────────────
          _buildBackground(),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: AppSize.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSize.height * 0.05),

                  // Logo card with glass effect
                  ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: _buildLogoCard(),
                  ),

                  SizedBox(height: AppSize.height * 0.025),

                  // Welcome text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildWelcomeText(),
                    ),
                  ),

                  SizedBox(height: AppSize.height * 0.04),

                  // Glass form card
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildGlassFormCard(),
                    ),
                  ),

                  SizedBox(height: AppSize.height * 0.025),

                  // Footer
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFooter(),
                  ),

                  SizedBox(height: AppSize.height * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background with layered blobs ──────────────────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        // Warm base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5EDE8), // warm cream
                Color(0xFFF9FAF7), // app background
                Color(0xFFEDF3EE), // faint green tint
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Large soft blob – top right
        Positioned(
          top: -AppSize.height * 0.08,
          right: -AppSize.width * 0.25,
          child: Container(
            height: AppSize.height * 0.42,
            width: AppSize.height * 0.42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.14),
                  AppColors.primaryGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Medium blob – bottom left
        Positioned(
          bottom: -AppSize.height * 0.06,
          left: -AppSize.width * 0.15,
          child: Container(
            height: AppSize.height * 0.32,
            width: AppSize.height * 0.32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.10),
                  AppColors.primaryGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Small accent blob – center right
        Positioned(
          top: AppSize.height * 0.45,
          right: -AppSize.width * 0.05,
          child: Container(
            height: AppSize.height * 0.18,
            width: AppSize.height * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFAC638).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Logo Card ──────────────────────────────────────────────────────────
  Widget _buildLogoCard() {
    return Center(
      child: Image.asset(
        "assets/images/f_logo.png",
        height: 220,
        width: 200,
        fit: BoxFit.contain,
      ),
    );
  }

  // ── Welcome Text ──────────────────────────────────────────────────────
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Welcome Back",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSize.width * 0.075,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        SizedBox(height: AppSize.height * 0.010),
        Text(
          "Enter your mobile number to continue\nand access your shop portal.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSize.width * 0.038,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Glass Form Card ────────────────────────────────────────────────────
  Widget _buildGlassFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(AppSize.width * 0.06),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.60),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.75),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.08),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section label
                Text(
                  "Mobile Number",
                  style: TextStyle(
                    fontSize: AppSize.width * 0.035,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: AppSize.height * 0.012),

                // Glass input field
                _buildGlassInputField(),

                SizedBox(height: AppSize.height * 0.035),

                // CTA Button
                _buildCtaButton(),

                SizedBox(height: AppSize.height * 0.022),

                // Security badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Secured with OTP verification",
                      style: TextStyle(
                        fontSize: AppSize.width * 0.03,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Glass Input Field ─────────────────────────────────────────────────
  Widget _buildGlassInputField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Prefix
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.width * 0.04,
                  vertical: AppSize.height * 0.012,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: AppColors.divider.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "+91",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSize.width * 0.04,
                      ),
                    ),
                  ],
                ),
              ),

              // Text input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: AppSize.width * 0.045,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: "10-digit number",
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                      fontSize: AppSize.width * 0.042,
                      letterSpacing: 0,
                    ),
                    border: InputBorder.none,
                    counterText: "",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSize.width * 0.04,
                      vertical: AppSize.height * 0.018,
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? "";
                    if (trimmed.isEmpty) return "Please enter mobile number";
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
                      return "Enter valid 10-digit number";
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CTA Button ────────────────────────────────────────────────────────
  Widget _buildCtaButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _requestOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.38),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle gloss overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Expanded(
                      child: Center(
                        child: const Text(
                          "Get OTP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.divider.withOpacity(0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "By continuing",
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: AppSize.width * 0.03,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.divider.withOpacity(0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.height * 0.012),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "you agree to our ",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSize.width * 0.032,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                "Terms of Service",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: AppSize.width * 0.032,
                  fontWeight: FontWeight.w600,
                  decorationColor: AppColors.primaryGreen.withOpacity(0.4),
                ),
              ),
            ),
            // Text(
            //   " & ",
            //   style: TextStyle(
            //     color: AppColors.textSecondary,
            //     fontSize: AppSize.width * 0.032,
            //   ),
            // ),
            // GestureDetector(
            //   onTap: () {},
            //   child: Text(
            //     "Privacy Policy",
            //     style: TextStyle(
            //       color: AppColors.primaryGreen,
            //       fontSize: AppSize.width * 0.032,
            //       fontWeight: FontWeight.w600,
            //       decoration: TextDecoration.underline,
            //       decorationColor: AppColors.primaryGreen.withOpacity(0.4),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
