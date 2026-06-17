import 'package:client/screens/Onboard_screen/splash_Screen.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  // Initialize Notification Service with error handling
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize AppSize HERE where context is available
    // AppSize.init(context); // Uncomment if you have AppSize class

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Farmer',
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
      ),
      home: const SplashScreen(),
    );
  }
}
