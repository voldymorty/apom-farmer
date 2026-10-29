import 'dart:convert';

// ── Plans ────────────────────────────────────────────────────────

PlansModel plansModelFromJson(String str) =>
    PlansModel.fromJson(json.decode(str));

class PlansModel {
  final bool success;
  final List<SubscriptionPlan> data;

  PlansModel({required this.success, required this.data});

  factory PlansModel.fromJson(Map<String, dynamic> json) => PlansModel(
        success: json["success"] == true,
        data: ((json["data"] as List<dynamic>?) ?? [])
            .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class SubscriptionPlan {
  final int planId;
  final String planType; // "basic" | "premium"
  final String duration; // "monthly" | "quarterly" | "annual"
  final double price;
  final int durationDays;
  final bool isActive;

  SubscriptionPlan({
    required this.planId,
    required this.planType,
    required this.duration,
    required this.price,
    required this.durationDays,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        planId: _asInt(json["plan_id"]),
        planType: _asString(json["plan_type"]),
        duration: _asString(json["duration"]),
        price: _asDouble(json["price"]) ?? 0,
        durationDays: _asInt(json["duration_days"]),
        isActive: json["is_active"] == true,
      );

  bool get isPremium => planType == "premium";

  String get durationLabel {
    switch (duration) {
      case "monthly":
        return "Monthly";
      case "quarterly":
        return "Quarterly";
      case "annual":
        return "Annual";
      default:
        return duration;
    }
  }

  String get planTypeLabel => isPremium ? "Premium" : "Basic";
}

// ── Status ───────────────────────────────────────────────────────

SubscriptionStatusModel subscriptionStatusModelFromJson(String str) =>
    SubscriptionStatusModel.fromJson(json.decode(str));

class SubscriptionStatusModel {
  final bool success;
  final bool hasAccess;

  /// "none" | "expired" | "flagged" | "active"
  final String reason;
  final SubscriptionSummary? subscription;

  SubscriptionStatusModel({
    required this.success,
    required this.hasAccess,
    required this.reason,
    this.subscription,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    final data = (json["data"] ?? const {}) as Map<String, dynamic>;
    return SubscriptionStatusModel(
      success: json["success"] == true,
      hasAccess: data["has_access"] == true,
      reason: _asString(data["reason"]),
      subscription: data["subscription"] != null
          ? SubscriptionSummary.fromJson(
              data["subscription"] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isNone => reason == "none";
  bool get isExpired => reason == "expired";
  bool get isFlagged => reason == "flagged";
  bool get isActive => hasAccess && subscription != null;
  bool get isPremium => isActive && subscription!.isPremium;
  bool get isBasic => isActive && subscription!.isBasic;
}

class SubscriptionSummary {
  final int subscriptionId;
  final String planType;
  final String duration;
  final String status;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String? adminNote;

  SubscriptionSummary({
    required this.subscriptionId,
    required this.planType,
    required this.duration,
    required this.status,
    this.startDate,
    this.expiryDate,
    this.adminNote,
  });

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) =>
      SubscriptionSummary(
        subscriptionId: _asInt(json["subscription_id"]),
        planType: _asString(json["plan_type"]),
        duration: _asString(json["duration"]),
        status: _asString(json["status"]),
        startDate: _asDate(json["start_date"]),
        expiryDate: _asDate(json["expiry_date"]),
        adminNote: json["admin_note"]?.toString(),
      );

  bool get isPremium => planType == "premium";
  bool get isBasic => planType == "basic";

  String get durationLabel {
    switch (duration) {
      case "monthly":
        return "Monthly";
      case "quarterly":
        return "Quarterly";
      case "annual":
        return "Annual";
      default:
        return duration;
    }
  }

  String get planTypeLabel => isPremium ? "Premium" : "Basic";
}

// ── Initiate / Verify ───────────────────────────────────────────

class SubscriptionInitiateResult {
  final int subscriptionId;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final double amount;
  final String currency;
  final String planType;
  final String duration;
  final String companyName;

  SubscriptionInitiateResult({
    required this.subscriptionId,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.amount,
    required this.currency,
    required this.planType,
    required this.duration,
    required this.companyName,
  });

  factory SubscriptionInitiateResult.fromJson(Map<String, dynamic> json) {
    final data = (json["data"] ?? const {}) as Map<String, dynamic>;
    return SubscriptionInitiateResult(
      subscriptionId: _asInt(data["subscription_id"]),
      razorpayOrderId: _asString(data["razorpay_order_id"]),
      razorpayKeyId: _asString(data["razorpay_key_id"]),
      amount: _asDouble(data["amount"]) ?? 0,
      currency: _asString(data["currency"]).isEmpty
          ? "INR"
          : _asString(data["currency"]),
      planType: _asString(data["plan_type"]),
      duration: _asString(data["duration"]),
      companyName: _asString(data["company_name"]).isEmpty
          ? "Apom Market"
          : _asString(data["company_name"]),
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String _asString(dynamic v) => (v ?? '').toString();

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}