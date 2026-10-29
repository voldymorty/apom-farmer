import 'package:flutter/material.dart';
import 'package:client/global/colortheme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:client/screens/Onboard_screen/login.dart';

class AccountDeactivatedScreen extends StatelessWidget {
  final String message;
  final String supportEmail;
  final String supportPhone;

  const AccountDeactivatedScreen({
    super.key,
    this.message =
        "Your account has been deactivated by the administrator. Please contact support if you need assistance.",
    this.supportEmail = "apomcrm@gmail.com",
    this.supportPhone = "+919019814347",
  });

  Future<void> _launch(BuildContext context, Uri uri, String fallback) async {
    final messenger = ScaffoldMessenger.of(context);
    bool opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(fallback)));
    }
  }

  Widget _supportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: BorderSide(color: AppColors.primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 42,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Account Deactivated",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Need help? Contact APOM support.",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _supportButton(
                            icon: Icons.mail_outline_rounded,
                            label: "Email",
                            onTap: () => _launch(
                              context,
                              Uri.parse(
                                'mailto:$supportEmail?subject=${Uri.encodeComponent("Account Deactivated - Reactivation Request")}',
                              ),
                              "Email us at $supportEmail",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _supportButton(
                            icon: Icons.call_outlined,
                            label: "Call",
                            onTap: () => _launch(
                              context,
                              Uri(scheme: 'tel', path: supportPhone),
                              "Call us at $supportPhone",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
