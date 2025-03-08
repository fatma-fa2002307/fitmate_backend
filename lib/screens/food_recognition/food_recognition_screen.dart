// //Displays a simple UI where users can capture a food image.
// //Uses image_picker to open the camera.
// //Calls food_recognition_service.dart to analyze the image.
// //Shows the recognized food name on the screen.
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../../services/food_recognition_services.dart';
//
// class FoodRecognitionScreen extends StatefulWidget {
//   @override
//   _FoodRecognitionScreenState createState() => _FoodRecognitionScreenState();
// }
//
// class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
//   File? _image;
//   String _result = "";
//   final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();
//
//   @override
//   void initState() {
//     super.initState();
//     _foodRecognitionService.loadModel();
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         _result = "Recognizing...";
//       });
//       _recognizeFood();
//     }
//   }
//
//   Future<void> _recognizeFood() async {
//     if (_image == null) return;
//     String prediction = await _foodRecognitionService.recognizeFood(_image!);
//     setState(() {
//       _result = prediction;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Food Recognition")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _image == null ? Text("Take a picture of food") : Image.file(_image!),
//             SizedBox(height: 20),
//             Text(_result, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: _pickImage, child: Text("Capture Food")),
//           ],
//         ),
//       ),
//     );
//   }
// }
