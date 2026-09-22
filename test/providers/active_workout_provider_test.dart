import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/active_workout_provider.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late ActiveWorkoutNotifier notifier;

  setUp(() async {
    await setUpHiveForTests();
    container = ProviderContainer();
    notifier = container.read(activeWorkoutProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveForTests();
  });

  group('ActiveWorkoutNotifier', () {
    test('startWorkout initializes active state', () {
      notifier.startWorkout(routineName: 'Push');

      final state = container.read(activeWorkoutProvider);
      expect(state, isNotNull);
      expect(state!.routineName, 'Push');
      expect(state.exercises, isEmpty);
    });

    test('addExercise appends a new exercise with one set', () {
      notifier.startWorkout();
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Bench', category: 'Chest'));

      final state = container.read(activeWorkoutProvider)!;
      expect(state.exercises, hasLength(1));
      expect(state.exercises.first.exerciseName, 'Bench');
      expect(state.exercises.first.sets, hasLength(1));
    });

    test('addExercise ignores duplicates', () {
      notifier.startWorkout();
      final exercise = Exercise(id: 'ex-1', name: 'Bench', category: 'Chest');
      expect(notifier.addExercise(exercise), isTrue);
      expect(notifier.addExercise(exercise), isFalse);

      expect(container.read(activeWorkoutProvider)!.exercises, hasLength(1));
    });

    test('updateSet keeps the set id', () {
      notifier.startWorkout();
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Bench', category: 'Chest'));
      final id = container
          .read(activeWorkoutProvider)!
          .exercises
          .first
          .sets
          .first
          .id;

      notifier.updateSet(0, 0, reps: 8, weight: 60, isCompleted: true);

      expect(
        container.read(activeWorkoutProvider)!.exercises.first.sets.first.id,
        id,
      );
    });

    test('addSet copies previous set values', () {
      notifier.startWorkout();
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Bench', category: 'Chest'));
      notifier.updateSet(0, 0, reps: 8, weight: 60);
      notifier.addSet(0);

      final sets = container.read(activeWorkoutProvider)!.exercises.first.sets;
      expect(sets, hasLength(2));
      expect(sets.last.reps, 8);
      expect(sets.last.weight, 60);
      expect(sets.last.isCompleted, isFalse);
    });

    test('updateSet changes reps weight and completion', () {
      notifier.startWorkout();
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Squat', category: 'Legs'));
      notifier.updateSet(0, 0, reps: 5, weight: 100, isCompleted: true);

      final set = container.read(activeWorkoutProvider)!.exercises.first.sets.first;
      expect(set.reps, 5);
      expect(set.weight, 100);
      expect(set.isCompleted, isTrue);
    });

    test('removeSet and removeExercise update state', () {
      notifier.startWorkout();
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Squat', category: 'Legs'));
      notifier.addSet(0);
      notifier.removeSet(0, 1);
      expect(container.read(activeWorkoutProvider)!.exercises.first.sets, hasLength(1));

      notifier.removeExercise(0);
      expect(container.read(activeWorkoutProvider)!.exercises, isEmpty);
    });

    test('reorderExercises moves items', () {
      notifier.startWorkout();
      notifier.addExercise(Exercise(id: 'a', name: 'A', category: 'Chest'));
      notifier.addExercise(Exercise(id: 'b', name: 'B', category: 'Back'));
      notifier.reorderExercises(0, 1);

      final names = container
          .read(activeWorkoutProvider)!
          .exercises
          .map((e) => e.exerciseName)
          .toList();
      expect(names, ['B', 'A']);
    });

    test('cancelWorkout clears state', () {
      notifier.startWorkout();
      notifier.cancelWorkout();
      expect(container.read(activeWorkoutProvider), isNull);
    });

    test('finishWorkout saves completed volume and clears state', () async {
      notifier.startWorkout(routineName: 'Legs');
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Squat', category: 'Legs'));
      notifier.updateSet(0, 0, reps: 5, weight: 100, isCompleted: true);
      notifier.addSet(0);
      notifier.updateSet(0, 1, reps: 5, weight: 100, isCompleted: false);

      final session = await notifier.finishWorkout();

      expect(session, isNotNull);
      expect(session!.routineName, 'Legs');
      expect(session.totalVolume, 500);
      expect(session.isCompleted, isTrue);
      expect(container.read(activeWorkoutProvider), isNull);

      final box = Hive.box<WorkoutSession>('sessions');
      expect(box.values, hasLength(1));
      expect(box.values.first.totalVolume, 500);
    });

    test('methods no-op when workout is inactive', () {
      notifier.addExercise(Exercise(id: 'ex-1', name: 'Bench', category: 'Chest'));
      notifier.addSet(0);
      notifier.updateSet(0, 0, reps: 1);
      notifier.removeSet(0, 0);
      notifier.removeExercise(0);
      notifier.reorderExercises(0, 1);

      expect(container.read(activeWorkoutProvider), isNull);
    });
  });
}
