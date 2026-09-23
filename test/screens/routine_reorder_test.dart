import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/screens/start_workout_screen.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveForTests();
    if (!Hive.isBoxOpen('exercises')) {
      await Hive.openBox<Exercise>('exercises');
    }
    final exercises = Hive.box<Exercise>('exercises');
    await exercises.clear();
    await exercises.put(
      'bench',
      Exercise(id: 'bench', name: 'Bench Press', category: 'Chest'),
    );
    await exercises.put(
      'squat',
      Exercise(id: 'squat', name: 'Squat', category: 'Legs'),
    );
    final routine = Routine(
      id: 'day',
      name: 'Day',
      exercises: [
        RoutineExercise(exerciseId: 'bench', targetSets: 3),
        RoutineExercise(exerciseId: 'squat', targetSets: 4),
      ],
    );
    await Hive.box<Routine>('routines').put(routine.id, routine);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('exercises')) {
      await Hive.box<Exercise>('exercises').clear();
    }
    await tearDownHiveForTests();
  });

  testWidgets('routine builder can reorder exercises', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: StartWorkoutScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Bench Press'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Bench Press')).dy,
      lessThan(tester.getTopLeft(find.text('Squat')).dy),
    );

    await tester.drag(
      find.byIcon(Icons.drag_handle).first,
      const Offset(0, 240),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.getTopLeft(find.text('Squat')).dy,
      lessThan(tester.getTopLeft(find.text('Bench Press')).dy),
    );
  });
}
