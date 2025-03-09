//Loading and running the TensorFlow Lite model.
//Preprocessing images.
//Returning recognized food items.

//temporary code : 
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FoodRecognitionService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/food_model.tflite');
      print("✅ TFLite model loaded successfully");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<String> recognizeFood(File imageFile) async {
    if (_interpreter == null) {
      return "Model not loaded";
    }

    // Load image
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) {
      return "Error decoding image";
    }

    // Preprocess image: Resize & Normalize
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    List<List<List<double>>> input = _imageToByteList(resizedImage);

    // Run inference
    var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);
    _interpreter!.run(input, output);

    // Get the highest confidence prediction
    int maxIndex = 0;
    double maxConfidence = 0.0;
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > maxConfidence) {
        maxConfidence = output[0][i];
        maxIndex = i;
      }
    }

    // Convert index to label (Replace with actual labels from your model)
    List<String> labels = await _loadLabels();
    return labels[maxIndex];
  }

  List<List<List<double>>> _imageToByteList(img.Image image) {
    List<List<List<double>>> input = List.generate(
      224,
      (y) => List.generate(
        224,
        (x) {
          var pixel = image.getPixel(x, y);
          return [(pixel.r / 255.0), (pixel.g / 255.0), (pixel.b / 255.0)];
        },
      ),
    );
    return input;
  }

  Future<List<String>> _loadLabels() async {
    // Replace with your actual label file
    return [
      "Apple", "Banana", "Burger", "Pizza", "Strawberry", "Sushi", "Tomato"
    ];
  }
}