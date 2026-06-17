import 'package:flutter/material.dart';
import 'package:client/global/colortheme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportFarmerScreen extends StatelessWidget {
  const HelpSupportFarmerScreen({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email, String subject) async {
    final Uri url = Uri.parse(
        'mailto:$email?subject=${Uri.encodeComponent(subject)}');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Help & Support",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero / Logo Section ──────────────────────────────────
            _buildHeroSection(),
            // ── About / Info Box ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildAboutBox(),
            ),

            const SizedBox(height: 28),

            // ── Contact Admin Section ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildContactSection(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  //  Hero section — logo centred, soft gradient backdrop
  // ────────────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Column(
      children: [
        // Logo
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/f_logo.png',
              height: 150,
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────
  //  About / Info box
  // ────────────────────────────────────────────────────────────────────
  Widget _buildAboutBox() {
    return Container(

      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.farmerColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.farmerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.farmerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Help & Support",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Info items
          _buildInfoRow(
            Icons.support_agent_rounded,
            "Dedicated Support",
            "Our team is available to assist you with any issues related to your account, orders, and payments.",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.farmerColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────
  //  Contact Admin section
  // ────────────────────────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Contact Admin",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 10),
        _buildContactCard(
          icon: Icons.phone_in_talk_rounded,
          label: "Call Us",
          value: "+91 9019814347",
          badgeColor: const Color(0xFF22C55E),
          onTap: () => _launchPhone("+919019814347"),
        ),
        const SizedBox(height: 10),
        _buildContactCard(
          icon: Icons.email_outlined,
          label: "Email Us",
          value: "apomcrm@gmail.com",
          badgeColor: const Color(0xFF3B82F6),
          onTap: () => _launchEmail(
            "apomcrm@gmail.com",
            "Support Request - Farmer App",
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String value,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.farmerColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.farmerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.farmerColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.farmerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
