import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';

void main() {
  group('Exercise', () {
    test('assigns provided id and fields', () {
      final exercise = Exercise(
        id: 'ex-1',
        name: 'Squat',
        category: 'Legs',
      );

      expect(exercise.id, 'ex-1');
      expect(exercise.name, 'Squat');
      expect(exercise.category, 'Legs');
    });

    test('generates an id when omitted', () {
      final exercise = Exercise(name: 'Bench', category: 'Chest');
      expect(exercise.id, isNotEmpty);
    });
  });

  group('Routine', () {
    test('stores exercises list', () {
      final routine = Routine(
        id: 'r-1',
        name: 'Push Day',
        exercises: [RoutineExercise(exerciseId: 'ex-1', targetSets: 3)],
      );

      expect(routine.id, 'r-1');
      expect(routine.name, 'Push Day');
      expect(routine.exercises, hasLength(1));
      expect(routine.exercises.first.targetSets, 3);
    });
  });

  group('WorkoutSession', () {
    test('starts incomplete with generated id', () {
      final session = WorkoutSession();

      expect(session.id, isNotEmpty);
      expect(session.isCompleted, isFalse);
      expect(session.totalVolume, 0);
      expect(session.exercises, isEmpty);
    });
  });

  group('BodyWeightLog', () {
    test('stores weight and date', () {
      final date = DateTime(2026, 7, 26);
      final log = BodyWeightLog(id: 'bw-1', weight: 80.5, date: date);

      expect(log.id, 'bw-1');
      expect(log.weight, 80.5);
      expect(log.date, date);
    });
  });
}
