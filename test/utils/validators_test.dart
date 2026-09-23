import 'package:flutter_test/flutter_test.dart';
import 'package:larger/utils/validators.dart';

void main() {
  group('validateHeightCm', () {
    test('rejects empty and non-numeric', () {
      expect(validateHeightCm(''), 'Enter your height');
      expect(validateHeightCm('abc'), 'Enter a valid number');
    });

    test('rejects non-positive and absurd values', () {
      expect(validateHeightCm('0'), 'Height must be greater than 0');
      expect(validateHeightCm('-10'), 'Height must be greater than 0');
      expect(validateHeightCm('301'), 'Height must be 300 cm or less');
    });

    test('accepts a normal height', () {
      expect(validateHeightCm('175.5'), isNull);
    });
  });

  group('validateWeightKg', () {
    test('rejects empty and non-numeric', () {
      expect(validateWeightKg(''), 'Enter your weight');
      expect(validateWeightKg('abc'), 'Enter a valid number');
    });

    test('rejects non-positive and absurd values', () {
      expect(validateWeightKg('0'), 'Weight must be greater than 0');
      expect(validateWeightKg('-1'), 'Weight must be greater than 0');
      expect(validateWeightKg('501'), 'Weight must be 500 kg or less');
    });

    test('accepts a normal weight', () {
      expect(validateWeightKg('80.5'), isNull);
    });
  });
}
