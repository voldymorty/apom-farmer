// lib/Screens/Onboard_screen/farmer_onboarding/farmer_photo_upload.dart
import 'dart:io';
import 'package:client/screens/Onboard_screen/farmer_location.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:client/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:client/global/image_compress.dart';

class FarmerPhotoUploadScreen extends StatefulWidget {
  final String mobile;
  const FarmerPhotoUploadScreen({super.key, required this.mobile});

  @override
  State<FarmerPhotoUploadScreen> createState() =>
      _FarmerPhotoUploadScreenState();
}

class _FarmerPhotoUploadScreenState extends State<FarmerPhotoUploadScreen>
    with SingleTickerProviderStateMixin {
  File? _farmerPhoto;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _aadharController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 82,
      );

      if (pickedFile == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppColors.farmerColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (cropped != null) {
        final compressedFile = await ImageCompressHelper.compressAndConvertToPng(
          File(cropped.path),
        );
        if (compressedFile != null) {
          setState(() {
            _farmerPhoto = compressedFile;
          });
        }
      }
    } catch (e) {
      CustomSnackBar.error(context, "Error picking/cropping image: $e");
    }
  }

  void _showPickerOptions() {
    if (_farmerPhoto != null) {
      _showPhotoOptionsDialog();
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (_) => _PickerOptionsSheet(
              onGallery: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.gallery);
              },
              onCamera: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.camera);
              },
            ),
      );
    }
  }

  void _showPhotoOptionsDialog() {
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
                const SizedBox(height: 24),
                const Text(
                  "Change Profile Photo",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3025),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _OptionTile(
                        icon: Icons.camera_alt_rounded,
                        label: "Camera",
                        color: const Color(0xFFB5841A),
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndCropImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _OptionTile(
                        icon: Icons.photo_library_rounded,
                        label: "Gallery",
                        color: AppColors.farmerColor,
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndCropImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _farmerPhoto = null);
                    CustomSnackBar.success(context, "Photo removed");
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        "Remove Photo",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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

  void _next() {
    if (_farmerPhoto == null) {
      CustomSnackBar.error(context, "Please add your profile photo");
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      CustomSnackBar.error(context, "Please enter your full name");
      return;
    }
    // if (_aadharController.text.trim().length != 12) {
    //   CustomSnackBar.error(context, "Please enter a valid 12-digit Aadhar number");
    //   return;
    // }
    // if (_farmNameController.text.trim().isEmpty) {
    //   CustomSnackBar.error(context, "Please enter your farm name");
    //   return;
    // }

    setState(() => _isLoading = true);

    // Here you would normally upload the photo
    // For now we simulate + pass path to next screen
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FarmerLocationScreen(
                mobile: widget.mobile,
                fullName: _nameController.text.trim(),
                aadharNumber: _aadharController.text.trim(),
                farmName: _farmNameController.text.trim(),
                profilePhoto: _farmerPhoto!,
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          // Background decorative blobs (unchanged)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.farmerColor.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB5841A).withOpacity(0.10),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar with step indicator (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      Row(
                        children: List.generate(4, (i) {
                          final isActive = i == 0;
                          final isDone = i == 0;
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
                                      ? AppColors.farmerColor.withOpacity(0.5)
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            "Farmer's Profile",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: Color(0xFF1E3025),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Upload a clear profile photo",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7C6E),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // ── Improved Photo Area ──
                          Center(
                            child: ScaleTransition(
                              scale: _scaleAnim,
                              child: GestureDetector(
                                onTap: _showPickerOptions,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 196,
                                      height: 196,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.farmerColor
                                                .withOpacity(0.18),
                                            blurRadius: 32,
                                            offset: const Offset(0, 10),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: Border.all(
                                          color:
                                              _farmerPhoto != null
                                                  ? AppColors.farmerColor
                                                  : const Color(0xFFD4C9B0),
                                          width: 4,
                                        ),
                                        image:
                                            _farmerPhoto != null
                                                ? DecorationImage(
                                                  image: FileImage(
                                                    _farmerPhoto!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                                : null,
                                      ),
                                      child:
                                          _farmerPhoto == null
                                              ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          18,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .farmerColor
                                                          .withOpacity(0.10),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .person_outline_rounded,
                                                      size: 44,
                                                      color:
                                                          AppColors.farmerColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    "Tap to add photo",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.farmerColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : null,
                                    ),

                                    // Edit / Camera badge when photo exists
                                    if (_farmerPhoto != null)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.farmerColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFF5F0E8),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.farmerColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Info card (unchanged)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: Color(0xFFB5841A),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    "Capture your face clearly with good lighting and no shadows.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF5C6B5E),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // --- Full Name Input ---
                          CustomTextField(
                            label: "Full Name",
                            hintText: "Enter your full name",
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // CustomTextField(
                          //   label: "Aadhar Number",
                          //   hintText: "Enter 12-digit Aadhar number",
                          //   prefixIcon: Icons.badge_outlined,
                          //   controller: _aadharController,
                          //   keyboardType: TextInputType.number,
                          //   maxLength: 12,
                          //   validator: (v) {
                          //     if (v == null || v.trim().isEmpty) return 'Required';
                          //     if (v.trim().length != 12) return '12 digits required';
                          //     return null;
                          //   },
                          // ),

                          // const SizedBox(height: 24),

                          // CustomTextField(
                          //   label: "Farm Name",
                          //   hintText: "Enter your farm name",
                          //   prefixIcon: Icons.agriculture_rounded,
                          //   controller: _farmNameController,
                          //   validator: (v) {
                          //     if (v == null || v.trim().isEmpty) return 'Required';
                          //     return null;
                          //   },
                          // ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color:
                                _farmerPhoto != null
                                    ? AppColors.farmerColor
                                    : AppColors.farmerColor.withOpacity(0.5),
                            boxShadow:
                                _farmerPhoto != null
                                    ? [
                                      BoxShadow(
                                        color: AppColors.farmerColor
                                            .withOpacity(0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Center(
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              _farmerPhoto != null
                                                  ? "Continue"
                                                  : "Continue",
                                              style: TextStyle(
                                                color: AppColors.surface,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            10,
                                            0,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: AppColors.surface,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
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

// ── Existing bottom sheet and option tile (unchanged) ──
class _PickerOptionsSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _PickerOptionsSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 24),
          const Text(
            "Add Your Photo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3025),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Choose how you'd like to add your photo",
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7C6E)),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  color: AppColors.farmerColor,
                  onTap: onGallery,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _OptionTile(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  color: const Color(0xFFB5841A),
                  onTap: onCamera,
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
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
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
