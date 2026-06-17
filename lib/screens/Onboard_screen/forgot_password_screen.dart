// import 'package:client/screens/Onboard_screen/otp_verification_screen.dart';
// import 'package:client/global/colortheme.dart';
// import 'package:client/widgets/custom_snackbar.dart';
// import 'package:client/widgets/custom_text_field.dart';
// import 'package:flutter/material.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _mobileController = TextEditingController();
//   bool _isLoading = false;

//   void _sendOTP() {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);

//       // TODO: Call backend to send OTP to this number

//       Future.delayed(const Duration(seconds: 2), () {
//         setState(() => _isLoading = false);

//         CustomSnackBar.success(context, "OTP sent to your mobile number");

//         // Navigate to OTP screen
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (context) => ForgotOTPVerificationScreen(
//                   mobileNumber: "+91${_mobileController.text.trim()}",
//                   isResetPassword: true, // flag to know it's for reset
//                 ),
//           ),
//         );
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     AppSize.init(context);
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.primaryGreen),
//           onPressed: () => Navigator.pop(context),
//         ),
//         backgroundColor: AppColors.background,
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: AppSize.width * 0.06,
//             vertical: AppSize.height * 0.04,
//           ),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: Image.asset(
//                     "assets/images/logo.png",
//                     height: 250,
//                     width: 250,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//                 const Text(
//                   "Reset Your Password",
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   "Enter your registered mobile number to receive OTP",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 48),

//                 CustomTextField(
//                   label: "Mobile Number",
//                   hintText: "Enter 10-digit mobile number",
//                   prefix: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.phone_rounded,
//                           color: AppColors.primaryGreen,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           "+91",
//                           style: TextStyle(
//                             color: AppColors.textPrimary,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   controller: _mobileController,
//                   keyboardType: TextInputType.number,
//                   maxLength: 10,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter mobile number';
//                     }
//                     final trimmed = value.trim();
//                     if (trimmed.length != 10) {
//                       return 'Enter valid 10-digit number';
//                     }
//                     if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
//                       return 'Mobile number should start with 6-9';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 40),

//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _sendOTP,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryGreen,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                     ),
//                     child:
//                         _isLoading
//                             ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2.5,
//                               ),
//                             )
//                             : const Text(
//                               "Get OTP",
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
