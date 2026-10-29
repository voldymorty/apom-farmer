import 'package:client/utils/subscription_exception.dart';
import 'package:client/widgets/subscription_required_view.dart';
import 'package:flutter/material.dart';

/// Drop this into any error branch — a Riverpod `.when(error: ...)`, or a
/// plain `catch (e)` block that sets error state — to get consistent,
/// friendly subscription-paywall UX instead of a raw API error dump,
/// without re-implementing the reason/CTA logic on every screen.
///
/// A [SubscriptionRequiredException] (see utils/subscription_exception.dart,
/// thrown by repositories via `AuthClient.subscriptionErrorFrom`) renders the
/// shared [SubscriptionRequiredView]. Anything else falls back to the same
/// generic "message + Retry" shape screens already use, so existing
/// non-subscription error handling is unaffected.
Widget buildApiErrorView(
  BuildContext context, {
  required Object error,
  required VoidCallback onRetry,
}) {
  if (error is SubscriptionRequiredException) {
    return SubscriptionRequiredView(
      reason: error.reason,
      expiryDate: error.expiryDate,
      onResolved: onRetry,
      embedded: true,
    );
  }

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    ),
  );
}