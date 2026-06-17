import 'package:flutter/material.dart';
import 'package:client/global/colortheme.dart';

class TermsConditionsFarmerScreen extends StatelessWidget {
  const TermsConditionsFarmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionTitle("1. Acceptance of Terms"),
            _SectionBody(
              "By using the Apom Logistics Farmer app, you agree to these Terms & Conditions. "
              "If you do not agree, please do not use the app.",
            ),
            _SectionTitle("2. Account & Profile"),
            _SectionBody(
              "You are responsible for keeping your profile information accurate and up to date. "
              "You must not share your login credentials with others.",
            ),
            _SectionTitle("3. Data & Privacy"),
            _SectionBody(
              "We collect and process information required to provide services, including profile "
              "and location details. Use of the app is also subject to our Privacy Policy.",
            ),
            _SectionTitle("4. Service Usage"),
            _SectionBody(
              "You agree to use the app lawfully and not to misuse services, attempt unauthorized "
              "access, or interfere with operations.",
            ),
            _SectionTitle("5. Changes to Terms"),
            _SectionBody(
              "We may update these terms from time to time. Continued use of the app means you "
              "accept the updated terms.",
            ),
            _SectionTitle("6. Contact"),
            _SectionBody(
              "If you have any questions about these terms, please contact support through the "
              "Help & Support section.",
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
    );
  }
}
