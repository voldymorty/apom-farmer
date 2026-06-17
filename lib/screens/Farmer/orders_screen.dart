import 'package:client/global/colortheme.dart';
import 'package:client/models/orders_model.dart';
import 'package:client/repository/orders_repository.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:client/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String? _selectedStatus;

  final OrdersRepository _repo = OrdersRepository();
  bool _isLoading = true;
  String? _error;
  List<Datum> _allOrders = [];
  List<Datum> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _refreshOrders() async {
    await _loadOrders(status: _selectedStatus);
  }

  Future<void> _loadOrders({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final model = await _repo.getOrders(status: status);
      if (!mounted) return;

      if (status == null) {
        setState(() {
          _allOrders = model.data;
          _orders = _applyFilter(_allOrders, _selectedStatus);
          _isLoading = false;
        });
        return;
      }

      if (model.data.isNotEmpty) {
        setState(() {
          _orders = model.data;
          _isLoading = false;
        });
        return;
      }

      if (_allOrders.isEmpty) {
        final allModel = await _repo.getOrders();
        if (!mounted) return;
        setState(() {
          _allOrders = allModel.data;
          _orders = _applyFilter(_allOrders, status);
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _orders = _applyFilter(_allOrders, status);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (status != null && _allOrders.isNotEmpty) {
          _orders = _applyFilter(_allOrders, status);
        } else {
          _error = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd MMM, yyyy').format(date);
  }

  String _formatUpdated(DateTime? date) {
    if (date == null) return 'Updated recently';
    return 'Updated ${DateFormat('dd MMM, yyyy').format(date)}';
  }

  String _resolvePhotoUrl(Datum order) {
    if (order.cropPhotoUrls.isNotEmpty) {
      return order.cropPhotoUrls.first;
    }
    final productImage = order.product.imageUrl?.toString() ?? '';
    if (productImage.trim().isNotEmpty) {
      return productImage;
    }
    return 'https://via.placeholder.com/600x400.png?text=No+Image';
  }

  String _normalizeStatus(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    return raw.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  List<Datum> _applyFilter(List<Datum> source, String? status) {
    final normalized = _normalizeStatus(status);
    if (normalized.isEmpty || normalized == 'all') return source;
    return source
        .where(
          (order) {
            final orderStatus = _normalizeStatus(order.status);
            if (normalized == 'pickup assigned') {
              return orderStatus == 'pickup assigned' ||
                  orderStatus.contains('pickup assigned') ||
                  (orderStatus.contains('pickup') &&
                      orderStatus.contains('assigned'));
            }
            if (normalized == 'picked up') {
              return orderStatus == 'picked up' ||
                  orderStatus == 'pickup' ||
                  orderStatus.contains('picked up') ||
                  (orderStatus.contains('pickup') &&
                      !orderStatus.contains('assigned'));
            }
            return orderStatus == normalized;
          },
        )
        .toList();
  }

  bool _isAvailable(Datum order) {
    final status = order.status.trim().toLowerCase();
    return status == 'available' || status.contains('available');
  }

  String _normalizeGrade(String grade) {
    final raw = grade.trim().toUpperCase();
    if (raw.startsWith('GRADE ')) {
      return raw.substring(6).trim();
    }
    return raw.isEmpty ? 'A' : raw;
  }

  Future<void> _deleteOrder(Datum order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Crop'),
          content: const Text('Are you sure you want to delete this crop?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repo.deleteOrder(cropId: order.cropId);
      if (!mounted) return;
      _loadOrders(status: _selectedStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _editOrder(Datum order) async {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController(text: order.quantityKg);
    final priceController = TextEditingController(
      text: order.expectedPricePerKg,
    );
    String selectedGrade = _normalizeGrade(order.grade);
    DateTime selectedDate = order.harvestDate ?? DateTime.now();
    final unitLabel =
        order.product.unit.trim().isEmpty ? 'KG' : order.product.unit;

    InputDecoration fieldDecoration(
      String label,
      IconData icon, {
      String? suffixText,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffixText,
        filled: true,
        fillColor: const Color(0xFFF6F7F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              title: Row(
                children: [
                  const Text(
                    'Edit Crop',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE0E6E2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.grass_outlined,
                              color: AppColors.farmerColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.product.productName.trim().isEmpty
                                    ? 'Crop'
                                    : order.product.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '#CROP-${order.cropId}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                          'Quantity',
                          Icons.scale_outlined,
                          suffixText: unitLabel,
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: fieldDecoration(
                          'Expected Price (per $unitLabel)',
                          Icons.currency_rupee,
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGrade,
                        items:
                            ['A', 'B', 'C']
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text('Grade $g'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedGrade = value);
                        },
                        decoration: fieldDecoration(
                          'Quality Grade',
                          Icons.verified_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          setDialogState(() => selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: fieldDecoration(
                            'Harvest Date',
                            Icons.calendar_today,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_formatDate(selectedDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.farmerColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final quantity = quantityController.text.trim();
    final price = priceController.text.trim();

    try {
      await _repo.updateOrder(
        cropId: order.cropId,
        quantityKg: quantity,
        expectedPricePerKg: price,
        grade: selectedGrade,
        harvestDate: selectedDate,
      );
      if (!mounted) return;
      _loadOrders(status: _selectedStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  List<Map<String, String?>> get _statusFilters => [
    {"label": "All", "status": null},
    {"label": "Available", "status": "available"},
    {"label": "Pickup Assigned", "status": "pickup_assigned"},
    {"label": "Picked Up", "status": "picked_up"},
    {"label": "Cancelled", "status": "cancelled"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: CustomAppBar(
        showBackButton: false,
        title: "My Products",
        backgroundColor: AppColors.farmerColor,
        elevation: 0,

      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                    _statusFilters.map((filter) {
                      final label = filter["label"] ?? "";
                      final status = filter["status"];
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatus = status;
                              });
                              _loadOrders(status: status);
                            }
                          },
                          selectedColor: AppColors.farmerColor,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Order list
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.farmerColor,
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                    : _orders.isEmpty
                    ? const _EmptyOrdersView()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final unit =
                            order.product.unit.trim().isEmpty
                                ? 'KG'
                                : order.product.unit;
                        return OrderCard(
                          photoUrl: _resolvePhotoUrl(order),
                          status: order.status,
                          orderId: '#CROP-${order.cropId}',
                          cropId: order.cropId,
                          cropName:
                              order.product.productName.trim().isEmpty
                                  ? 'Crop'
                                  : order.product.productName,
                          quantity: '${order.quantityKg} $unit',
                          expectedPrice:
                              '₹ ${order.expectedPricePerKg} / $unit',
                          pickupTime: _formatDate(order.harvestDate),
                          updatedTime: _formatUpdated(order.updatedAt),
                          showEditDelete: _isAvailable(order),
                          onEdit:
                              _isAvailable(order) ? () => _editOrder(order) : null,
                          onDelete:
                              _isAvailable(order) ? () => _deleteOrder(order) : null,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              "No products yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Once you post a crop, it will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
