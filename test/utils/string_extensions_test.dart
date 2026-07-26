import 'package:flutter_test/flutter_test.dart';
import 'package:larger/utils/string_extensions.dart';

void main() {
  group('StringExtension.toTitleCase', () {
    test('title-cases a simple phrase', () {
      expect('bench press'.toTitleCase(), 'Bench Press');
    });

    test('handles mixed case input', () {
      expect('dEaDlIfT'.toTitleCase(), 'Deadlift');
    });

    test('returns empty string unchanged', () {
      expect(''.toTitleCase(), '');
    });

    test('returns whitespace-only string unchanged', () {
      expect('   '.toTitleCase(), '   ');
    });
  });
}
