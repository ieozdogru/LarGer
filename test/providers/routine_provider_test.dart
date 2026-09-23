import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/routine_provider.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveForTests();
  });

  tearDown(() async {
    await tearDownHiveForTests();
  });

  group('RoutineNotifier', () {
    test('createRoutine adds a routine', () async {
      final notifier = RoutineNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.createRoutine('Push', [
        RoutineExercise(exerciseId: 'ex-1', targetSets: 3),
      ]);

      expect(notifier.state.hasValue, isTrue);
      final routines = notifier.state.value!;
      expect(routines, hasLength(1));
      expect(routines.first.name, 'Push');
      expect(routines.first.exercises.first.targetSets, 3);
    });

    test('updateRoutine changes name and exercises', () async {
      final notifier = RoutineNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.createRoutine('Push', [
        RoutineExercise(exerciseId: 'ex-1', targetSets: 3),
      ]);
      final id = notifier.state.value!.first.id;

      await notifier.updateRoutine(id, 'Push Updated', [
        RoutineExercise(exerciseId: 'ex-2', targetSets: 4),
      ]);

      final routine = notifier.state.value!.first;
      expect(routine.id, id);
      expect(routine.name, 'Push Updated');
      expect(routine.exercises.first.exerciseId, 'ex-2');
      expect(routine.exercises.first.targetSets, 4);
    });

    test('deleteRoutine removes the routine', () async {
      final notifier = RoutineNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.createRoutine('Push', [
        RoutineExercise(exerciseId: 'ex-1', targetSets: 3),
      ]);
      final id = notifier.state.value!.first.id;

      await notifier.deleteRoutine(id);

      expect(notifier.state.value, isEmpty);
    });
  });
}
