// import 'package:client/global/colortheme.dart';
// import 'package:client/widgets/custom_snackbar.dart';
// import 'package:client/widgets/custom_text_field.dart';
// import 'package:flutter/material.dart';

// class ResetPasswordScreen extends StatefulWidget {
//   final String mobileNumber;

//   const ResetPasswordScreen({super.key, required this.mobileNumber});

//   @override
//   State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _newPassController = TextEditingController();
//   final _confirmPassController = TextEditingController();
//   bool _obscureNew = true;
//   bool _obscureConfirm = true;
//   bool _isLoading = false;

//   void _resetPassword() {
//     if (_formKey.currentState!.validate()) {
//       if (_newPassController.text != _confirmPassController.text) {
//         CustomSnackBar.error(context, "Passwords do not match");
//         return;
//       }

//       setState(() => _isLoading = true);

//       // TODO: Call backend to reset password using mobile + new password

//       Future.delayed(const Duration(seconds: 2), () {
//         setState(() => _isLoading = false);

//         CustomSnackBar.success(
//           context,
//           "Password reset successful! Please login.",
//         );

//         // Go back to login
//         Navigator.popUntil(context, (route) => route.isFirst);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
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
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Image.asset(
//                   "assets/images/logo.png",
//                   height: 250,
//                   width: 250,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               const Text(
//                 "Create New Password",
//                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "For mobile: ${widget.mobileNumber}",
//                 style: TextStyle(color: AppColors.textSecondary),
//               ),
//               const SizedBox(height: 40),

//               CustomTextField(
//                 label: "New Password",
//                 hintText: "Minimum 8 characters",
//                 prefixIcon: Icons.lock_outline_rounded,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscureNew
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off_outlined,
//                   ),
//                   onPressed: () => setState(() => _obscureNew = !_obscureNew),
//                 ),
//                 controller: _newPassController,
//                 obscureText: _obscureNew,
//                 validator: (v) {
//                   if (v == null || v.isEmpty) return 'Required';
//                   if (v.length < 8) return 'Minimum 8 characters';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 24),

//               CustomTextField(
//                 label: "Confirm New Password",
//                 hintText: "Re-type new password",
//                 prefixIcon: Icons.lock_outline_rounded,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscureConfirm
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off_outlined,
//                   ),
//                   onPressed:
//                       () => setState(() => _obscureConfirm = !_obscureConfirm),
//                 ),
//                 controller: _confirmPassController,
//                 obscureText: _obscureConfirm,
//                 validator: (v) {
//                   if (v == null || v.isEmpty) return 'Required';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 48),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _resetPassword,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryGreen,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child:
//                       _isLoading
//                           ? CircularProgressIndicator(
//                             color: AppColors.primaryGreen,
//                           )
//                           : const Text(
//                             "Submit",
//                             style: TextStyle(
//                               fontSize: 17,
//                               color: AppColors.background,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
