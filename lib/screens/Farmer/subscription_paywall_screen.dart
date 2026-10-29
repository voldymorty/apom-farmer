import 'package:client/models/subscription_model.dart';
import 'package:client/widgets/subscription_required_view.dart';
import 'package:flutter/material.dart';

/// Thin wrapper around [SubscriptionRequiredView] for the proactive path:
/// used by [SubscriptionGate] once it already has a full
/// [SubscriptionStatusModel] from `/subscriptions/status` (so it can pass
/// along the admin note / expiry date that a live status check has, but a
/// bare 402 response may not). The reactive path (any gated endpoint
/// returning 402 unexpectedly) uses [SubscriptionRequiredView] directly via
/// `buildApiErrorView` in utils/subscription_error_handling.dart.
class SubscriptionPaywallScreen extends StatelessWidget {
  final SubscriptionStatusModel status;
  final VoidCallback onResolved;

  const SubscriptionPaywallScreen({
    super.key,
    required this.status,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    return SubscriptionRequiredView(
      reason: status.reason,
      expiryDate: status.subscription?.expiryDate,
      adminNote: status.subscription?.adminNote,
      onResolved: onResolved,
      embedded: false,
    );
  }
}