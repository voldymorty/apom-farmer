import 'dart:io';
import 'package:client/screens/Onboard_screen/farmer_land_details.dart';
import 'package:client/screens/Onboard_screen/reg_loc_picker.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/repository/profileSetup_repo.dart';
import 'package:client/models/district_model.dart';
import 'package:client/models/city_model.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:client/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FarmerLocationScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String fullName;
  final String aadharNumber;
  final String farmName;
  final File profilePhoto;

  const FarmerLocationScreen({
    super.key,
    required this.mobile,
    required this.fullName,
    required this.aadharNumber,
    required this.farmName,
    required this.profilePhoto,
  });

  @override
  ConsumerState<FarmerLocationScreen> createState() => _FarmerLocationScreenState();
}

class _FarmerLocationScreenState extends ConsumerState<FarmerLocationScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedState;
  int? _selectedStateId;
  String? _selectedDistrict;
  int? _selectedDistrictId;
  String? _selectedCity;
  int? _selectedCityId;
  String _mapAddress = "";
  double? _latitude;
  double? _longitude;
  final TextEditingController _pincodeController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // Future<void> _pickMapLocation() async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
  //   );
  //   if (result != null && result is Map<String, dynamic>) {
  //     setState(() {
  //       _mapAddress = result['address'] ?? '';
  //       _latitude = result['latitude'];
  //       _longitude = result['longitude'];
  //     });
  //   }
  // }

  Future<void> _pickMapLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _mapAddress = result['address'] ?? '';
        _latitude = result['latitude'];
        _longitude = result['longitude'];

        final detectedPincode = result['pincode']?.toString();

        if (detectedPincode != null &&
            RegExp(r'^\d{6}$').hasMatch(detectedPincode)) {
          _pincodeController.text = detectedPincode;
        }
      });
    }
  }

  bool get _isFormComplete =>
      _selectedDistrict != null &&
      _selectedCity != null &&
      _mapAddress.isNotEmpty &&
      _pincodeController.text.trim().length == 6;

  void _next() {
    if (!_isFormComplete) {
      CustomSnackBar.error(context, "Please complete all location fields");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FarmerLandDetailsScreen(
              mobile: widget.mobile,
              fullName: widget.fullName,
              aadharNumber: widget.aadharNumber,
              farmName: widget.farmName,
              profilePhoto: widget.profilePhoto,
              stateId: _selectedStateId?.toString() ?? "0",
              districtId: _selectedDistrictId?.toString() ?? "0",
              cityId: _selectedCityId?.toString() ?? "0",
              locationAddress: _mapAddress,
              pincode: _pincodeController.text.trim(),
              latitude: _latitude ?? 11.0168,
              longitude: _longitude ?? 76.9558,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(statesProvider);

    // Watch districts only if state is selected
    final String districtArg = (_selectedStateId != null && _selectedState != null)
        ? "$_selectedStateId|$_selectedState"
        : "";
    final districtsAsync = districtArg.isNotEmpty
        ? ref.watch(districtsProvider(districtArg))
        : const AsyncValue<DistrictDetailsModel?>.data(null);

    // Watch cities only if district is selected
    final String cityArg = (_selectedDistrictId != null && _selectedDistrict != null)
        ? "$_selectedDistrictId|$_selectedDistrict"
        : "";
    final citiesAsync = cityArg.isNotEmpty
        ? ref.watch(citiesProvider(cityArg))
        : const AsyncValue<CityDetailsModel?>.data(null);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.farmerColor.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB5841A).withOpacity(0.09),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header bar
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
                      // Step indicator — step 2 active
                      Row(
                        children: List.generate(4, (i) {
                          final isActive = i == 1;
                          final isDone = i < 1;
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

                // Scrollable content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Headline
                            const Text(
                              "Where's\nYour Farm?",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: Color(0xFF1E3025),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Share your farm’s location.",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7C6E),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Progress chips
                            _LocationProgressRow(
                              state: _selectedState,
                              district: _selectedDistrict,
                              city: _selectedCity,
                              hasPinned: _mapAddress.isNotEmpty,
                            ),

                            const SizedBox(height: 28),

                              // State dropdown
                            _SearchableField(
                              label: "State",
                              icon: Icons.map_rounded,
                              hint: statesAsync.when(
                                data: (_) => "Select your state",
                                loading: () => "Loading states...",
                                error: (_, __) => "Error loading states",
                              ),
                              value: _selectedState,
                              items: statesAsync.when(
                                data: (model) => model?.data.map((e) => e.stateName).toList() ?? [],
                                loading: () => [],
                                error: (_, __) => [],
                              ),
                              onChanged:
                                  (v) {
                                    if (v == null) return;
                                    final state = statesAsync.value?.data.firstWhere((e) => e.stateName == v);
                                    setState(() {
                                      _selectedState = v;
                                      _selectedStateId = state?.stateId;
                                      _selectedDistrict = null;
                                      _selectedDistrictId = null;
                                      _selectedCity = null;
                                      _selectedCityId = null;
                                    });
                                  },
                            ),

                            // District dropdown (animated appearance)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child:
                                  _selectedState != null
                                      ? Column(
                                        children: [
                                          const SizedBox(height: 14),
                                          _SearchableField(
                                            label: "District",
                                            icon: Icons.location_city_rounded,
                                            hint: districtsAsync.when(
                                              data: (_) => "Select your district",
                                              loading: () => "Loading districts...",
                                              error: (_, __) => "Error loading districts",
                                            ),
                                            value: _selectedDistrict,
                                            items: districtsAsync.when(
                                              data: (model) => model?.data.map((e) => e.districtName).toList() ?? [],
                                              loading: () => [],
                                              error: (_, __) => [],
                                            ),
                                            onChanged:
                                                (v) {
                                                  if (v == null) return;
                                                  final district = districtsAsync.value?.data.firstWhere((e) => e.districtName == v);
                                                  setState(() {
                                                    _selectedDistrict = v;
                                                    _selectedDistrictId = district?.districtId;
                                                    _selectedCity = null;
                                                    _selectedCityId = null;
                                                  });
                                                },
                                          ),
                                        ],
                                      )
                                      : const SizedBox.shrink(),
                            ),

                            // City dropdown (animated appearance)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child:
                                  _selectedDistrict != null
                                      ? Column(
                                        children: [
                                          const SizedBox(height: 14),
                                          _SearchableField(
                                              label: "City / Taluk",
                                              icon: Icons.storefront_rounded,
                                              hint: citiesAsync.when(
                                                data: (_) => "Select your city",
                                                loading: () => "Loading cities...",
                                                error: (_, __) => "Error loading cities",
                                              ),
                                              value: _selectedCity,
                                              items: citiesAsync.when(
                                                data: (model) => model?.data.map((e) => e.cityName).toList() ?? [],
                                                loading: () => [],
                                                error: (_, __) => [],
                                              ),
                                              onChanged:
                                                  (v) {
                                                    if (v == null) return;
                                                    final city = citiesAsync.value?.data.firstWhere((e) => e.cityName == v);
                                                    setState(() {
                                                      _selectedCity = v;
                                                      _selectedCityId = city?.cityId;
                                                    });
                                                  },
                                            ),
                                        ],
                                      )
                                      : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 20),

                            // Map pin selector
                            GestureDetector(
                              onTap: _pickMapLocation,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color:
                                      _mapAddress.isNotEmpty
                                          ? AppColors.farmerColor.withOpacity(
                                            0.08,
                                          )
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        _mapAddress.isNotEmpty
                                            ? AppColors.farmerColor
                                            : const Color(0xFFD4C9B0),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            _mapAddress.isNotEmpty
                                                ? AppColors.farmerColor
                                                : const Color(0xFFF0EBE0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _mapAddress.isNotEmpty
                                            ? Icons.location_on_rounded
                                            : Icons.add_location_alt_outlined,
                                        color:
                                            _mapAddress.isNotEmpty
                                                ? Colors.white
                                                : AppColors.farmerColor
                                                    .withOpacity(0.5),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _mapAddress.isEmpty
                                                ? "Pin exact location on map"
                                                : "Location pinned",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _mapAddress.isNotEmpty
                                                      ? Colors.black
                                                      : const Color(0xFF4A4A4A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _mapAddress.isEmpty
                                                ? "Tap to open map and drop a pin"
                                                : _mapAddress,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  _mapAddress.isNotEmpty
                                                      ? AppColors.farmerColor
                                                      : const Color(0xFF9AA89C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _mapAddress.isNotEmpty
                                          ? Icons.check_circle_rounded
                                          : Icons.chevron_right_rounded,
                                      color:
                                          _mapAddress.isNotEmpty
                                              ? AppColors.farmerColor
                                              : const Color(0xFFB8C4BA),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                      CustomTextField(
                        label: "Pincode",
                        hintText: "Enter 6-digit pincode",
                        prefixIcon: Icons.pin_drop_outlined,
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length != 6) return '6 digits required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color:
                            _isFormComplete
                                ? AppColors.farmerColor
                                : AppColors.farmerColor.withOpacity(0.5),
                        boxShadow:
                            _isFormComplete
                                ? [
                                  BoxShadow(
                                    color: AppColors.farmerColor.withOpacity(
                                      0.35,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                                : [],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
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

// ─── Progress chips row ──────────────────────────────────────────────────────

class _LocationProgressRow extends StatelessWidget {
  final String? state;
  final String? district;
  final String? city;
  final bool hasPinned;

  const _LocationProgressRow({
    required this.state,
    required this.district,
    required this.city,
    required this.hasPinned,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: "State", done: state != null),
      (label: "District", done: district != null),
      (label: "City", done: city != null),
      (label: "Pinned", done: hasPinned),
    ];

    return Row(
      children:
          steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            step.done
                                ? AppColors.farmerColor
                                : AppColors.farmerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            step.done
                                ? Icons.check_rounded
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color:
                                step.done
                                    ? Colors.white
                                    : AppColors.farmerColor.withOpacity(0.2),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  step.done
                                      ? Colors.white
                                      : AppColors.farmerColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 8,
                      height: 1.5,
                      color: const Color(0xFFD4C9B0),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

// ─── Searchable field (replaces _DropdownCard) ────────────────────────────────

// ─── Searchable field (uses new bottom sheet design) ──────────────────────

class _SearchableField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SearchableField({
    required this.label,
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  Future<void> _openSheet(BuildContext context) async {
    final selected = await showSearchableBottomSheet<String>(
      context: context,
      title: label,
      items: items,
      labelBuilder: (e) => e,
    );
    if (selected != null) onChanged(selected);
  }

  Future<T?> showSearchableBottomSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
  }) async {
    final controller = TextEditingController();

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        List<T> filteredItems = List.from(items);

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: AppColors.loginBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Search $title",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredItems = items.where((e) {
                            return labelBuilder(e)
                                .toLowerCase()
                                .contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20,
                      ),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = filteredItems[index];

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(
                                  context, item);
                            },
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.farmerColor
                                    .withOpacity(0.06),
                                borderRadius:
                                BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.farmerColor
                                      .withOpacity(0.6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      labelBuilder(item),
                                      style:
                                      const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    return GestureDetector(
      onTap: items.isEmpty ? null : () => _openSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasValue
                ? AppColors.farmerColor.withOpacity(0.5)
                : const Color(0xFFD4C9B0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue
                  ? AppColors.farmerColor
                  : AppColors.farmerColor.withOpacity(0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? const Color(0xFF1E3025)
                      : AppColors.farmerColor.withOpacity(0.5),
                ),
              ),
            ),
            if (hasValue)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.farmerColor, size: 18)
            else
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.farmerColor.withOpacity(0.5), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Searchable bottom sheet ──────────────────────────────────────────────────

class _SearchableBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selected;

  const _SearchableBottomSheet({
    required this.title,
    required this.items,
    this.selected,
  });

  @override
  State<_SearchableBottomSheet> createState() => _SearchableBottomSheetState();
}

class _SearchableBottomSheetState extends State<_SearchableBottomSheet> {
  late List<String> _filtered;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.items
            : widget.items
                .where((e) => e.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F0E8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C9B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      "Select ${widget.title}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3025),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF2D4A35)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFD4C9B0), width: 1.5),
                  ),
                  child: TextField(
                    controller: _search,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF1E3025)),
                    decoration: InputDecoration(
                      hintText: "Search ${widget.title.toLowerCase()}...",
                      hintStyle: TextStyle(
                          color: AppColors.farmerColor.withOpacity(0.4),
                          fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.farmerColor.withOpacity(0.5),
                          size: 20),
                      suffixIcon: _search.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _search.clear(),
                              child: Icon(Icons.clear_rounded,
                                  color:
                                      AppColors.farmerColor.withOpacity(0.4),
                                  size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${_filtered.length} result${_filtered.length == 1 ? '' : 's'}",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.farmerColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 40,
                                color:
                                    AppColors.farmerColor.withOpacity(0.25)),
                            const SizedBox(height: 10),
                            Text(
                              "No results for \"${_search.text}\"",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.farmerColor.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFEDE8DE),
                        ),
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final isSelected = item == widget.selected;
                          return InkWell(
                            onTap: () => Navigator.pop(context, item),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.farmerColor
                                            : const Color(0xFF2D4A35),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_rounded,
                                        color: AppColors.farmerColor,
                                        size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
