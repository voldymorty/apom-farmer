import 'package:client/models/crop_catogory_model.dart';
import 'package:flutter/material.dart';

/// Result of picking a crop/product from the shared crop picker sheet.
class CropSelection {
  final int productId;
  final String productName;
  final String categoryName;
  final String unit;

  const CropSelection({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.unit,
  });
}

/// Shows the category → product picker bottom sheet backed by the
/// Crop API (`GET /farmer-crops/categories`). Used identically by the
/// farmer onboarding land partition screen and the Land tab, so both
/// flows select crops the same way.
Future<CropSelection?> showCropPickerSheet(
  BuildContext context, {
  required List<Datum> categories,
  bool categoriesLoading = false,
}) {
  return showModalBottomSheet<CropSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      Datum? selectedCategory;
      String categorySearch = '';
      String productSearch = '';

      return StatefulBuilder(
        builder: (context, setSheetState) {
          // ── STEP 2: Product list ──
          if (selectedCategory != null) {
            final filtered = selectedCategory!.products
                .where((p) => p.productName
                    .toLowerCase()
                    .contains(productSearch.toLowerCase()))
                .toList();

            return _bottomSheetContainer(
              context: context,
              child: Column(
                children: [
                  _sheetHeader(
                    title: selectedCategory!.categoryName,
                    onBack: () => setSheetState(() {
                      selectedCategory = null;
                      productSearch = '';
                    }),
                  ),
                  const SizedBox(height: 12),
                  _sheetSearchField(
                    hint: 'Search product...',
                    onChanged: (v) => setSheetState(() => productSearch = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? _sheetEmptyState('No products found')
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final product = filtered[i];
                              return ListTile(
                                onTap: () {
                                  Navigator.pop(
                                    sheetContext,
                                    CropSelection(
                                      productId: product.productId,
                                      productName: product.productName,
                                      categoryName:
                                          selectedCategory!.categoryName,
                                      unit: product.unit,
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFF3ECE1),
                                  child: Text(
                                    product.productName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7C6E),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  product.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF2D4A35),
                                  ),
                                ),
                                subtitle: Text(
                                  product.unit,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF7C8C7F),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF9AA89C),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          // ── STEP 1: Category list ──
          final filteredCats = categories
              .where((c) => c.categoryName
                  .toLowerCase()
                  .contains(categorySearch.toLowerCase()))
              .toList();

          return _bottomSheetContainer(
            context: context,
            child: Column(
              children: [
                _sheetHeader(title: 'Select Category'),
                const SizedBox(height: 12),
                _sheetSearchField(
                  hint: 'Search category...',
                  onChanged: (v) => setSheetState(() => categorySearch = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: categoriesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredCats.isEmpty
                          ? _sheetEmptyState('No categories found')
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filteredCats.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final cat = filteredCats[i];
                                return ListTile(
                                  onTap: () =>
                                      setSheetState(() => selectedCategory = cat),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFF3ECE1),
                                    child: Text(
                                      cat.categoryName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B7C6E),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    cat.categoryName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF2D4A35),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${cat.products.length} product${cat.products.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF7C8C7F),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF9AA89C),
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

// ── Shared sheet helper widgets ──

Widget _bottomSheetContainer({required BuildContext context, required Widget child}) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.72,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: child,
  );
}

Widget _sheetHeader({required String title, VoidCallback? onBack}) {
  return Row(
    children: [
      if (onBack != null) ...[
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Color(0xFF2D4A35)),
          ),
        ),
        const SizedBox(width: 10),
      ],
      if (onBack == null)
        Expanded(
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C9B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D4A35))),
            ],
          ),
        )
      else
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D4A35))),
        ),
    ],
  );
}

Widget _sheetSearchField({
  required String hint,
  required ValueChanged<String> onChanged,
}) {
  return TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA89C)),
      prefixIcon: const Icon(Icons.search_rounded,
          size: 20, color: Color(0xFF7A8C7D)),
      filled: true,
      fillColor: const Color(0xFFF5F0E8),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _sheetEmptyState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off_rounded,
            size: 48, color: Color(0xFFD4C9B0)),
        const SizedBox(height: 12),
        Text(message,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9AA89C),
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}