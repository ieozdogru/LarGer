import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/screens/welcome_screen.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveForTests();
  });

  tearDown(() async {
    await tearDownHiveForTests();
  });

  testWidgets('welcome asks one question at a time and saves the answers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WelcomeScreen())),
    );

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Are you a man or a woman?'), findsNothing);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    expect(find.text('Are you a man or a woman?'), findsOneWidget);
    expect(find.text('1 of 6'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    expect(find.text('Pick one'), findsOneWidget);

    await tester.tap(find.text('Men'));
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('How old are you?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '30');
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('How tall are you?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '180');
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('What do you weigh?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '80');
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('How active are you?'), findsOneWidget);
    expect(find.text('How old are you?'), findsNothing);

    await tester.tap(find.text('Moderately active'));
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('What do you want to do?'), findsOneWidget);

    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();
    expect(find.text('How active are you?'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maintain'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('DONE'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    final settings = Hive.box('settings');
    expect(settings.get(welcomeCompletedKey), isTrue);
    expect(settings.get(calorieSexKey), 'male');
    expect(settings.get(calorieAgeKey), 30);
    expect(settings.get(calorieActivityKey), 'moderatelyActive');
    expect(settings.get(calorieGoalKey), 'maintain');
    expect(settings.get('height'), 180);

    final weights = Hive.box<BodyWeightLog>('bodyWeightLogs').values.toList();
    expect(weights, hasLength(1));
    expect(weights.single.weight, 80);
  });

  test(
    'resetWelcome clears the flag so the welcome screen shows again',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Hive.box('settings').put(welcomeCompletedKey, true);
      expect(container.read(welcomeCompletedProvider), isTrue);

      await container.read(calorieSettingsProvider).resetWelcome();

      expect(container.read(welcomeCompletedProvider), isFalse);
      expect(Hive.box('settings').containsKey(welcomeCompletedKey), isFalse);
    },
  );
}
