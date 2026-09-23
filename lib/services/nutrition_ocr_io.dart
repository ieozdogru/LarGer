import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class NutritionOcrService {
  const NutritionOcrService();

  bool get isSupported {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<String?> recognize(ImageSource source) async {
    if (!isSupported) return null;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 95,
    );
    if (file == null) return null;

    final recognizer = TextRecognizer();
    try {
      final input = InputImage.fromFilePath(file.path);
      final result = await recognizer.processImage(input);
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } finally {
      await recognizer.close();
    }
  }
}
