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
}
