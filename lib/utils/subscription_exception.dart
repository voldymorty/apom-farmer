/// Thrown when the API returns HTTP 402 for a subscription-gated endpoint
/// (see middleware/subscriptionGate.js on the backend).
///
/// Repositories detect this via [AuthClient.subscriptionErrorFrom] and throw
/// it instead of a generic `Exception`, so the UI layer can show a clean
/// subscription message/CTA instead of the raw API response — see
/// `widgets/subscription_required_view.dart` for the reusable UI, and
/// `utils/subscription_error_handling.dart` for the reusable
/// AsyncValue-error helper.
class SubscriptionRequiredException implements Exception {
  /// "none" | "expired" | "flagged" (mirrors the backend's `reason` field).
  final String reason;

  /// Human-readable message from the backend (already farmer-friendly —
  /// see subscriptionGate.js's per-reason messages). Used as a fallback
  /// only; the UI normally derives its own copy from [reason].
  final String message;

  final DateTime? expiryDate;

  const SubscriptionRequiredException({
    required this.reason,
    required this.message,
    this.expiryDate,
  });

  bool get isNone => reason == "none";
  bool get isExpired => reason == "expired";
  bool get isFlagged => reason == "flagged";

  @override
  String toString() => message;
}