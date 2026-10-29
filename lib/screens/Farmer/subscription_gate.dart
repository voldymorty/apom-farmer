import 'package:client/global/colortheme.dart';
import 'package:client/repository/subscription_repository.dart';
import 'package:client/screens/Farmer/subscription_paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a gated screen (Home dashboard, Add Crop) with a live subscription
/// check, matching the module spec: "no listing/dashboard access at all if
/// subscription has lapsed, checked live, no background job needed."
///
/// Shows [child] only when the farmer currently has access; otherwise shows
/// [SubscriptionPaywallScreen] with the appropriate reason.
class SubscriptionGate extends ConsumerWidget {
  final Widget child;

  const SubscriptionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return statusAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Couldn't check your subscription status.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(subscriptionStatusProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (status) {
        if (status.hasAccess) return child;

        return SubscriptionPaywallScreen(
          status: status,
          onResolved: () => ref.invalidate(subscriptionStatusProvider),
        );
      },
    );
  }
}