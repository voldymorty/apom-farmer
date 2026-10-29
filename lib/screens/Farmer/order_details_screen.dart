import 'package:client/config/api_config.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/models/order_Detail_Model.dart';
import 'package:client/repository/order_detail_repository.dart';
import 'package:client/utils/token_storage.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int cropId;

  const OrderDetailScreen({super.key, required this.cropId});

  Future<void> _openSecureDocument(BuildContext context, String urlPath) async {
    try {
      final token = await TokenStorage.getToken();
      final fullUrl = ApiConfig.buildDocumentUrl(urlPath);
      final authenticatedUrl = token != null ? '$fullUrl?token=$token' : fullUrl;
      final uri = Uri.parse(authenticatedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.error(context, "Could not open document");
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.error(context, "Failed to open document: $e");
      }
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return DateTime.tryParse(trimmed);
    }
    return null;
  }

  String _formatDate(
    BuildContext context,
    DateTime? date, {
    String fallback = 'Not set',
  }) {
    if (date == null) return fallback;
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatTime(
    BuildContext context,
    DateTime? date, {
    String fallback = 'Not set',
  }) {
    if (date == null) return fallback;
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(date));
  }

  String _formatDateTime(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final dateText = _formatDate(context, date, fallback: '');
    final timeText = _formatTime(context, date, fallback: '');
    if (dateText.isEmpty) return timeText;
    if (timeText.isEmpty) return dateText;
    return '$dateText $timeText';
  }

  String _initials(String name) {
    final parts =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final second =
        parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return '$first$second';
  }

  String _normalizeStatus(String status) {
    return status
        .trim()
        .toLowerCase()
         .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Color _statusColor(String status) {
    final normalized = _normalizeStatus(status);
    if (normalized.contains('settled') ||
        normalized.contains('paid') ||
        normalized.contains('payment')) {
      return const Color(0xFF15803D); // Emerald Green
    }
    if (normalized.contains('stock released') || normalized == 'released') {
      return const Color(0xFF0D9488); // Teal
    }
    if (normalized.contains('holding') || normalized.contains('quality verified')) {
      return const Color(0xFF6366F1); // Indigo
    }
    if (normalized.contains('picked up')) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (normalized.contains('arrived') || normalized.contains('reached')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (normalized.contains('in transit') || normalized.contains('en route')) {
      return const Color(0xFF0284C7); // Sky Blue
    }
    if (normalized.contains('pickup assigned') ||
        (normalized.contains('pickup') && normalized.contains('assigned'))) {
      return const Color(0xFF3D66F5); // Royal Blue
    }
    if (normalized.contains('cancel')) {
      return const Color(0xFFE11D48); // Red
    }
    if (normalized.contains('reject')) {
      return const Color(0xFF9A3412); // Deep Orange/Brown
    }
    if (normalized.contains('requested') || normalized.contains('pending')) {
      return const Color(0xFFD97706); // Amber
    }
    if (normalized.contains('available')) {
      return const Color(0xFF1B7F6B); // Deep Forest Green
    }
    return const Color(0xFF1B7F6B);
  }

  String _resolvePhotoUrl(Data data) {
    final cropPhoto = data.cropPhotoUrl;
    if (cropPhoto is List && cropPhoto.isNotEmpty) {
      final first = cropPhoto.first?.toString() ?? '';
      if (first.trim().isNotEmpty) return first;
    }
    final cropPhotoString = cropPhoto?.toString() ?? '';
    if (cropPhotoString.trim().isNotEmpty) return cropPhotoString;
    final productImage = data.product.imageUrl?.toString() ?? '';
    if (productImage.trim().isNotEmpty) return productImage;
    return 'https://via.placeholder.com/600x400.png?text=No+Image';
  }

  List<Map<String, dynamic>> _buildTimeline(
    Data data,
    BuildContext context,
  ) {
    final eff = data.effectiveStatus;
    final createdText = _formatDateTime(context, data.createdAt);
    final updatedText = _formatDateTime(context, data.updatedAt);

    if (eff == 'cancelled') {
      return [
        {
          'title': 'Order Cancelled',
          'subtitle': 'Procurement request was cancelled',
          'time': updatedText.isNotEmpty ? updatedText : createdText,
          'completed': true,
        },
      ];
    }

    int progress = 0;
    if (eff == 'payment_settled' ||
        data.isPaymentLocked ||
        data.paymentStatus?.toLowerCase() == 'paid' ||
        data.paymentStatus?.toLowerCase() == 'fully_paid') {
      progress = 5;
    } else if (eff == 'stock_released' || data.holdingStatus?.toLowerCase() == 'released') {
      progress = 4;
    } else if (eff == 'in_holding' ||
        data.holdingStatus?.toLowerCase() == 'holding' ||
        data.isProcurementLocked ||
        data.procurementStatus?.toLowerCase() == 'finalized') {
      progress = 3;
    } else if (eff == 'picked_up' ||
        data.status.toLowerCase() == 'picked_up' ||
        data.deliveryStatus?.toLowerCase() == 'completed') {
      progress = 2;
    } else if (eff == 'pickup_assigned' ||
        eff == 'in_transit' ||
        eff == 'driver_arrived' ||
        data.status.toLowerCase() == 'pickup_assigned' ||
        data.deliveryStatus?.toLowerCase() == 'assigned' ||
        data.deliveryStatus?.toLowerCase() == 'accepted') {
      progress = 1;
    }

    return [
      {
        'title': 'Procurement Requested',
        'subtitle': 'Crop pickup request submitted',
        'time': createdText,
        'completed': true,
      },
      {
        'title': 'Pickup Assigned',
        'subtitle': progress >= 1
            ? (data.deliveryStatus == 'in_transit'
                ? 'Driver en route to farm'
                : data.deliveryStatus == 'reached' || data.deliveryStatus == 'arrived'
                    ? 'Driver arrived at pickup location'
                    : 'Driver assigned for pickup')
            : 'Awaiting driver assignment',
        'time': '',
        'completed': progress >= 1,
      },
      {
        'title': 'Picked Up',
        'subtitle': progress >= 2
            ? 'Crops collected from farm'
            : 'Pickup in progress',
        'time': '',
        'completed': progress >= 2,
      },
      {
        'title': 'Quality Inspection Completed',
        'subtitle': progress >= 3
            ? 'Warehouse inspection verified'
            : 'Warehouse quality inspection pending',
        'time': '',
        'completed': progress >= 3,
      },
      {
        'title': 'Stock Released to Live Inventory',
        'subtitle': progress >= 4
            ? 'Stock released to main live inventory'
            : 'Holding release pending',
        'time': '',
        'completed': progress >= 4,
      },
      {
        'title': 'Payment Settled',
        'subtitle': progress >= 5
            ? 'Payment credited to farmer account'
            : 'Farmer payment processing pending',
        'time': progress >= 5 ? updatedText : '',
        'completed': progress >= 5,
      },
    ];
  }

  String cleanImageUrl(String url) {
    return url
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .trim();
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(cropId));

    return orderAsync.when(
      loading:
          () => Scaffold(
            backgroundColor: AppColors.background,
            appBar: CustomAppBar(
              showBackButton: true,
              title: "ORDER REFERENCE",
              backgroundColor: AppColors.farmerColor,
              elevation: 0,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.farmerColor),
            ),
          ),
      error:
          (error, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: CustomAppBar(
              showBackButton: true,
              title: "ORDER REFERENCE",
              backgroundColor: AppColors.farmerColor,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Unable to load order details:\n$error",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          () => ref.invalidate(
                            orderDetailProvider(cropId),
                          ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          ),
      data: (model) {
        if (!model.success) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: CustomAppBar(
              showBackButton: true,
              title: "ORDER REFERENCE",
              backgroundColor: AppColors.farmerColor,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Order details not available.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          () => ref.invalidate(
                            orderDetailProvider(cropId),
                          ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = model.data;
        final orderId = '#CROP-${data.cropId}';
        final cropName =
            data.product.productName.trim().isEmpty
                ? 'Crop'
                : data.product.productName;
        final grade = data.grade.trim().isEmpty ? 'Not set' : data.grade;
        final unit = data.product.unit.trim().isEmpty ? 'KG' : data.product.unit;
        final quantityText =
            data.quantityKg.trim().isEmpty
                ? 'Not set'
                : '${data.quantityKg} $unit';
        final expectedPriceText =
            data.expectedPricePerKg.trim().isEmpty
                ? 'Not set'
                : 'Rs ${data.expectedPricePerKg} / $unit';
        final harvestDate = _parseDate(data.harvestDate);
        final harvestDateText = _formatDate(context, harvestDate);
        final statusLabel = data.effectiveStatusLabel;
        final statusColor = _statusColor(data.effectiveStatus);
        final photoUrl = _resolvePhotoUrl(data);
        final farmerName =
            data.farmer.fullName.trim().isEmpty
                ? 'Farmer'
                : data.farmer.fullName;
        final farmerIdLabel = '#FARMER-${data.farmer.farmerId}';
        final remarks = data.remarks?.toString().trim() ?? '';

        final timelineSteps = _buildTimeline(data, context);
        final imageUrl = cleanImageUrl(photoUrl);


        return Scaffold(
          backgroundColor: AppColors.loginBackground,
          appBar: CustomAppBar(
            showBackButton: true,
            title: "ORDER REFERENCE",
            backgroundColor: AppColors.farmerColor,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  orderId,
                  style: TextStyle(
                    color: AppColors.farmerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            elevation: 0,
          ),
          body: RefreshIndicator(
              color: AppColors.farmerColor,
              onRefresh: () async {
                ref.invalidate(orderDetailProvider(cropId));
                await ref.read(orderDetailProvider(cropId).future);
              },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image with overlay text
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child:
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: imageUrl.isEmpty
                              ? Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            ),
                          )
                              : Image.network(
                            imageUrl,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            headers: const {
                              "Accept": "image/*",
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
            
                              return Container(
                                height: 250,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (_, error, stackTrace) {
                              debugPrint("Image load error: $error");
                              debugPrint("Image URL: $imageUrl");
            
                              return Container(
                                height: 250,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        )
                      ),
                      Positioned(
                        bottom: 20,
                        left: 30,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.farmerColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data.items.length > 1
                                    ? 'Multi-Product Procurement (${data.items.length} Items)'
                                    : cropName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Order Summary",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (data.items.isNotEmpty) ...[
                                  Text(
                                    "REQUESTED PRODUCTS (${data.items.length})",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...data.items.map((item) {
                                    final pName = item.productName ?? 'Product #${item.productId}';
                                    final gLabel = (item.grade != null && item.grade!.trim().isNotEmpty)
                                        ? item.grade!.trim()
                                        : 'Standard';
                                    final pRate = item.expectedPricePerKg != null
                                        ? '₹ ${item.expectedPricePerKg! % 1 == 0 ? item.expectedPricePerKg!.toInt() : item.expectedPricePerKg} / ${item.unit ?? "KG"}'
                                        : 'Not set';
                                    final pQty = '${item.requestedQuantityKg % 1 == 0 ? item.requestedQuantityKg.toInt() : item.requestedQuantityKg} ${item.unit ?? "KG"}';
            
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFE5E7EB)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Grade: $gLabel  •  Qty: $pQty",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.farmerColor.withOpacity(0.10),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              pRate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.farmerColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "TOTAL REQUESTED",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${data.items.fold<double>(0.0, (s, i) => s + i.requestedQuantityKg).toStringAsFixed(1)} KG",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "HARVEST DATE",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            harvestDateText,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "GRADE",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            grade,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "QUANTITY",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            quantityText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "EXPECTED PRICE",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            expectedPriceText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "HARVEST DATE",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            harvestDateText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "LAST UPDATED",
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(context, data.updatedAt),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildProcurementItemsCard(context, data),
                        _buildSettlementAndPaymentCard(context, data),
                        const SizedBox(height: 12),
            
                        // // Farmer Details
                        // Container(
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(16),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.black.withOpacity(0.05),
                        //         blurRadius: 10,
                        //       ),
                        //     ],
                        //   ),
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       const Text(
                        //         "Farmer Details",
                        //         style: TextStyle(
                        //           fontSize: 18,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       const SizedBox(height: 16),
                        //       Row(
                        //         children: [
                        //           CircleAvatar(
                        //             radius: 26,
                        //             backgroundColor:
                        //                 AppColors.farmerColor.withOpacity(0.12),
                        //             child: Text(
                        //               _initials(farmerName),
                        //               style: TextStyle(
                        //                 color: AppColors.farmerColor,
                        //                 fontWeight: FontWeight.bold,
                        //               ),
                        //             ),
                        //           ),
                        //           const SizedBox(width: 14),
                        //           Column(
                        //             crossAxisAlignment: CrossAxisAlignment.start,
                        //             children: [
                        //               Text(
                        //                 farmerName,
                        //                 style: const TextStyle(
                        //                   fontWeight: FontWeight.bold,
                        //                   fontSize: 16,
                        //                 ),
                        //               ),
                        //               const SizedBox(height: 4),
                        //               Text(
                        //                 farmerIdLabel,
                        //                 style: TextStyle(
                        //                   color: AppColors.textSecondary,
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ],
                        //       ),
                        //       if (remarks.isNotEmpty) ...[
                        //         const SizedBox(height: 14),
                        //         Container(
                        //           width: double.infinity,
                        //           padding: const EdgeInsets.all(12),
                        //           decoration: BoxDecoration(
                        //             color: const Color(0xFFF7F7F7),
                        //             borderRadius: BorderRadius.circular(12),
                        //             border: Border.all(
                        //               color: const Color(0xFFE5E5E5),
                        //             ),
                        //           ),
                        //           child: Text(
                        //             remarks,
                        //             style: TextStyle(
                        //               color: AppColors.textSecondary,
                        //               height: 1.4,
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ],
                        //   ),
                        // ),
                        // const SizedBox(height: 12),
            
                        // Order Journey Timeline
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Procurement Journey",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...timelineSteps.asMap().entries.map((entry) {
                                final index = entry.key;
                                final step = entry.value;
                                final isActive = step['completed'] == true;
                                final isLast = index == timelineSteps.length - 1;
            
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  isActive
                                                      ? AppColors.farmerColor
                                                      : Colors.grey.shade300,
                                            ),
                                            child:
                                                isActive
                                                    ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 20,
                                                    )
                                                    : null,
                                          ),
                                          if (!isLast)
                                            Container(
                                              width: 2,
                                              height: 40,
                                              color:
                                                  isActive
                                                      ? AppColors.farmerColor
                                                          .withOpacity(0.5)
                                                      : Colors.grey.shade300,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              step['title'] as String,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isActive
                                                        ? AppColors.farmerColor
                                                        : AppColors.textPrimary,
                                              ),
                                            ),
                                            if (step['subtitle'] != null &&
                                                (step['subtitle'] as String)
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  step['subtitle'] as String,
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            if (step['time'] != null &&
                                                (step['time'] as String)
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  step['time'] as String,
                                                  style: const TextStyle(
                                                    color: AppColors.farmerColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcurementItemsCard(BuildContext context, Data data) {
    if (data.items.isEmpty && data.procurementReceiptUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.farmerColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Procurement Breakdown",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (data.isProcurementLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "LOCKED",
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (data.items.isNotEmpty)
              ...data.items.map((item) {
                final prodName = item.productName ?? 'Product #${item.productId}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            prodName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Req: ${item.requestedQuantityKg} ${item.unit ?? 'kg'}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((item.grade != null && item.grade!.trim().isNotEmpty) || item.expectedPricePerKg != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (item.grade != null && item.grade!.trim().isNotEmpty)
                              // _miniBadge("Grade", item.grade!.trim(), const Color(0xFF4338CA)),
                            if (item.expectedPricePerKg != null)
                              _miniBadge(
                                "Preferred",
                                "₹${item.expectedPricePerKg! % 1 == 0 ? item.expectedPricePerKg!.toInt() : item.expectedPricePerKg}/${item.unit ?? 'kg'}",
                                const Color(0xFF0D9488),
                                isBold: true,
                              ),
                          ],
                        ),
                      ],
                      if (data.isProcurementLocked || item.collectedQuantityKg > 0) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            // _miniBadge("Collected", "${item.collectedQuantityKg} kg", Colors.grey.shade700),
                            // _miniBadge("Grade A", "${item.gradeAQtyKg} kg", const Color(0xFF15803D)),
                            // _miniBadge("Grade B", "${item.gradeBQtyKg} kg", const Color(0xFF2563EB)),
                            // _miniBadge("Grade C", "${item.gradeCQtyKg} kg", const Color(0xFFD97706)),
                            _miniBadge("Wastage", "${item.wastageQuantityKg} kg", const Color(0xFFDC2626)),
                            _miniBadge("Accepted", "${item.acceptedQuantityKg} kg", const Color(0xFF059669), isBold: true),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            if (data.procurementReceiptUrl != null && data.procurementReceiptUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openSecureDocument(context, data.procurementReceiptUrl!),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                  label: const Text(
                    "Download Procurement Receipt (PDF)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.farmerColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String label, String value, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettlementAndPaymentCard(BuildContext context, Data data) {
    if (!data.isProcurementLocked && (data.paymentStatus == null || data.paymentStatus == 'unpaid')) {
      return const SizedBox.shrink();
    }

    final isPaid = data.paymentStatus?.toLowerCase() == 'paid' ||
        data.paymentStatus?.toLowerCase() == 'fully_paid' ||
        data.isPaymentLocked;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_outline : Icons.hourglass_top_outlined,
                      color: isPaid ? const Color(0xFF15803D) : Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Payment Details",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPaid ? const Color(0xFF15803D) : Colors.orange.shade700).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? "PAID" : "UNPAID",
                    style: TextStyle(
                      color: isPaid ? const Color(0xFF15803D) : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (!isPaid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Procurement physical inspection is complete. Admin will enter grade rates and initiate direct bank settlement.",
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     const Text(
              //       "Total Payable Amount",
              //       style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              //     ),
              //     Text(
              //       "₹${data.totalPayableAmount.toStringAsFixed(2)}",
              //       style: const TextStyle(
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //         color: Color(0xFF15803D),
              //       ),
              //     ),
              //   ],
              // ),


              // if (data.settlementItems.isNotEmpty) ...[
              //   const SizedBox(height: 14),
              //   const Text(
              //     "Grade-wise Breakdown",
              //     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              //   ),
              //   const SizedBox(height: 8),
              //   ...data.settlementItems.map((s) {
              //     return Container(
              //       margin: const EdgeInsets.only(bottom: 6),
              //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              //       decoration: BoxDecoration(
              //         color: const Color(0xFFF9FAFB),
              //         borderRadius: BorderRadius.circular(8),
              //         border: Border.all(color: const Color(0xFFE5E7EB)),
              //       ),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Text(
              //             "${s.productName ?? 'Product'} - Grade ${s.grade}",
              //             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              //           ),
              //           Text(
              //             "${s.quantityKg} kg × ₹${s.ratePerKg} = ₹${s.subtotal.toStringAsFixed(2)}",
              //             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              //           ),
              //         ],
              //       ),
              //     );
              //   }),
              // ],

              
              if (data.settlementItems.isNotEmpty) ...[
                // const SizedBox(height: 14),
                const Text(
                  "Settlement Breakdown",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),

                ...data.settlementItems.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.productName ?? 'Product',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Grade ${s.grade}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "QUANTITY",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "${s.quantityKg} kg",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "RATE / KG",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "₹${s.ratePerKg}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "SUBTOTAL",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "₹${s.subtotal.toStringAsFixed(2)}",
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF15803D).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TOTAL PAYABLE AMOUNT",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Final settlement amount",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "₹${data.totalPayableAmount.toStringAsFixed(2)}",
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Row(
                children: [
                  if (data.paymentReceiptUrl != null && data.paymentReceiptUrl!.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openSecureDocument(context, data.paymentReceiptUrl!),
                        icon: const Icon(Icons.receipt_long, size: 18, color: AppColors.farmerColor),
                        label: const Text(
                          "Payment Receipt",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.farmerColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.farmerColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (data.paymentReceiptUrl != null && data.transactionProofUrl != null)
                    const SizedBox(width: 10),
                  if (data.transactionProofUrl != null && data.transactionProofUrl!.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openSecureDocument(context, data.transactionProofUrl!),
                        icon: const Icon(Icons.image_outlined, size: 18, color: Color(0xFF2563EB)),
                        label: const Text(
                          "Transfer Proof",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
