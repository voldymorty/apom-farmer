import 'package:client/global/colortheme.dart';
import 'package:client/screens/Farmer/subscription_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The single place that turns a subscription-gate "reason" into copy + a CTA.
///
/// Used two ways:
///  - Proactively, by [SubscriptionGate] (via [SubscriptionPaywallScreen]),
///    after checking `/subscriptions/status` before showing a gated screen.
///  - Reactively, by [buildApiErrorView] (see subscription_error_handling.dart),
///    when a gated endpoint unexpectedly returns HTTP 402 anyway (e.g. the
///    subscription expired in the moments between the proactive check and
///    the actual request).
///
/// Set [embedded] to true when the caller already provides a Scaffold/
/// background (e.g. slotting this into an existing screen's error state),
/// and false for a standalone full screen.
class SubscriptionRequiredView extends StatelessWidget {
  static const String _adminPhone = '9019814347';

  /// "none" | "expired" | "flagged"
  final String reason;
  final DateTime? expiryDate;
  final String? adminNote;

  /// Called after a successful subscribe/renew (from the plan screen), or
  /// wired to a retry/refresh by callers using this reactively.
  final VoidCallback? onResolved;
  final bool embedded;

  const SubscriptionRequiredView({
    super.key,
    required this.reason,
    this.expiryDate,
    this.adminNote,
    this.onResolved,
    this.embedded = false,
  });

  bool get _isFlagged => reason == "flagged";
  bool get _isExpired => reason == "expired";

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _adminPhone);
    await launchUrl(uri);
  }

  Future<void> _goToPlans(BuildContext context) async {
    final activated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SubscriptionPlanScreen()),
    );
    if (activated == true) {
      onResolved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String message;

    if (_isFlagged) {
      icon = Icons.flag_rounded;
      title = "Subscription Flagged";
      message = adminNote?.isNotEmpty == true
          ? adminNote!
          : "Our team has flagged your subscription for review. Please contact support to resolve this.";
    } else if (_isExpired) {
      icon = Icons.event_busy_rounded;
      title = "Subscription Expired";
      message =
          "Your subscription ended on ${_formatDate(expiryDate)}. Renew to continue.";
    } else {
      icon = Icons.workspace_premium_rounded;
      title = "Subscribe to Continue";
      message = "An active subscription is required to access this feature.";
    }

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.farmerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.farmerColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.farmerColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    _isFlagged ? _callSupport : () => _goToPlans(context),
                child: Text(
                  _isFlagged
                      ? "Contact Support"
                      : _isExpired
                          ? "Renew Now"
                          : "View Plans",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(child: content),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "—";
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}