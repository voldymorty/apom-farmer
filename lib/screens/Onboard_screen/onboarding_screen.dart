import 'package:client/screens/Onboard_screen/login.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/utils/app_storage.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      imageUrl: "assets/images/ware.jpg",
      title: "Sell Your\nHarvest",
      subtitle:
          "Easily send your fresh produce directly to us for fair prices and immediate processing.",
      accentColor: AppColors.primaryGreen,
    ),
    _OnboardingPageData(
      imageUrl: "assets/images/track.png",
      title: "Track Every\nShipment",
      subtitle:
          "Real-time updates on your drop-offs. Know exactly when your produce reaches our secure facility.",
      accentColor: AppColors.farmerColor,
    ),
    _OnboardingPageData(
      imageUrl: "assets/images/grow.jpg",
      title: "Grow Your\nBusiness",
      subtitle:
          "Access insights, manage your drop-offs, and scale your farming business with smart tracking tools.",
      accentColor: AppColors.farmerColor,
    ),
  ];

  Future<void> _goToLogin() async {
    await AppStorage.setOnboardingSeen(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    return Scaffold(
      body: Stack(
        children: [
          // ── Pages ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          // ── Skip (top-right) ──
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: _goToLogin,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // ── Bottom controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                28,
                32,
                28,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    _pages[_currentPage].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _pages[_currentPage].subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 6,
                        width: _currentPage == i ? 28 : 6,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Row(
                          key: ValueKey(_currentPage),
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  _currentPage == _pages.length - 1
                                      ? "Get Started"
                                      : "Next",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen image
        Image.asset(
          page.imageUrl, // make sure this is like "assets/images/your_image.png"
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white38,
                  size: 48,
                ),
              ),
            );
          },
        ),
        // Dark overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.75, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.20),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  final String imageUrl;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _OnboardingPageData({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
