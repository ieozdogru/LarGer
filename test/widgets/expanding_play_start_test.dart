import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(_dimBlackSurfaces(tester), isEmpty);
  });
}

List<Color> _dimBlackSurfaces(WidgetTester tester) {
  final colors = <Color>[];
  for (final container in tester.widgetList<Container>(find.byType(Container))) {
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
