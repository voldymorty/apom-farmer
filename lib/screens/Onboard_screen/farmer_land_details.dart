import 'dart:io';
import 'package:client/screens/Onboard_screen/farmer_land_partition.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:client/global/image_compress.dart';

class FarmerLandDetailsScreen extends StatefulWidget {
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

  const FarmerLandDetailsScreen({
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
  });

  @override
  State<FarmerLandDetailsScreen> createState() =>
      _FarmerLandDetailsScreenState();
}

class _FarmerLandDetailsScreenState extends State<FarmerLandDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _quantityController = TextEditingController();
  String _selectedUnit = 'cent';
  File? _landPhoto;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _units = [
    {'value': 'cent', 'label': 'Cent', 'sub': '≈ 436 sq ft'},
    {'value': 'acres', 'label': 'Acres', 'sub': '≈ 43,560 sq ft'},
    {'value': 'hectares', 'label': 'Hectares', 'sub': '≈ 107,639 sq ft'},
  ];

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
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickLandPhoto() async {
    _showImagePickerSheet();
  }

  Future<void> _pickFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) {
      final compressedFile = await ImageCompressHelper.compressAndConvertToPng(
        File(file.path),
      );
      if (compressedFile != null) {
        setState(() => _landPhoto = compressedFile);
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C9B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Add Land Photo",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3025),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7C6E)),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: _SheetOption(
                        icon: Icons.photo_library_rounded,
                        label: "Gallery",
                        color: AppColors.farmerColor,
                        onTap: () {
                          Navigator.pop(context);
                          _pickFromSource(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SheetOption(
                        icon: Icons.camera_alt_rounded,
                        label: "Camera",
                        color: const Color(0xFFB5841A),
                        onTap: () {
                          Navigator.pop(context);
                          _pickFromSource(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A9E8D),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _submit() {
    final qty = _quantityController.text.trim();
    final totalLand = double.tryParse(qty);
    if (qty.isEmpty || totalLand == null || totalLand <= 0) {
      CustomSnackBar.error(context, "Please enter your land size");
      return;
    }
    if (_landPhoto == null) {
      CustomSnackBar.error(context, "Please add a photo of your land");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FarmerLandPartitionScreen(
              mobile: widget.mobile,
              fullName: widget.fullName,
              aadharNumber: widget.aadharNumber,
              farmName: widget.farmName,
              profilePhoto: widget.profilePhoto,
              stateId: widget.stateId,
              districtId: widget.districtId,
              cityId: widget.cityId,
              locationAddress: widget.locationAddress,
              pincode: widget.pincode,
              latitude: widget.latitude,
              longitude: widget.longitude,
              totalLand: totalLand,
              landUnit: _selectedUnit,
              landPhoto: _landPhoto!,
            ),
      ),
    );
  }

  bool get _isReady =>
      _quantityController.text.trim().isNotEmpty && _landPhoto != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -40,
            right: -60,
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
                      // Step indicator — step 3 active
                      Row(
                        children: List.generate(4, (i) {
                          final isActive = i == 2;
                          final isDone = i < 2;
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Headline
                            const Text(
                              "Your Land\nDetails",
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
                              "Specify your land area\nand add a photo of your farm.",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7C6E),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Land size section ──────────────────────
                            const _SectionLabel(
                              icon: Icons.landscape_rounded,
                              text: "Land Size",
                            ),
                            const SizedBox(height: 12),

                            // Input + unit selector combined card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      _isReady
                                          ? AppColors.farmerColor.withOpacity(
                                            0.5,
                                          )
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
                                  // Number input
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(
                                          7,
                                        ), // Max 7 digits
                                      ],
                                      onChanged: (_) => setState(() {}),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E3025),
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
                                            ),
                                        hintText: "0",
                                        hintStyle: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Color(
                                            0xFF1E3025,
                                          ).withOpacity(0.15),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 44,
                                    color: const Color(0xFFE8E2D6),
                                  ),
                                  // Unit selector
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedUnit,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.farmerColor,
                                          size: 20,
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.farmerColor,
                                        ),
                                        items:
                                            _units
                                                .map(
                                                  (u) => DropdownMenuItem(
                                                    value: u['value'] as String,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          u['label'] as String,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Color(
                                                                  0xFF1E3025,
                                                                ),
                                                              ),
                                                        ),
                                                        Text(
                                                          u['sub'] as String,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color: Color(
                                                                  0xFF9AA89C,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedUnit = v!,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Unit info chips ────────────────────────
                            Row(
                              children:
                                  _units.map((u) {
                                    final isSelected =
                                        u['value'] == _selectedUnit;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap:
                                            () => setState(
                                              () =>
                                                  _selectedUnit =
                                                      u['value'] as String,
                                            ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: EdgeInsets.only(
                                            right:
                                                u['value'] != 'hectares'
                                                    ? 8
                                                    : 0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? AppColors.farmerColor
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? AppColors.farmerColor
                                                      : const Color(0xFFD4C9B0),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                u['label'] as String,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFF4A4A4A,
                                                          ),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                u['sub'] as String,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                              .withOpacity(0.75)
                                                          : const Color(
                                                            0xFFABB8AD,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),

                            const SizedBox(height: 32),

                            // ── Land photo section ─────────────────────
                            const _SectionLabel(
                              icon: Icons.photo_camera_rounded,
                              text: "Land Photo",
                            ),
                            const SizedBox(height: 12),

                            GestureDetector(
                              onTap: _pickLandPhoto,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        _landPhoto != null
                                            ? AppColors.farmerColor
                                            : const Color(0xFFE8BABA),
                                    width: 1.5,
                                  ),
                                  color:
                                      _landPhoto != null
                                          ? null
                                          : const Color(0xFFFFF8F8),
                                  image:
                                      _landPhoto != null
                                          ? DecorationImage(
                                            image: FileImage(_landPhoto!),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child:
                                    _landPhoto == null
                                        ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF4A7C59,
                                                ).withOpacity(0.10),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons
                                                    .add_photo_alternate_rounded,
                                                size: 36,
                                                color: AppColors.farmerColor,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Add a photo of your land",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.farmerColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "Tap to upload from gallery or camera",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFB94040),
                                              ),
                                            ),
                                          ],
                                        )
                                        : // Overlay edit button on photo
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.farmerColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Required badge
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom CTA ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                                : AppColors.farmerColor.withOpacity(0.5),
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
                      child: Row(
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

// ─── Section label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.farmerColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.farmerColor),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D4A35),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─── Bottom sheet option tile ──────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.20), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
