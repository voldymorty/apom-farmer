import 'dart:io';
import 'package:client/repository/profileSetup_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/screens/Onboard_screen/login.dart';
import 'package:client/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:client/screens/Farmer/about_screen.dart';
import 'package:client/screens/Farmer/help_support_screen.dart';
import 'package:client/screens/Farmer/terms_conditions_screen.dart';
import 'package:client/models/profile_detail_model.dart';
import 'package:client/models/state_model.dart' as state_model;
import 'package:client/models/district_model.dart' as district_model;
import 'package:client/models/city_model.dart' as city_model;
import 'package:image_picker/image_picker.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/custom_app_bar.dart';
import 'account_setting_screen.dart';

class FarmerProfileScreen extends ConsumerWidget {
  const FarmerProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(profileSetupRepoProvider).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String confirmText = "";
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Delete Account"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "This action will deactivate your account and cannot be undone.",
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setDialogState(() => confirmText = value),
                  decoration: const InputDecoration(
                    labelText: "Type DELETE to confirm",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed:
                confirmText.trim().toUpperCase() == "DELETE"
                    ? () async {
                  Navigator.pop(dialogContext);
                  final success =
                  await ref.read(profileSetupRepoProvider).deleteAccount();
                  if (success && context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                          (route) => false,
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Failed to delete account. Please try again.",
                        ),
                      ),
                    );
                  }
                }
                    : null,
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, Profile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditProfileSheet(initialProfile: profile),
    );
  }

  void _openWebView(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppSize.init(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: CustomAppBar(
        showBackButton: false,
        title: "My Profile",
        backgroundColor: AppColors.farmerColor,
        elevation: 0,

      ),
      body: profileAsync.when(
        data: (profileData) {
          if (profileData == null || !profileData.success) {
            return const Center(child: Text("Failed to load profile"));
          }
          final userProfile = profileData.data.profile;
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Profile Header Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.farmerColor.withOpacity(0.1),
                        AppColors.farmerColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.farmerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.farmerColor.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundImage: userProfile.profilePhotoUrl != null
                                  ? NetworkImage(userProfile.profilePhotoUrl!)
                                  : const NetworkImage(
                                "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500",
                              ),
                            ),
                          ),
                          if (profileData.data.isVerified)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.fullName,
                              style: TextStyle(
                                fontSize: AppSize.width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            //   decoration: BoxDecoration(
                            //     color: AppColors.farmerColor.withOpacity(0.1),
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: Text(
                            //     "ID: #${userProfile.farmerId}",
                            //     style: TextStyle(
                            //       color: AppColors.farmerColor,
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.w600,
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${userProfile.cityInfo.cityName}, ${userProfile.stateInfo.stateName}",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Cards Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.currency_rupee_sharp,
                          label: "Total Earnings",
                          value: "₹ ${userProfile.totalEarnings}",
                          color: AppColors.farmerColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Menu Sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildMenuSection(
                        title: "ACCOUNT",
                        items: [
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            title: "Account Settings",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AccountSettingScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildMenuSection(
                        title: "INFORMATION",
                        items: [
                          _MenuItem(
                            icon: Icons.description_outlined,
                            title: "Terms & Conditions",
                            subtitle: "T&C for using our platform",
                            onTap: () => _openWebView(context, "https://apom.in/terms-conditions", "Terms & Conditions"),
                          ),
                          _MenuItem(
                            icon: Icons.privacy_tip_outlined,
                            title: "Privacy Policy",
                            subtitle: "How we handle your data",
                            onTap: () => _openWebView(context, "https://apom.in/privacy-policy", "Privacy Policy"),
                          ),
                          _MenuItem(
                            icon: Icons.receipt_outlined,
                            title: "Refund & Cancellation",
                            subtitle: "Policy for refunds and cancellations",
                            onTap: () => _openWebView(context, "https://apom.in/refund-cancellation", "Refund & Cancellation"),
                          ),
                          _MenuItem(
                            icon: Icons.support_agent_outlined,
                            title: "Help & Support",
                            subtitle: "Get help with your queries",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HelpSupportFarmerScreen()),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.info_outline_rounded,
                            title: "About Us",
                            subtitle: "Learn more about Apom",
                            onTap: () => _openWebView(context, "https://apom.in/about", "About Us"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.logout,
                        label: "Logout",
                        subLabel: "Sign out of your account",
                        color: Colors.red,
                        backgroundColor: Colors.transparent,
                        borderColor: Colors.red,
                        onPressed: () => _showLogoutDialog(context, ref),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Version
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 0.5, indent: 15, endIndent: 15),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.farmerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.farmerColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        )
                        : null,
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onTap: item.onTap,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        subtitle:  Text(
          subLabel,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}


// WebView Screen
class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _progress = 0.0;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load page: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.farmerColor),
            ),
          if (_isLoading && _progress == 0.0)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.initialProfile});

  final Profile initialProfile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _pincodeController;
  File? _selectedPhoto;
  bool _isSubmitting = false;
  int? _selectedStateId;
  int? _selectedDistrictId;
  int? _selectedCityId;
  String? _selectedStateName;
  String? _selectedDistrictName;
  String? _selectedCityName;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialProfile.fullName);
    _pincodeController = TextEditingController(text: widget.initialProfile.pincode);
    _selectedStateId = widget.initialProfile.stateId;
    _selectedDistrictId = widget.initialProfile.districtId;
    _selectedCityId = widget.initialProfile.cityId;
    _selectedStateName = widget.initialProfile.stateInfo.stateName;
    _selectedDistrictName = widget.initialProfile.districtInfo.districtName;
    _selectedCityName = widget.initialProfile.cityInfo.cityName;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _selectedPhoto = File(picked.path));
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final pincode = _pincodeController.text.trim();
    final stateId = _selectedStateId;
    final districtId = _selectedDistrictId;
    final cityId = _selectedCityId;

    if (fullName.isEmpty || pincode.isEmpty || stateId == null || districtId == null || cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(profileSetupRepoProvider).editProfile(
      stateId: stateId.toString(),
      districtId: districtId.toString(),
      cityId: cityId.toString(),
      stateName: _selectedStateName,
      districtName: _selectedDistrictName,
      cityName: _selectedCityName,
      fullName: fullName,
      pincode: pincode,
      profilePhoto: _selectedPhoto,
    );
    setState(() => _isSubmitting = false);

    final success = result["success"] == true;
    if (!mounted) return;

    if (success) {
      ref.invalidate(profileProvider);
      Navigator.pop(context);
      CustomSnackBar.success(context, "Profile updated.");
    } else {
      final message = result["message"]?.toString() ?? "Failed to update profile.";
      CustomSnackBar.error(context, message);
    }
  }

  ImageProvider _photoProvider() {
    if (_selectedPhoto != null) {
      return FileImage(_selectedPhoto!);
    }
    final url = widget.initialProfile.profilePhotoUrl?.toString() ?? "";
    if (url.isNotEmpty) {
      return NetworkImage(url);
    }
    return const AssetImage("assets/images/Applogo_padded.png");
  }

  InputDecoration _fieldDecoration(
      String labelText, {
        String? helperText,
        Widget? prefixIcon,
      }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.farmerColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Edit Profile",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Text(
              "Update your personal and location details.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.farmerColor.withOpacity(0.15),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: _photoProvider(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.farmerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _selectedPhoto == null ? "Tap the pencil to change photo" : "Photo selected",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: _fieldDecoration(
                "Full Name",
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            ref.watch(statesProvider).when(
              data: (stateData) {
                final states = stateData?.data ?? <state_model.Datum>[];
                final selectedState =
                states.isEmpty || _selectedStateId == null
                    ? null
                    : states.firstWhere(
                      (s) => s.stateId == _selectedStateId,
                  orElse: () => states.first,
                );
                return DropdownButtonFormField<state_model.Datum>(
                  value: selectedState,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  iconSize: 22,
                  items:
                  states
                      .map(
                        (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.stateName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStateId = value?.stateId;
                      _selectedStateName = value?.stateName;
                      _selectedDistrictId = null;
                      _selectedDistrictName = null;
                      _selectedCityId = null;
                      _selectedCityName = null;
                    });
                  },
                  decoration: _fieldDecoration(
                    "State",
                    prefixIcon: const Icon(Icons.map_outlined),
                  ),
                );
              },
              loading:
                  () => const _LoadingField(labelText: "State"),
              error:
                  (err, stack) =>
                  _ErrorField(labelText: "State", message: err.toString()),
            ),
            const SizedBox(height: 12),
            if (_selectedStateId == null)
              const _DisabledField(labelText: "District")
            else
              ref
                  .watch(
                districtsProvider(
                  '${_selectedStateId!}|${_selectedStateName ?? ""}',
                ),
              )
                  .when(
                data: (districtData) {
                  final districts = districtData?.data ?? <district_model.Datum>[];
                  final selectedDistrict =
                  districts.isEmpty || _selectedDistrictId == null
                      ? null
                      : districts.firstWhere(
                        (d) => d.districtId == _selectedDistrictId,
                    orElse: () => districts.first,
                  );
                  return DropdownButtonFormField<district_model.Datum>(
                    value: selectedDistrict,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    iconSize: 22,
                    items:
                    districts
                        .map(
                          (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          d.districtName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrictId = value?.districtId;
                        _selectedDistrictName = value?.districtName;
                        _selectedCityId = null;
                        _selectedCityName = null;
                      });
                    },
                    decoration: _fieldDecoration(
                      "District",
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                  );
                },
                loading:
                    () => const _LoadingField(labelText: "District"),
                error:
                    (err, stack) =>
                    _ErrorField(labelText: "District", message: err.toString()),
              ),
            const SizedBox(height: 12),
            if (_selectedDistrictId == null)
              const _DisabledField(labelText: "City")
            else
              ref
                  .watch(
                citiesProvider(
                  '${_selectedDistrictId!}|${_selectedDistrictName ?? ""}',
                ),
              )
                  .when(
                data: (cityData) {
                  final cities = cityData?.data ?? <city_model.Datum>[];
                  final selectedCity =
                  cities.isEmpty || _selectedCityId == null
                      ? null
                      : cities.firstWhere(
                        (c) => c.cityId == _selectedCityId,
                    orElse: () => cities.first,
                  );
                  return DropdownButtonFormField<city_model.Datum>(
                    value: selectedCity,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    iconSize: 22,
                    items:
                    cities
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.cityName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value?.cityId;
                        _selectedCityName = value?.cityName;
                      });
                    },
                    decoration: _fieldDecoration(
                      "City",
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                  );
                },
                loading: () => const _LoadingField(labelText: "City"),
                error:
                    (err, stack) =>
                    _ErrorField(labelText: "City", message: err.toString()),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                "Pincode",
                prefixIcon: const Icon(Icons.local_post_office_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.farmerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.farmerColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your location details help us match you with nearby orders.",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.farmerColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  "Save Changes",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField({required this.labelText});

  final String labelText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      child: const SizedBox(
        height: 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.labelText});

  final String labelText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      child: const Text(
        "Select previous field first",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}



class _ErrorField extends StatelessWidget {
  const _ErrorField({required this.labelText, required this.message});

  final String labelText;
  final String message;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        "Failed to load: $message",
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
