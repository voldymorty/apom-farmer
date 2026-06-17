import 'package:client/screens/Farmer/order_details_screen.dart';
import 'package:client/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderCard extends StatelessWidget {
  static const String _adminPhone = '9019814347';

  final String photoUrl;
  final String status;
  final String orderId;
  final int cropId;
  final String cropName;
  final String quantity;
  final String expectedPrice;
  final String pickupTime;
  final String updatedTime;
  final bool showEditDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.photoUrl,
    required this.status,
    required this.orderId,
    required this.cropId,
    required this.cropName,
    required this.quantity,
    required this.expectedPrice,
    required this.pickupTime,
    required this.updatedTime,
    this.showEditDelete = false,
    this.onEdit,
    this.onDelete,
  });

  // ── Status color (unchanged logic) ──────────────────────────────────────
  Color _getStatusColor() {
    final normalized = status.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized.contains('pickup') && normalized.contains('assigned')) {
      return const Color(0xFF3D66F5);
    }
    if (normalized.contains('pickup') || normalized.contains('picked up')) {
      return const Color(0xFFF59E0B);
    }
    switch (normalized) {
      case "available":
        return const Color(0xFF1B7F6B);
      case "cancelled":
      case "canceled":
        return const Color(0xFFE11D48);
      case "rejected":
        return const Color(0xFF9A3412);
      case "approved":
      case "completed":
      case "picked up":
        return const Color(0xFF15803D);
      case "pending":
      case "pending pickup":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ── Contact admin (unchanged logic) ─────────────────────────────────────
  Future<void> _contactAdmin(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _adminPhone);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dial pad')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: Square image with status badge ─────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: photoUrl.isEmpty
                          ? Container(
                        width: 100,
                        height: 110,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported_outlined),
                      )
                          :Image.network(
                        photoUrl,
                        width: 100,
                        height: 110,
                        fit: BoxFit.cover,

                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;

                          return Container(
                            width: 100,
                            height: 110,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.farmerColor,
                              ),
                            ),
                          );
                        },

                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 110,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    // Status pill overlaid at bottom of image
                    Positioned(
                      bottom: -10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── Right: Content column ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.farmerColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          orderId,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.farmerColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Crop name + Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cropName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.farmerColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              expectedPrice,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.farmerColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Pickup time
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: pickupTime,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 5),

                      // Quantity
                      _InfoRow(
                        icon: Icons.scale_rounded,
                        label: quantity,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),

          // ── Action buttons ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // View Details button
                Expanded(
                  child: _ActionButton(
                    label: "View Details",
                    icon: Icons.info_outline_rounded,
                    outlined: true,
                    color: AppColors.farmerColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(cropId: cropId),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Edit/Delete or Contact Admin
                Expanded(
                  child: showEditDelete
                      ? Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: '',
                          icon: Icons.edit_outlined,
                          outlined: true,
                          color: AppColors.farmerColor,
                          onTap: onEdit ?? () {},
                          iconOnly: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: '',
                          icon: Icons.delete_outline_rounded,
                          outlined: false,
                          color: Colors.redAccent,
                          onTap: onDelete ?? () {},
                          iconOnly: true,
                        ),
                      ),
                    ],
                  )
                      : _ActionButton(
                    label: "Contact Admin",
                    icon: Icons.call_rounded,
                    outlined: false,
                    color: AppColors.farmerColor,
                    onTap: () => _contactAdmin(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable info row ───────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Reusable action button ──────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final Color color;
  final VoidCallback onTap;
  final bool iconOnly;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.outlined,
    required this.color,
    required this.onTap,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: outlined ? Colors.transparent : color,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: outlined
              ? BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: borderRadius,
          )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: outlined ? color : Colors.white,
              ),
              if (!iconOnly) ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: outlined ? color : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
