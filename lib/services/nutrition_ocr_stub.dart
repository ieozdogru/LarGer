import 'package:image_picker/image_picker.dart';

class NutritionOcrService {
  const NutritionOcrService();

  bool get isSupported => false;

  Future<String?> recognize(ImageSource source) async => null;
}
