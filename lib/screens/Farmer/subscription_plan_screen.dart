import 'package:client/global/colortheme.dart';
import 'package:client/models/subscription_model.dart';
import 'package:client/repository/subscription_repository.dart';
import 'package:client/utils/subscription_error_handling.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

const List<String> _kBasicFeatures = [
  "Unlimited crop listings",
  "Sales history dashboard",
  "Call & email support",
];

const List<String> _kPremiumFeatures = [
  "Unlimited crop listings",
  "Dashboard with future insights",
  "Call, email & priority WhatsApp support",
];

/// Plan/duration picker + Razorpay checkout for the Farmer Subscription module.
///
/// Reached from [SubscriptionPaywallScreen] when a farmer has no active
/// subscription or theirs has expired. On successful payment, pops with
/// `true` so the caller (the paywall gate) can refresh subscription status
/// and reveal the gated screen.
class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState
    extends ConsumerState<SubscriptionPlanScreen> {
  late final Razorpay _razorpay;
  final SubscriptionRepository _repo = SubscriptionRepository();

  String _selectedPlanType = "basic"; // "basic" | "premium"
  int? _selectedPlanId;
  bool _isProcessing = false;
  int? _pendingSubscriptionId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Payment flow ──────────────────────────────────────────────────

  void _showUpgradeConfirmationDialog({
    required SubscriptionPlan plan,
    required SubscriptionSummary currentSub,
    required bool isUpgrade,
    required bool isExactCurrent,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.of(bottomSheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isUpgrade ? AppColors.farmerColor : Colors.blue)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUpgrade
                          ? Icons.upgrade_rounded
                          : isExactCurrent
                              ? Icons.restart_alt_rounded
                              : Icons.swap_horiz_rounded,
                      color: isUpgrade ? AppColors.farmerColor : Colors.blue.shade700,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isUpgrade
                          ? "Upgrade to ${plan.planTypeLabel} Plan"
                          : isExactCurrent
                              ? "Renew ${plan.planTypeLabel} Plan"
                              : "Switch to ${plan.planTypeLabel} Plan",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Plan change summary box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Current Plan",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          "${currentSub.planTypeLabel} (${currentSub.durationLabel})",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Plan",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          "${plan.planTypeLabel} (${plan.durationLabel})",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.farmerColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Amount Payable",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "₹${plan.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── IMPORTANT DISCLAIMER (As explicitly requested by user) ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE65100),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Important Notice",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your old plan will be removed immediately, and your new ${plan.planTypeLabel} (${plan.durationLabel}) plan will be active and start fresh from today. Unused days from your existing plan will not be carried forward.",
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF5D4037),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.farmerColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _startCheckout(plan);
                      },
                      child: Text(
                        "Confirm & Pay ₹${plan.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startCheckout(SubscriptionPlan plan) async {
    setState(() => _isProcessing = true);
    try {
      final result = await _repo.initiate(plan.planId);
      _pendingSubscriptionId = result.subscriptionId;

      final options = {
        'key': result.razorpayKeyId,
        'amount': (result.amount * 100).round(), // paise
        'currency': result.currency,
        'name': result.companyName,
        'description': '${plan.planTypeLabel} Plan · ${plan.durationLabel}',
        'order_id': result.razorpayOrderId,
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        CustomSnackBar.error(context, "Unable to start payment: $e");
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final subscriptionId = _pendingSubscriptionId;
    if (subscriptionId == null) return;

    try {
      await _repo.verify(
        subscriptionId: subscriptionId,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;
      ref.invalidate(subscriptionStatusProvider);
      CustomSnackBar.success(context, "Subscription activated!");
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(
          context,
          "Payment received but activation failed. Please contact support.",
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) async {
    final subscriptionId = _pendingSubscriptionId;
    if (subscriptionId != null) {
      await _repo.recordFailure(
        subscriptionId: subscriptionId,
        reason: response.message ?? 'Payment cancelled or failed',
      );
    }
    if (mounted) {
      setState(() => _isProcessing = false);
      CustomSnackBar.error(
        context,
        response.message?.isNotEmpty == true
            ? response.message!
            : "Payment was cancelled",
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      CustomSnackBar.info(
        context,
        "Opening ${response.walletName ?? 'wallet'}...",
      );
    }
  }

  // ── UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: const CustomAppBar(
        showBackButton: true,
        backgroundColor: AppColors.farmerColor,
        elevation: 0,
        title: "Subscription Plans",
        ),
      body: plansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (err, _) => buildApiErrorView(
          context,
          error: err,
          onRetry: () => ref.invalidate(subscriptionPlansProvider),
        ),
        data: (plansModel) {
          final allPlans = plansModel.data;
          if (allPlans.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No subscription plans are available right now.\nPlease check back shortly.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final basicPlans =
              allPlans.where((p) => p.planType == "basic").toList()
                ..sort((a, b) => a.durationDays.compareTo(b.durationDays));
          final premiumPlans =
              allPlans.where((p) => p.planType == "premium").toList()
                ..sort((a, b) => a.durationDays.compareTo(b.durationDays));

          final visiblePlans =
              _selectedPlanType == "premium" ? premiumPlans : basicPlans;

          SubscriptionPlan? selectedPlan;
          for (final p in visiblePlans) {
            if (p.planId == _selectedPlanId) {
              selectedPlan = p;
              break;
            }
          }
          // Sensible default: cheapest/first duration of the selected plan type.
          selectedPlan ??= visiblePlans.isNotEmpty ? visiblePlans.first : null;

          final currentSub = statusAsync.value?.subscription;
          final hasActiveSub =
              statusAsync.value?.hasAccess == true && currentSub != null;
          final isSamePlanType =
              hasActiveSub && currentSub.planType == selectedPlan?.planType;
          final isSameDuration =
              hasActiveSub && currentSub.duration == selectedPlan?.duration;
          final isExactCurrent = isSamePlanType && isSameDuration;
          final isUpgradeToPremium = hasActiveSub &&
              currentSub.isBasic &&
              (selectedPlan?.isPremium == true);

          String buttonText;
          if (selectedPlan == null) {
            buttonText = "Select a plan";
          } else if (hasActiveSub) {
            if (isExactCurrent) {
              buttonText =
                  "Renew Plan · ₹${selectedPlan.price.toStringAsFixed(0)}";
            } else if (isUpgradeToPremium) {
              buttonText =
                  "Upgrade to Premium · ₹${selectedPlan.price.toStringAsFixed(0)}";
            } else {
              buttonText =
                  "Switch to ${selectedPlan.planTypeLabel} · ₹${selectedPlan.price.toStringAsFixed(0)}";
            }
          } else {
            buttonText =
                "Pay ₹${selectedPlan.price.toStringAsFixed(0)} & Subscribe";
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 560;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 0 : 16,
                        16,
                        isWide ? 0 : 16,
                        16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 16 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Current status ──
                                statusAsync.maybeWhen(
                                  data: (status) => status.subscription !=
                                          null
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: _CurrentStatusBanner(
                                            status: status,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  orElse: () => const SizedBox.shrink(),
                                ),

                                const Text(
                                  "Choose your plan",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasActiveSub
                                      ? "Upgrade or switch your subscription anytime."
                                      : "Pick the plan that fits how you sell.",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Plan type cards ──
                                isWide
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _PlanTypeCard(
                                              title: "Basic",
                                              tagline: "Get started selling",
                                              features: _kBasicFeatures,
                                              isPremium: false,
                                              selected:
                                                  _selectedPlanType == "basic",
                                              isCurrent: hasActiveSub &&
                                                  currentSub.isBasic,
                                              startingPrice:
                                                  basicPlans.isNotEmpty
                                                      ? basicPlans.first.price
                                                      : null,
                                              onTap: () => setState(() {
                                                _selectedPlanType = "basic";
                                                _selectedPlanId = null;
                                              }),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _PlanTypeCard(
                                              title: "Premium",
                                              tagline: "Sell with more insight",
                                              features: _kPremiumFeatures,
                                              isPremium: true,
                                              selected: _selectedPlanType ==
                                                  "premium",
                                              isCurrent: hasActiveSub &&
                                                  currentSub.isPremium,
                                              startingPrice:
                                                  premiumPlans.isNotEmpty
                                                      ? premiumPlans.first.price
                                                      : null,
                                              onTap: () => setState(() {
                                                _selectedPlanType = "premium";
                                                _selectedPlanId = null;
                                              }),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _PlanTypeCard(
                                            title: "Basic",
                                            tagline: "Get started selling",
                                            features: _kBasicFeatures,
                                            isPremium: false,
                                            selected:
                                                _selectedPlanType == "basic",
                                            isCurrent: hasActiveSub &&
                                                currentSub.isBasic,
                                            startingPrice: basicPlans.isNotEmpty
                                                ? basicPlans.first.price
                                                : null,
                                            onTap: () => setState(() {
                                              _selectedPlanType = "basic";
                                              _selectedPlanId = null;
                                            }),
                                          ),
                                          const SizedBox(height: 12),
                                          _PlanTypeCard(
                                            title: "Premium",
                                            tagline: "Sell with more insight",
                                            features: _kPremiumFeatures,
                                            isPremium: true,
                                            selected:
                                                _selectedPlanType == "premium",
                                            isCurrent: hasActiveSub &&
                                                currentSub.isPremium,
                                            startingPrice:
                                                premiumPlans.isNotEmpty
                                                    ? premiumPlans.first.price
                                                    : null,
                                            onTap: () => setState(() {
                                              _selectedPlanType = "premium";
                                              _selectedPlanId = null;
                                            }),
                                          ),
                                        ],
                                      ),

                                const SizedBox(height: 24),

                                // ── Billing duration ──
                                const Text(
                                  "Billing duration",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                if (visiblePlans.isEmpty)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      "No durations available for this plan yet.",
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: visiblePlans
                                        .map(
                                          (plan) => _DurationPill(
                                            plan: plan,
                                            selected: plan.planId ==
                                                selectedPlan?.planId,
                                            isCurrent: hasActiveSub &&
                                                currentSub.planType ==
                                                    plan.planType &&
                                                currentSub.duration ==
                                                    plan.duration,
                                            onTap: () => setState(
                                              () => _selectedPlanId =
                                                  plan.planId,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),

                                const SizedBox(height: 24),

                                // ── Price summary ──
                                if (selectedPlan != null)
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: _PriceSummaryCard(
                                      key: ValueKey(selectedPlan.planId),
                                      plan: selectedPlan,
                                    ),
                                  ),

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Sticky CTA ──
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.loginBackground,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.farmerColor,
                              disabledBackgroundColor: AppColors.farmerColor
                                  .withValues(alpha: 0.5),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: selectedPlan == null || _isProcessing
                                ? null
                                : () {
                                    final planToBuy = selectedPlan!;
                                    if (hasActiveSub) {
                                      _showUpgradeConfirmationDialog(
                                        plan: planToBuy,
                                        currentSub: currentSub,
                                        isUpgrade: isUpgradeToPremium,
                                        isExactCurrent: isExactCurrent,
                                      );
                                    } else {
                                      _startCheckout(planToBuy);
                                    }
                                  },
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasActiveSub
                                            ? Icons.upgrade_rounded
                                            : Icons.lock_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          buttonText,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Current status banner ─────────────────────────────────────────

class _CurrentStatusBanner extends StatelessWidget {
  final SubscriptionStatusModel status;

  const _CurrentStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final sub = status.subscription;
    if (sub == null) return const SizedBox.shrink();

    final bool isActive = status.hasAccess;
    final Color accent = isActive ? AppColors.success : AppColors.error;
    final String label = isActive
        ? "Current plan"
        : status.isExpired
            ? "Expired plan"
            : status.isFlagged
                ? "Flagged"
                : "Subscription";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$label · ${sub.planType == "premium" ? "Premium" : "Basic"} (${sub.duration})",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (sub.expiryDate != null)
                  Text(
                    isActive
                        ? "Renews / expires ${_formatDate(sub.expiryDate)}"
                        : "Ended ${_formatDate(sub.expiryDate)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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

// ── Plan type card (Basic / Premium) ────────────────────────────────

class _PlanTypeCard extends StatelessWidget {
  final String title;
  final String tagline;
  final List<String> features;
  final bool isPremium;
  final bool selected;
  final bool isCurrent;
  final double? startingPrice;
  final VoidCallback onTap;

  const _PlanTypeCard({
    required this.title,
    required this.tagline,
    required this.features,
    required this.isPremium,
    required this.selected,
    this.isCurrent = false,
    required this.startingPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.farmerColor : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.farmerColor.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Current",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )
                else if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.farmerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Popular",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.farmerColor,
                      ),
                    ),
                  ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.farmerColor, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tagline,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (startingPrice != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "₹${startingPrice!.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "starting",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 15,
                        color: isPremium
                            ? AppColors.farmerColor
                            : AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Duration pill ──────────────────────────────────────────────────

class _DurationPill extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _DurationPill({
    required this.plan,
    required this.selected,
    this.isCurrent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAnnual = plan.duration == "annual";

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.farmerColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.farmerColor : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  plan.durationLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Current",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ] else if (isAnnual) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Best value",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "₹${plan.price.toStringAsFixed(0)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price summary card ──────────────────────────────────────────────

class _PriceSummaryCard extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PriceSummaryCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.farmerColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${plan.planTypeLabel} · ${plan.durationLabel}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Billed once per ${plan.duration == "monthly" ? "month" : plan.duration == "quarterly" ? "quarter" : "year"}",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹${plan.price.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.farmerColor,
            ),
          ),
        ],
      ),
    );
  }
}