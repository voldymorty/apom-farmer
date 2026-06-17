import 'package:flutter/material.dart';

/// Color Theme for Wholesale Fruits & Vegetables Management App
class AppColors {
  // Role-based colors
  static const Color farmerColor = Color(0xFF5D4037);
  static const Color vendorColor = Color(0xFFFAC638); //0xFFFFC107
  static const Color deliveryColor = Color(0xFF389CFA);
  // Primary theme colors
  static const Color primaryGreen = Color(0xFF5D4037); //0xFF2E7D32
  static const Color lightGreen = Color(0xFFE8F5E9);

  // UI colors
  static const Color background = Color(0xFFF9FAF7);
  static const Color loginBackground = Color(0xFFE8DED3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFE0E0E0);

  // Status colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2ECC71);

  // Helper methods
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'farmer':
        return farmerColor;
      case 'vendor':
        return vendorColor;
      case 'delivery':
        return deliveryColor;
      default:
        return primaryGreen;
    }
  }
}

class AppSize {
  static late double width;
  static late double height;

  static void init(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
  }
}
