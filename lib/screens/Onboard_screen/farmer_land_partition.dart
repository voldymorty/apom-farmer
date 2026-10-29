import 'dart:io';
import 'package:client/models/crop_catogory_model.dart';
import 'package:client/repository/add_pickup_repository.dart';
import 'package:client/screens/Onboard_screen/welcome_screen.dart';
import 'package:client/repository/profileSetup_repo.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:client/widgets/crop_picker_sheet.dart';
import 'package:flutter/material.dart';

class FarmerLandPartitionScreen extends StatefulWidget {
  final String mobile;
  final String fullName;
  final String aadharNumber;
  final String farmName;
  final File profilePhoto;
  final String stateId;
  final String districtId;
  final String cityId;
  final String locationAddress;
  final String pincode;
  final double latitude;
  final double longitude;
  final double totalLand;
  final String landUnit;
  final File landPhoto;

  const FarmerLandPartitionScreen({
    super.key,
    required this.mobile,
    required this.fullName,
    required this.aadharNumber,
    required this.farmName,
    required this.profilePhoto,
    required this.stateId,
    required this.districtId,
    required this.cityId,
    required this.locationAddress,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.totalLand,
    required this.landUnit,
    required this.landPhoto,
  });

  @override
  State<FarmerLandPartitionScreen> createState() =>
      _FarmerLandPartitionScreenState();
}

class _FarmerLandPartitionScreenState extends State<FarmerLandPartitionScreen>
    with SingleTickerProviderStateMixin {
  static const double _epsilon = 0.0001;

  final List<_LandPartitionInput> _partitions = [_LandPartitionInput()];
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<Datum> _categories = [];
  bool _categoriesLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadCategories();
  }

  @override
  void dispose() {
    for (final partition in _partitions) {
      partition.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  String get _unitLabel {
    switch (widget.landUnit) {
      case 'acres':
        return 'Acres';
      case 'hectares':
        return 'Hectares';
      case 'cent':
      default:
        return 'Cent';
    }
  }

  double get _usedLand {
    return _partitions.fold(
      0.0,
      (total, partition) => total + partition.parsedArea,
    );
  }

  double get _remainingLand => widget.totalLand - _usedLand;

  // Crop partitions only need to fit within the total land — they no
  // longer need to add up to it exactly. Any leftover is fallow land.
  bool get _isWithinLimit => _usedLand - widget.totalLand <= _epsilon;
  double get _fallowLand => _remainingLand < 0 ? 0 : _remainingLand;

  int get _maxPartitionCount {
    final maxByLand = widget.totalLand.floor();
    return maxByLand < 1 ? 1 : maxByLand;
  }

  bool get _isPartitionLimitReached => _remainingLand <= 0;

  bool _isCardValid(_LandPartitionInput item) {
    if (item.selectedProductId == null) return false;
    if (item.parsedArea <= 0) return false;
    if (item.parsedYield == null || item.parsedYield! <= 0) return false;
    if (item.plantationDate == null || item.harvestingDate == null) return false;
    return item.harvestingDate!.isAfter(item.plantationDate!);
  }

  bool get _isReady => _partitions.every(_isCardValid) && _isWithinLimit;

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Future<void> _pickPlantationDate(int index) async {
    final item = _partitions[index];
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: item.plantationDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
      helpText: 'Select Plantation Date',
    );

    if (selected == null) return;

    setState(() {
      item.plantationDate = selected;
      if (item.harvestingDate != null &&
          !item.harvestingDate!.isAfter(selected)) {
        item.harvestingDate = null;
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final repo = AddPickupRepository();
      final result = await repo.getCropCategories();
      if (mounted) setState(() => _categories = result.data);
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to load crops: $e');
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _showCropPickerSheet(int partitionIndex) async {
    final item = _partitions[partitionIndex];
    final selection = await showCropPickerSheet(
      context,
      categories: _categories,
      categoriesLoading: _categoriesLoading,
    );
    if (selection == null) return;
    setState(() {
      item.selectedProductId = selection.productId;
      item.selectedProductName = selection.productName;
      item.selectedCategoryName = selection.categoryName;
    });
  }


  Future<void> _pickHarvestingDate(int index) async {
    final item = _partitions[index];
    if (item.plantationDate == null) {
      CustomSnackBar.error(context, 'Please select plantation date first');
      return;
    }

    final minHarvestDate = item.plantationDate!.add(const Duration(days: 1));
    final maxDate = DateTime(2100);
    if (minHarvestDate.isAfter(maxDate)) {
      CustomSnackBar.error(context, 'Please choose an earlier plantation date');
      return;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate:
          item.harvestingDate == null ||
                  item.harvestingDate!.isBefore(minHarvestDate)
              ? minHarvestDate
              : item.harvestingDate!,
      firstDate: minHarvestDate,
      lastDate: maxDate,
      helpText: 'Select Harvesting Date',
    );

    if (selected == null) return;
    setState(() => item.harvestingDate = selected);
  }

  void _addPartitionCard() {
    if (_isPartitionLimitReached) {
      CustomSnackBar.info(
        context,
        'You can add up to $_maxPartitionCount partitions for ${widget.totalLand.toStringAsFixed(2)} $_unitLabel.',
      );
      return;
    }
    setState(() => _partitions.add(_LandPartitionInput()));
  }

  void _removePartitionCard(int index) {
    if (_partitions.length == 1) {
      CustomSnackBar.error(context, 'At least one partition is required');
      return;
    }
    setState(() {
      final removed = _partitions.removeAt(index);
      removed.dispose();
    });
  }

  void _submit() async {
    for (var i = 0; i < _partitions.length; i++) {
      final partition = _partitions[i];
      if (partition.selectedProductId == null) {
        CustomSnackBar.error(context, 'Select a crop product in partition ${i + 1}');
        return;
      }
      if (partition.parsedArea <= 0) {
        CustomSnackBar.error(
          context,
          'Enter valid partition area in partition ${i + 1}',
        );
        return;
      }
      if (partition.parsedYield == null || partition.parsedYield! <= 0) {
        CustomSnackBar.error(
          context,
          'Enter expected yield in partition ${i + 1}',
        );
        return;
      }
      if (partition.plantationDate == null ||
          partition.harvestingDate == null) {
        CustomSnackBar.error(
          context,
          'Select plantation and harvesting dates in partition ${i + 1}',
        );
        return;
      }
      if (!partition.harvestingDate!.isAfter(partition.plantationDate!)) {
        CustomSnackBar.error(
          context,
          'Harvesting date must be after plantation date (partition ${i + 1})',
        );
        return;
      }
    }

    if (!_isWithinLimit) {
      final over = (_usedLand - widget.totalLand).toStringAsFixed(2);
      CustomSnackBar.error(
        context,
        'Allocated crop land exceeds total land by $over $_unitLabel. Reduce a partition area.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> partitionPayload = _partitions.map((partition) => <String, dynamic>{
        'crop_name': partition.selectedProductName ?? '',
        'product_id': partition.selectedProductId,
        'area_value': partition.parsedArea,
        'expected_yield_value': partition.parsedYield,
        'expected_yield_unit': partition.yieldUnit,
        'plantation_date': partition.plantationDate?.toIso8601String().split('T')[0],
        'harvesting_date': partition.harvestingDate?.toIso8601String().split('T')[0],
      }).toList();

      final repo = ProfileSetupRepository();
      final result = await repo.setupProfile(
        pincode: widget.pincode,
        totalLand: widget.totalLand,
        stateId: widget.stateId,
        locationAddress: widget.locationAddress,
        latitude: widget.latitude,
        districtId: widget.districtId,
        cityId: widget.cityId,
        longitude: widget.longitude,
        aadharNumber: widget.aadharNumber,
        farmName: widget.farmName,
        landUnit: widget.landUnit,
        fullName: widget.fullName,
        landSegments: partitionPayload,
        profilePhoto: widget.profilePhoto,
        landPhoto: widget.landPhoto,
      );

      if (result['success'] != false && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RegistrationSuccessScreen(),
          ),
        );
      } else if (mounted) {
        CustomSnackBar.error(context, "Profile setup failed. Please try again.");
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, "An error occurred: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _dateCard({
    required String hint,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFF5EFE5) : const Color(0xFFFBFAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasValue
                    ? AppColors.farmerColor.withOpacity(0.55)
                    : const Color(0xFFD4C9B0),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    hasValue
                        ? AppColors.farmerColor.withOpacity(0.14)
                        : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    hasValue
                        ? AppColors.farmerColor
                        : AppColors.farmerColor.withOpacity(0.5),
                size: 19,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                hasValue ? _formatDate(value) : hint,
                style: TextStyle(
                  fontSize: 12.5,
                  color:
                      hasValue
                          ? AppColors.farmerColor
                          : const Color(0xFF9AA89C),
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              hasValue
                  ? Icons.check_circle_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 18,
              color: hasValue ? AppColors.farmerColor : const Color(0xFF8EA194),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Color(0xFF6B7C6E),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9AA89C)),
      filled: true,
      fillColor: const Color(0xFFFCFAF5),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF7A8C7D)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0D6C3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0D6C3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.farmerColor.withOpacity(0.7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _partitionCard(int index, _LandPartitionInput item) {
    final invalidDate =
        item.plantationDate != null &&
        item.harvestingDate != null &&
        !item.harvestingDate!.isAfter(item.plantationDate!);
    final isComplete = _isCardValid(item);
    final usedArea = item.parsedArea;
    final statusColor =
        isComplete ? AppColors.farmerColor : const Color(0xFF7B6A4D);

    return Container(
      margin: const EdgeInsets.fromLTRB(2, 2, 2, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isComplete
                  ? AppColors.farmerColor.withOpacity(0.32)
                  : const Color(0xFFD7CCB8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.farmerColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crop Partition',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D4A35),
                        ),
                      ),
                      Text(
                        'Card ${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C8C7F),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isComplete
                            ? AppColors.farmerColor.withOpacity(0.14)
                            : const Color(0xFFEDE3D0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isComplete ? 'Complete' : 'Pending',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                if (_partitions.length > 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removePartitionCard(index),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5DAC7)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 15,
                    color: Color(0xFF6B7C6E),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Allocated in this card',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7C6E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${usedArea.toStringAsFixed(2)} $_unitLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D4A35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showCropPickerSheet(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: item.selectedProductId != null
                      ? const Color(0xFFF5EFE5)
                      : const Color(0xFFFCFAF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.selectedProductId != null
                        ? AppColors.farmerColor.withOpacity(0.55)
                        : const Color(0xFFE0D6C3),
                    width: 1.3,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.grass_rounded,
                        size: 18,
                        color: item.selectedProductId != null
                            ? AppColors.farmerColor
                            : const Color(0xFF7A8C7D)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: item.selectedProductId != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.selectedProductName ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.farmerColor,
                                  ),
                                ),
                                Text(
                                  item.selectedCategoryName ?? '',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF7C8C7F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Select Crop / Product',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9AA89C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    Icon(
                      item.selectedProductId != null
                          ? Icons.check_circle_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      size: 18,
                      color: item.selectedProductId != null
                          ? AppColors.farmerColor
                          : const Color(0xFF8EA194),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: item.areaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration(
                label: 'Partition Area ($_unitLabel)',
                hint: 'Enter area for this crop',
                icon: Icons.square_foot_rounded,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.yieldController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDecoration(
                      label: 'Expected Yield',
                      hint: 'Enter expected quantity',
                      icon: Icons.grain_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFAF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0D6C3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: item.yieldUnit,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'ton', child: Text('ton')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => item.yieldUnit = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plantation Date',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7C6E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _dateCard(
                        hint: 'Select date',
                        icon: Icons.event_available_rounded,
                        value: item.plantationDate,
                        onTap: () => _pickPlantationDate(index),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harvesting Date',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7C6E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _dateCard(
                        hint: 'Select date',
                        icon: Icons.event_repeat_rounded,
                        value: item.harvestingDate,
                        onTap: () => _pickHarvestingDate(index),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invalidDate) ...[
              const SizedBox(height: 12),
              const Text(
                'Harvesting date must be after plantation date.',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _landMetric({
    required String label,
    required String value,
    required String unit,
    Color valueColor = const Color(0xFF2D4A35),
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5DAC7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7C8C7F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _landSummaryCard({
    required double used,
    required double remaining,
    required bool exceeded,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFBF7EF)],
        ),
        border: Border.all(
          color: exceeded ? AppColors.error : const Color(0xFFD4C9B0),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                size: 18,
                color: Color(0xFF2D4A35),
              ),
              const SizedBox(width: 6),
              const Text(
                'Land Summary',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D4A35),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      !exceeded
                          ? AppColors.farmerColor.withOpacity(0.15)
                          : const Color(0xFFFDEAEA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  !exceeded ? 'Within Limit' : 'Exceeds Land',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color:
                        !exceeded
                            ? AppColors.farmerColor
                            : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Divider(height: 10, thickness: 1),
          const SizedBox(height: 3),
          Row(
            children: [
              _landMetric(
                label: 'Total',
                value: widget.totalLand.toStringAsFixed(2),
                unit: _unitLabel,
              ),
              const SizedBox(width: 8),
              _landMetric(
                label: 'Cultivated',
                value: used.toStringAsFixed(2),
                unit: _unitLabel,
              ),
              const SizedBox(width: 8),
              _landMetric(
                label: 'Fallow',
                value: (remaining < 0 ? 0 : remaining).toStringAsFixed(2),
                unit: _unitLabel,
                valueColor:
                    exceeded ? AppColors.error : const Color(0xFF2D4A35),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            !exceeded
                ? 'Unallocated land is automatically fallow.'
                : 'Cultivated land cannot exceed total land.',
            style: TextStyle(
              fontSize: 11.5,
              color: !exceeded ? AppColors.farmerColor : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPartitionButton({required bool disabled}) {
    return Opacity(
      opacity: disabled ? 0.58 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: GestureDetector(
          onTap: _addPartitionCard,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient:
                  disabled
                      ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE0E0E0), Color(0xFFD2D2D2)],
                      )
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.farmerColor.withOpacity(0.12),
                          AppColors.farmerColor.withOpacity(0.18),
                        ],
                      ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    disabled
                        ? const Color(0xFFBEBEBE)
                        : AppColors.farmerColor.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Icon(
                    disabled ? Icons.block_rounded : Icons.add_rounded,
                    size: 18,
                    color:
                        disabled
                            ? const Color(0xFF6E6E6E)
                            : AppColors.farmerColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    disabled
                        ? 'Add Limit Reached'
                        : 'Add Another Crop Partition',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D4A35),
                    ),
                  ),
                ),
                Icon(
                  disabled
                      ? Icons.lock_outline_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: const Color(0xFF2D4A35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final used = _usedLand;
    final remaining = _remainingLand;
    final exceeded = remaining < -_epsilon;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.farmerColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB5841A).withOpacity(0.09),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF2D4A35),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(4, (i) {
                          final isActive = i == 3;
                          final isDone = i < 3;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color:
                                  isActive
                                      ? AppColors.farmerColor
                                      : isDone
                                      ? AppColors.farmerColor.withOpacity(0.45)
                                      : const Color(0xFFD4C9B0),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: CustomScrollView(
                        slivers: [
                          const SliverPadding(
                            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Land Segments',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      color: Color(0xFF1E3025),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Split your total land into crop cards with plantation and harvesting dates.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF6B7C6E),
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 18),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                            sliver: SliverPersistentHeader(
                              pinned: true,
                              delegate: _PinnedHeaderDelegate(
                                height: screenHeight * 0.21,
                                backgroundColor: const Color(0xFFF5F0E8),
                                child: SizedBox.expand(
                                  child: _landSummaryCard(
                                    used: used,
                                    remaining: remaining,
                                    exceeded: exceeded,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                children: [
                                  const Text(
                                    'Crop Partitions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2D4A35),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$used/${widget.totalLand}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          _isPartitionLimitReached
                                              ? AppColors.error
                                              : const Color(0xFF6B7C6E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index < _partitions.length) {
                                  return _partitionCard(
                                    index,
                                    _partitions[index],
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    _addPartitionButton(
                                      disabled: _isPartitionLimitReached,
                                    ),
                                    if (_isPartitionLimitReached) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add disabled: partition count cannot be greater than total land (${widget.totalLand.toStringAsFixed(2)} $_unitLabel).',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }, childCount: _partitions.length + 1),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                            sliver: SliverToBoxAdapter(
                              child: GestureDetector(
                                onTap: _submit,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: double.infinity,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color:
                                        _isReady
                                            ? AppColors.farmerColor
                                            : AppColors.farmerColor.withOpacity(
                                              0.5,
                                            ),
                                    boxShadow:
                                        _isReady
                                            ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF4A7C59,
                                                ).withOpacity(0.35),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ]
                                            : [],
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Complete Registration",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.check_circle_outline_outlined,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color backgroundColor;
  final Widget child;

  _PinnedHeaderDelegate({
    required this.height,
    required this.backgroundColor,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: Align(alignment: Alignment.topCenter, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.child != child;
  }
}

class _LandPartitionInput {
  final TextEditingController cropController;
  final TextEditingController areaController;
  final TextEditingController yieldController;
  DateTime? plantationDate;
  DateTime? harvestingDate;

  // product selection
  int? selectedProductId;
  String? selectedProductName;
  String? selectedCategoryName;

  // expected yield
  String yieldUnit;

  _LandPartitionInput()
    : cropController = TextEditingController(),
      areaController = TextEditingController(),
      yieldController = TextEditingController(),
      yieldUnit = 'kg';

  double get parsedArea => double.tryParse(areaController.text.trim()) ?? 0;
  double? get parsedYield => double.tryParse(yieldController.text.trim());

  void dispose() {
    cropController.dispose();
    areaController.dispose();
    yieldController.dispose();
  }
}