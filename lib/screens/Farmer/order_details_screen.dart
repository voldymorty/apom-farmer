import 'package:client/global/colortheme.dart';
import 'package:client/models/order_Detail_Model.dart';
import 'package:client/repository/order_detail_repository.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int cropId;

  const OrderDetailScreen({super.key, required this.cropId});

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

  String _formatStatusLabel(String status) {
    final raw = status.trim();
    if (raw.isEmpty) return 'UNKNOWN';
    return raw.replaceAll('_', ' ').toUpperCase();
  }

  Color _statusColor(String status) {
    final normalized = _normalizeStatus(status);
    if (normalized.contains('pickup') && normalized.contains('assigned')) {
      return const Color(0xFF3D66F5);
    }
    if (normalized.contains('pickup') || normalized.contains('picked up')) {
      return const Color(0xFFF59E0B);
    }
    switch (normalized) {
      case 'available':
        return const Color(0xFF1B7F6B);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFE11D48);
      case 'rejected':
        return const Color(0xFF9A3412);
      case 'approved':
      case 'completed':
      case 'picked up':
        return const Color(0xFF15803D);
      case 'pending':
      case 'pending pickup':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
    final status = _normalizeStatus(data.status);
    final createdText = _formatDateTime(context, data.createdAt);
    final updatedText = _formatDateTime(context, data.updatedAt);

    if (status.contains('cancel') || status.contains('reject')) {
      return [
        {
          'title': 'Order Cancelled',
          'time': updatedText.isNotEmpty ? updatedText : createdText,
          'completed': true,
        },
      ];
    }

    int progress = 0;
    if (status.contains('payment') || status.contains('paid')) {
      progress = 4;
    } else if (status.contains('delivered') || status.contains('completed')) {
      progress = 3;
    } else if (status.contains('picked up') || status == 'pickup') {
      progress = 2;
    } else if (status.contains('pickup assigned') ||
        (status.contains('pickup') && status.contains('assigned'))) {
      progress = 1;
    }

    return [
      {
        'title': 'Order Confirmed',
        'time': createdText,
        'completed': true,
      },
      {
        'title': 'Pickup Assigned',
        'time': '',
        'completed': progress >= 1,
      },
      {
        'title': 'Picked Up',
        'time': '',
        'completed': progress >= 2,
      },
      {
        'title': 'Payment Processed',
        'time': progress >= 4 ? updatedText : '',
        'completed': progress >= 4,
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
        final harvestTimeText = _formatTime(context, harvestDate);
        final statusLabel = _formatStatusLabel(data.status);
        final statusColor = _statusColor(data.status);
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
          body: SingleChildScrollView(
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
                              cropName,
                              style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 12),
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
                      const SizedBox(height: 12),

                      // Farmer Details
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
                              "Farmer Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor:
                                      AppColors.farmerColor.withOpacity(0.12),
                                  child: Text(
                                    _initials(farmerName),
                                    style: TextStyle(
                                      color: AppColors.farmerColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farmerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      farmerIdLabel,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (remarks.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7F7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E5E5),
                                  ),
                                ),
                                child: Text(
                                  remarks,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

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
                              "Order Journey",
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
                                          if (step['time'] != null &&
                                              (step['time'] as String)
                                                  .isNotEmpty)
                                            Text(
                                              step['time'] as String,
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
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
        );
      },
    );
  }
}
