import 'dart:io';
import 'package:client/global/colortheme.dart';
import 'package:client/models/crop_catogory_model.dart';
import 'package:client/repository/add_pickup_repository.dart';
import 'package:client/screens/Farmer/subscription_plan_screen.dart';
import 'package:client/utils/subscription_exception.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:client/widgets/custom_snackbar.dart';
import 'package:client/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:client/global/image_compress.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class DraftCropItem {
  final int productId;
  final String productName;
  final String categoryName;
  final double quantityKg;
  final double expectedPricePerKg;
  final String grade;

  DraftCropItem({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantityKg,
    required this.expectedPricePerKg,
    required this.grade,
  });

  Map<String, dynamic> toMap() => {
    "product_id": productId,
    "quantity_kg": quantityKg,
    "expected_price_per_kg": expectedPricePerKg,
    "grade": grade,
  };
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCropName;
  String? _selectedGrade;

  // Multi-item draft list
  final List<DraftCropItem> _draftItems = [];

  // Photos (1 to 3)
  final List<File> _photos = [];

  // Harvest date
  DateTime? _harvestDate;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final AddPickupRepository _repo = AddPickupRepository();
  bool _isCategoryLoading = true;
  String? _categoryError;
  List<Datum> _categoryModels = [];
  List<String> _categories = [];
  Map<String, List<String>> _cropsByCategory = {};
  int? _selectedProductId;
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryError = null;
    });

    try {
      final model = await _repo.getCropCategories();
      final categories = model.data;
      final categoryNames =
          categories.map((item) => item.categoryName).toList();
      final cropsByCategory = <String, List<String>>{};
      for (final category in categories) {
        cropsByCategory[category.categoryName] =
            category.products.map((p) => p.productName).toList();
      }
      if (!mounted) return;
      setState(() {
        _categoryModels = categories;
        _categories = categoryNames;
        _cropsByCategory = cropsByCategory;
        _isCategoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryError = e.toString();
        _isCategoryLoading = false;
      });
    }
  }

  Future<void> _pickPhotoFromCamera() async {
    if (_photos.isNotEmpty) {
      CustomSnackBar.error(context, "Only one photo allowed");
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final compressed = await ImageCompressHelper.compressAndConvertToPng(
        File(pickedFile.path),
      );

      if (compressed != null) {
        setState(() {
          _photos.clear();
          _photos.add(compressed);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.farmerColor),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.farmerColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  void _addDraftCrop() {
    if (_selectedProductId == null) {
      CustomSnackBar.error(context, "Select crop category and crop name");
      return;
    }
    if (_selectedGrade == null) {
      CustomSnackBar.error(context, "Please select quality grade");
      return;
    }
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      CustomSnackBar.error(context, "Enter valid quantity");
      return;
    }
    final expectedPrice = double.tryParse(_priceController.text.trim());
    if (expectedPrice == null || expectedPrice <= 0) {
      CustomSnackBar.error(context, "Enter valid expected price");
      return;
    }
    final gradeValue = _selectedGrade!.replaceAll('Grade ', '').trim();

    setState(() {
      _draftItems.add(DraftCropItem(
        productId: _selectedProductId!,
        productName: _selectedCropName ?? "Crop",
        categoryName: _selectedCategory ?? "",
        quantityKg: quantity,
        expectedPricePerKg: expectedPrice,
        grade: gradeValue,
      ));
      _quantityController.clear();
      _priceController.clear();
      _selectedCropName = null;
      _selectedProductId = null;
      _selectedGrade = null;
    });

    CustomSnackBar.success(context, "Crop added to request! You can add another crop or submit below.");
  }

  void _submitCrop() {
    // If no draft items yet, try to parse current form input as the single item
    if (_draftItems.isEmpty) {
      if (_selectedProductId == null) {
        CustomSnackBar.error(context, "Select crop category and crop name");
        return;
      }
      if (_selectedGrade == null) {
        CustomSnackBar.error(context, "Please select quality grade");
        return;
      }
      final quantity = double.tryParse(_quantityController.text.trim());
      if (quantity == null || quantity <= 0) {
        CustomSnackBar.error(context, "Enter valid quantity");
        return;
      }
      final expectedPrice = double.tryParse(_priceController.text.trim());
      if (expectedPrice == null || expectedPrice <= 0) {
        CustomSnackBar.error(context, "Enter valid expected price");
        return;
      }
      final gradeValue = _selectedGrade!.replaceAll('Grade ', '').trim();
      _draftItems.add(DraftCropItem(
        productId: _selectedProductId!,
        productName: _selectedCropName ?? "Crop",
        categoryName: _selectedCategory ?? "",
        quantityKg: quantity,
        expectedPricePerKg: expectedPrice,
        grade: gradeValue,
      ));
    }

    if (_photos.isEmpty) {
      CustomSnackBar.error(context, "Please upload at least 1 photo");
      return;
    }

    if (_harvestDate == null) {
      CustomSnackBar.error(context, "Please select harvest date");
      return;
    }

    setState(() => _isLoading = true);

    final primaryItem = _draftItems.first;
    final itemsPayload = _draftItems.map((e) => e.toMap()).toList();

    _repo
        .submitPickup(
          productId: primaryItem.productId,
          quantity: primaryItem.quantityKg,
          expectedPrice: primaryItem.expectedPricePerKg,
          grade: primaryItem.grade,
          harvestDate: _harvestDate!,
          photos: _photos,
          remarks: _remarksController.text,
          items: itemsPayload,
        )
        .then((_) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          CustomSnackBar.success(
            context,
            "Pickup submitted to admin for approval!",
          );
          Navigator.pop(context);
        })
          .catchError((e) {
            if (!mounted) return;
            setState(() => _isLoading = false);

            if (e is SubscriptionRequiredException) {
              CustomSnackBar.show(
                context,
                e.isFlagged
                    ? "Your subscription has been flagged. Contact support to continue."
                    : e.isExpired
                        ? "Your subscription has expired. Renew to submit listings."
                        : "An active subscription is required to submit listings.",
                isError: true,
                duration: const Duration(seconds: 5),
                action: e.isFlagged
                    ? null
                    : SnackBarAction(
                        label: "View Plans",
                        textColor: Colors.white,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPlanScreen(),
                          ),
                        ),
                      ),
              );
              return;
            }

            CustomSnackBar.error(context, "Failed to submit pickup: $e");
          });
  }

  // Add this method inside _AddCropScreenState

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
                color:AppColors.loginBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = filteredItems[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(context, item);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.farmerColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.farmerColor.withOpacity(0.6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      labelBuilder(item),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 18),
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

// Selector card widget (add as a separate class or private widget)
  Widget _buildSelectorCard({
    required String label,
    required String hint,
    required String? value,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.farmerColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: !enabled
                      ? Colors.grey.withOpacity(0.6)
                      : (value != null ? AppColors.farmerColor : Colors.grey),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? null : Colors.grey.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: CustomAppBar(
        centerTitle: true,
        title: "Add New Pickup",
        backgroundColor: AppColors.farmerColor,
        showLeading: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSize.width * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDraftItemsCard(),
              // General Information
              const Text(
                "General Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              const Text(
                "Crop Category",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (_isCategoryLoading)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Crop Category",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text("Loading categories..."),
                    ],
                  ),
                )
              else if (_categoryError != null)
                InkWell(
                  onTap: _loadCategories,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Crop Category",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text("Failed to load. Tap to retry.")),
                      ],
                    ),
                  ),
                )
              else
                _buildSelectorCard(
                  label: "Crop Category",
                  hint: "Select crop category",
                  value: _selectedCategory,
                  onTap: () async {
                    final category = await showSearchableBottomSheet<String>(
                      context: context,
                      title: "Select Crop Category",
                      items: _categories,
                      labelBuilder: (e) => e,
                    );

                    if (category != null) {
                      setState(() {
                        _selectedCategory = category;
                        _selectedCropName = null;
                        _selectedProductId = null;
                      });
                    }
                  },
                ),
              const SizedBox(height: 15),

              const Text(
                "Crop Name",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _buildSelectorCard(
                label: "Crop Name",
                hint: "Select crop name",
                value: _selectedCropName,
                enabled: _selectedCategory != null,
                onTap: _selectedCategory == null
                    ? null
                    : () async {
                  final crop = await showSearchableBottomSheet<String>(
                    context: context,
                    title: "Select Crop Name",
                    items: _cropsByCategory[_selectedCategory] ?? [],
                    labelBuilder: (e) => e,
                  );

                  if (crop != null) {
                    setState(() {
                      _selectedCropName = crop;
                      _selectedProductId = null;
                      for (final category in _categoryModels) {
                        if (category.categoryName != _selectedCategory) continue;
                        for (final product in category.products) {
                          if (product.productName == crop) {
                            _selectedProductId = product.productId;
                            return;
                          }
                        }
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 25),

              // Commercial Details
              const Text(
                "Commercial Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Quantity (kg)",
                      hintText: "0",
                      keyboardType: TextInputType.number,
                      controller: _quantityController,
                      focusedBorderColor: AppColors.farmerColor,
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Expected Price (per kg)",
                      hintText: "0.00",
                      prefixText: "₹ ",
                      focusedBorderColor: AppColors.farmerColor,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      controller: _priceController,
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "The actual price may vary from the expected price",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Quality Grade
              const Text(
                "Quality Grade",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildGradeButton("Grade A", _selectedGrade == "Grade A"),
                  const SizedBox(width: 12),
                  _buildGradeButton("Grade B", _selectedGrade == "Grade B"),
                  const SizedBox(width: 12),
                  _buildGradeButton("Grade C", _selectedGrade == "Grade C"),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addDraftCrop,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.farmerColor),
                  label: const Text(
                    "+ Add Crop to Request List",
                    style: TextStyle(
                      color: AppColors.farmerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.farmerColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Photos
              const Text(
                "Photos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPhotoUploadBox(),
                    ..._photos.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: AppSize.width * 0.25,
                                height: AppSize.width * 0.25,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _photos.remove(file);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
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
              const SizedBox(height: 25),

              // Expected Available Date
              const Text(
                "Harvest Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.farmerColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _harvestDate == null
                            ? "Select date"
                            : DateFormat('dd/MM/yyyy').format(_harvestDate!),
                        style: TextStyle(
                          color: _harvestDate == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              CustomTextField(
                label: "Remarks (optional)",
                hintText: "Enter any additional information",
                controller: _remarksController,
                focusedBorderColor: AppColors.farmerColor,
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitCrop,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                  label: const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.farmerColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Subject to quality check and admin approval",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeButton(String grade, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGrade = grade),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.farmerColor : Colors.white,
            border: Border.all(
              color: isSelected ? AppColors.farmerColor : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              grade,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadBox() {
    return GestureDetector(
      onTap: _pickPhotoFromCamera,
      child: Container(
        width: AppSize.width * 0.25,
        height: AppSize.width * 0.25,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 32, color: AppColors.farmerColor),
              SizedBox(height: 8),
              Text(
                "Take Photo",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftItemsCard() {
    if (_draftItems.isEmpty) return const SizedBox.shrink();

    final totalQty = _draftItems.fold<double>(0.0, (sum, item) => sum + item.quantityKg);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.farmerColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  Text(
                    "Crops in Request (${_draftItems.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.farmerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Total: ${totalQty.toStringAsFixed(1)} kg",
                  style: TextStyle(
                    color: AppColors.farmerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _draftItems.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _draftItems[index];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.farmerColor.withOpacity(0.12),
                    child: Text(
                      item.grade,
                      style: TextStyle(
                        color: AppColors.farmerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${item.quantityKg} kg  •  ₹${item.expectedPricePerKg}/kg",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    onPressed: () {
                      setState(() {
                        _draftItems.removeAt(index);
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}