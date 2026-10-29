import 'dart:convert';

import 'package:client/config/api_config.dart';
import 'package:client/models/subscription_model.dart';
import 'package:client/utils/auth_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionRepository {
  Future<PlansModel> getPlans() async {
    final url = ApiConfig.getSubscriptionPlansUrl();

    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load plans (${response.statusCode}): ${response.body}",
      );
    }

    return plansModelFromJson(response.body);
  }

  Future<SubscriptionStatusModel> getStatus() async {
    final url = ApiConfig.getSubscriptionStatusUrl();

    final response = await AuthClient.getWithAuth(url);

    // Unlike other endpoints, 402 here is an expected, meaningful response
    // (no active subscription / expired / flagged) — not a failure to surface.
    if (response.statusCode != 200 && response.statusCode != 402) {
      throw Exception(
        "Failed to load subscription status (${response.statusCode}): ${response.body}",
      );
    }

    return subscriptionStatusModelFromJson(response.body);
  }

  Future<SubscriptionInitiateResult> initiate(int planId) async {
    final url = ApiConfig.getSubscriptionInitiateUrl();

    final response =
        await AuthClient.postWithAuth(url, {"plan_id": planId});

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to start payment (${response.statusCode}): ${response.body}",
      );
    }

    return SubscriptionInitiateResult.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> verify({
    required int subscriptionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = ApiConfig.getSubscriptionVerifyUrl();

    final response = await AuthClient.postWithAuth(url, {
      "subscription_id": subscriptionId,
      "razorpay_order_id": razorpayOrderId,
      "razorpay_payment_id": razorpayPaymentId,
      "razorpay_signature": razorpaySignature,
    });

    if (response.statusCode != 200) {
      throw Exception(
        "Payment verification failed (${response.statusCode}): ${response.body}",
      );
    }
  }

  Future<void> recordFailure({
    required int subscriptionId,
    String? reason,
  }) async {
    final url = ApiConfig.getSubscriptionFailureUrl();

    // Best-effort — a failure to log the failure shouldn't block the UI
    // from showing the farmer their payment didn't go through.
    try {
      await AuthClient.postWithAuth(url, {
        "subscription_id": subscriptionId,
        if (reason != null) "failure_reason": reason,
      });
    } catch (_) {}
  }
}

final subscriptionRepoProvider = Provider((ref) => SubscriptionRepository());

final subscriptionPlansProvider = FutureProvider<PlansModel>((ref) async {
  return ref.watch(subscriptionRepoProvider).getPlans();
});

final subscriptionStatusProvider =
    FutureProvider<SubscriptionStatusModel>((ref) async {
  return ref.watch(subscriptionRepoProvider).getStatus();
});