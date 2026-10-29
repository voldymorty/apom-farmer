import 'package:client/screens/Farmer/add_Pickup.dart';
import 'package:client/screens/Farmer/orders_screen.dart';
import 'package:client/screens/Farmer/profile_screen.dart';
import 'package:client/screens/Farmer/subscription_gate.dart';
import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:client/screens/Farmer/home.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/screens/Farmer/Land_Screen.dart';
import 'package:flutter/services.dart';

class FarmerBottomNav extends StatefulWidget {
  final List<Map<String, dynamic>> initialLandPartitions;
  final double totalLand;
  final String landUnit;

  const FarmerBottomNav({
    super.key,
    this.initialLandPartitions = const [],
    this.totalLand = 0,
    this.landUnit = 'Acres',
  });

  @override
  State<FarmerBottomNav> createState() => _FarmerBottomNavState();
}

class _FarmerBottomNavState extends State<FarmerBottomNav> {
  int _currentIndex = 0;

  // ICONS
  final List<IconData> iconList = [
    Icons.home_rounded,
    Icons.terrain_rounded,
    Icons.receipt_long_rounded,
    Icons.person_rounded,
  ];

  // LABELS
  final List<String> labels = ["Home", "Land", "Orders", "Profile"];

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text(
          "Are you sure you want to exit the app?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SubscriptionGate(child: FarmerHomeScreen()),
      LandManageScreen(
        initialParcels: widget.initialLandPartitions,
        totalLand: widget.totalLand,
        landUnit: widget.landUnit,
      ),
      const SubscriptionGate(child: MyOrdersScreen()),
      FarmerProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Not on Home tab → go back to Home tab
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // On Home tab → confirm exit
        final shouldExit = await _showExitDialog();
        if (shouldExit && mounted) {
          SystemNavigator.pop(); // closes the app without re-triggering PopScope
        }
      },
      child: Scaffold(
        body: pages[_currentIndex],

        // CENTER FAB
        floatingActionButton: Container(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: AppColors.farmerColor,
            shape: BoxShape.circle,
            // gradient: LinearGradient(
            //   colors: [
            //     AppColors.farmerColor,
            //     AppColors.farmerColor,
            //   ],
            // ),
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.farmerColor.withOpacity(0.5),
            //     blurRadius: 12,
            //     offset: const Offset(0, 4),
            //   )
            // ],
          ),
          child: FloatingActionButton(
            splashColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              setState(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SubscriptionGate(child: AddCropScreen()),
                  ),
                );
              });
            },
            child: Icon(Icons.add, size: 28, color: AppColors.background),
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ANIMATED BOTTOM BAR
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          height: 75,
          itemCount: iconList.length,
          activeIndex: _currentIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          backgroundColor: Color(0xFFE8F5E9),
          leftCornerRadius: 30,
          rightCornerRadius: 30,

          tabBuilder: (index, isActive) {
            final color = isActive ? AppColors.farmerColor : Colors.grey;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconList[index], size: isActive ? 28 : 24, color: color),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: color,
                  ),
                ),
              ],
            );
          },

          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}