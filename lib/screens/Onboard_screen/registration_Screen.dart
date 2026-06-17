// import 'package:client/screens/Onboard_screen/login.dart';
// import 'package:client/screens/Onboard_screen/reg_otp_Screen.dart';
// import 'package:client/global/colortheme.dart';
// import 'package:client/widgets/custom_snackbar.dart';
// import 'package:client/widgets/custom_text_field.dart';
// import 'package:client/repository/login_repository.dart';
// import 'package:flutter/material.dart';

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // Common fields only
//   final _nameController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   // Role

//   bool _obscurePassword = true;
//   bool _obscureConfirm = true;
//   bool _isLoading = false;

//   void _handleSubmit() {
//     if (_formKey.currentState!.validate()) {
//       if (_passwordController.text != _confirmPasswordController.text) {
//         CustomSnackBar.error(context, "Passwords do not match");
//         return;
//       }

//       setState(() => _isLoading = true);

//       final loginRepo = LoginRepository();
//       loginRepo.sendOtp(_mobileController.text.trim()).then((response) {
//         if (!mounted) return;
//         setState(() => _isLoading = false);

//         if (response['success'] == true) {
//           CustomSnackBar.success(context, "OTP sent successfully!");
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => OTPVerificationScreen(
//                     mobileNumber: "+91${_mobileController.text.trim()}",
//                   ),
//             ),
//           );
//         } else {
//           CustomSnackBar.error(
//             context,
//             response['message'] ?? "Failed to send OTP",
//           );
//         }
//       }).catchError((e) {
//         if (!mounted) return;
//         setState(() => _isLoading = false);
//         CustomSnackBar.error(context, "An error occurred: $e");
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _mobileController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     AppSize.init(context);
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: AppSize.width * 0.06,
//           vertical: AppSize.height * 0.02,
//         ),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Image.asset(
//                   "assets/images/logo.png",
//                   height: AppSize.height * 0.3,
//                   width: AppSize.width * 0.6,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               SizedBox(height: AppSize.height * 0.02),

//               Text(
//                 "Farmer's Registration",
//                 style: TextStyle(
//                   fontSize: AppSize.width * 0.05,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               SizedBox(height: AppSize.height * 0.01),
//               Text(
//                 "Fill your details to register as a farmer.",
//                 style: TextStyle(
//                   fontSize: AppSize.width * 0.038,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.textSecondary,
//                   height: 1.4,
//                 ),
//               ),
//               SizedBox(height: AppSize.height * 0.03),

//               // Radio buttons for role

//               // Only these 4 fields for both roles
//               CustomTextField(
//                 label: "Full Name",
//                 hintText: "Enter your full name",
//                 controller: _nameController,
//                 validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
//               ),
//               SizedBox(height: AppSize.height * 0.03),

//               CustomTextField(
//                 label: "Mobile Number",
//                 hintText: "Enter mobile number",
//                 prefix: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.phone_rounded, color: AppColors.primaryGreen),
//                       const SizedBox(width: 8),
//                       Text(
//                         "+91",
//                         style: TextStyle(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w500,
//                           fontSize: 18,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 controller: _mobileController,
//                 keyboardType: TextInputType.number,
//                 maxLength: 10,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) return 'Required';
//                   final trimmed = value.trim();
//                   if (trimmed.length != 10) return '10 digits required';
//                   if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
//                     return 'Invalid mobile';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 24),

//               CustomTextField(
//                 label: "Create Password",
//                 hintText: "Minimum 8 characters",
//                 prefixIcon: Icons.lock_outline_rounded,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off_outlined,
//                     color: AppColors.textSecondary,
//                   ),
//                   onPressed:
//                       () =>
//                           setState(() => _obscurePassword = !_obscurePassword),
//                 ),
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 validator: (v) {
//                   if (v == null || v.isEmpty) return 'Required';
//                   if (v.length < 8) return 'Min 8 characters';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 24),

//               CustomTextField(
//                 label: "Confirm Password",
//                 hintText: "Re-type password",
//                 prefixIcon: Icons.lock_outline_rounded,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscureConfirm
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off_outlined,
//                     color: AppColors.textSecondary,
//                   ),
//                   onPressed:
//                       () => setState(() => _obscureConfirm = !_obscureConfirm),
//                 ),
//                 controller: _confirmPasswordController,
//                 obscureText: _obscureConfirm,
//                 validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
//               ),

//               SizedBox(height: AppSize.height * 0.06),

//               // Get OTP Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _handleSubmit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryGreen,
//                     padding: EdgeInsets.symmetric(
//                       vertical: AppSize.height * 0.02,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child:
//                       _isLoading
//                           ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2.5,
//                             ),
//                           )
//                           : const Text(
//                             "Get OTP",
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                 ),
//               ),

//               SizedBox(height: AppSize.height * 0.03),

//               // Already have account? Login
//               Center(
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       "Already have an account? ",
//                       style: TextStyle(color: AppColors.textSecondary),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const LoginScreen(),
//                           ),
//                         );
//                       },
//                       child: Text(
//                         "Login",
//                         style: TextStyle(
//                           color: AppColors.primaryGreen,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: AppSize.height * 0.05),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
