import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/widgets/bounce_button.dart';

void main() {
  testWidgets('BounceButton calls onPressed on tap up', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BounceButton(
            onPressed: () => pressed = true,
            child: const Text('Tap me'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
  });
}
