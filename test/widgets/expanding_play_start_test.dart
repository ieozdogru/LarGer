import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/widgets/expanding_play_start.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveForTests();
  });

  tearDown(() async {
    await tearDownHiveForTests();
  });

  testWidgets('opening play keeps the page background', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.themeData,
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: ExpandingPlayStart(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Start empty workout'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    expect(_dimBlackSurfaces(tester), isEmpty);
  });

  testWidgets('play menu shows a scroll hint when routines overflow', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final box = Hive.box<Routine>('routines');
      for (var i = 0; i < 4; i++) {
        final routine = Routine(name: 'Routine $i');
        await box.put(routine.id, routine);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.themeData,
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 280,
              child: ExpandingPlayStart(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.text('Routine 0'), findsOneWidget);
  });
}

List<Color> _dimBlackSurfaces(WidgetTester tester) {
  final colors = <Color>[];
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final color = container.color;
    if (color != null && _isDimBlack(color)) colors.add(color);
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.color != null &&
        _isDimBlack(decoration.color!)) {
      colors.add(decoration.color!);
    }
  }
  for (final box in tester.widgetList<ColoredBox>(find.byType(ColoredBox))) {
    if (_isDimBlack(box.color)) colors.add(box.color);
  }
  return colors;
}

bool _isDimBlack(Color color) {
  return color.a > 0.3 && color.r < 0.05 && color.g < 0.05 && color.b < 0.05;
}
