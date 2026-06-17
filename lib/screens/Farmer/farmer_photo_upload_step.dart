// import 'dart:io';
// import 'package:client/global/colortheme.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:client/global/image_compress.dart';

// class FarmerPhotoUploadStep extends StatefulWidget {
//   final Function(File?) onPhotoPicked;

//   const FarmerPhotoUploadStep({super.key, required this.onPhotoPicked});

//   @override
//   State<FarmerPhotoUploadStep> createState() => _FarmerPhotoUploadStepState();
// }

// class _FarmerPhotoUploadStepState extends State<FarmerPhotoUploadStep> {
//   File? _photo;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickPhoto() async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       final compressedFile = await ImageCompressHelper.compressAndConvertToPng(
//         File(pickedFile.path),
//       );
//       if (compressedFile != null) {
//         setState(() => _photo = compressedFile);
//         widget.onPhotoPicked(_photo);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Text(
//           "Upload Your Photo",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 24),
//         GestureDetector(
//           onTap: _pickPhoto,
//           child: Container(
//             width: 160,
//             height: 160,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: AppColors.primaryGreen, width: 3),
//               image:
//                   _photo != null
//                       ? DecorationImage(
//                         image: FileImage(_photo!),
//                         fit: BoxFit.cover,
//                       )
//                       : null,
//             ),
//             child:
//                 _photo == null
//                     ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.add_a_photo,
//                           size: 48,
//                           color: AppColors.primaryGreen,
//                         ),
//                         SizedBox(height: 12),
//                         Text(
//                           "Tap to upload",
//                           style: TextStyle(color: AppColors.textSecondary),
//                         ),
//                       ],
//                     )
//                     : null,
//           ),
//         ),
//       ],
//     );
//   }
// }
