import 'package:flutter_test/flutter_test.dart';
import 'package:larger/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty email', () {
      expect(validateEmail(''), 'Enter your email');
      expect(validateEmail('   '), 'Enter your email');
      expect(validateEmail(null), 'Enter your email');
    });

    test('rejects invalid email', () {
      expect(validateEmail('not-an-email'), 'Enter a valid email');
      expect(validateEmail('missing@domain'), 'Enter a valid email');
    });

    test('accepts a basic email', () {
      expect(validateEmail('user@example.com'), isNull);
      expect(validateEmail('  user@example.com  '), isNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty password', () {
      expect(validatePassword(''), 'Enter your password');
      expect(validatePassword(null), 'Enter your password');
    });

    test('rejects short password', () {
      expect(validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('accepts password with 6+ characters', () {
      expect(validatePassword('123456'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('rejects mismatch', () {
      expect(
        validateConfirmPassword('abcdef', '123456'),
        'Passwords do not match',
      );
    });

    test('accepts matching password', () {
      expect(validateConfirmPassword('123456', '123456'), isNull);
    });
  });

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
