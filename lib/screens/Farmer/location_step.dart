// import 'package:client/screens/Onboard_screen/reg_loc_picker.dart';
// import 'package:client/global/colortheme.dart';
// import 'package:flutter/material.dart';

// class LocationStep extends StatelessWidget {
//   final Function(String?, String?, String?, String?, double?, double?)
//   onLocationSelected;

//   const LocationStep({super.key, required this.onLocationSelected});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Text(
//           "Select Your Location",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 24),
//         ElevatedButton.icon(
//           onPressed: () async {
//             final result = await Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
//             );

//             if (result != null && result is Map<String, dynamic>) {
//               onLocationSelected(
//                 result['state'],
//                 result['district'],
//                 result['city'],
//                 result['address'],
//                 result['latitude'],
//                 result['longitude'],
//               );
//             }
//           },
//           icon: const Icon(Icons.map),
//           label: const Text("Open Map & Select Location"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primaryGreen,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//           ),
//         ),
//       ],
//     );
//   }
// }
