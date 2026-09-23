import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';
import 'package:larger/widgets/set_kind_button.dart';

void main() {
  testWidgets('set type button reports the chosen kind', (tester) async {
    WorkoutSetKind? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetKindButton(
            setNumber: 1,
            kind: WorkoutSetKind.working,
            onChanged: (kind) => picked = kind,
          ),
        ),
      ),
    );

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();

    expect(picked, WorkoutSetKind.warmup);
  });
}
