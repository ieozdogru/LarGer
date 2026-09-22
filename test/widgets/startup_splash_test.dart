import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/widgets/startup_splash.dart';

void main() {
  testWidgets('startup splash spells the name then finishes', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(home: StartupSplash(onFinished: () => finished = true)),
    );
    await tester.pump();
    expect(find.text('L'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(finished, isFalse);

    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
