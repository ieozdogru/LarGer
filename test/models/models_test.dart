import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';

void main() {
  group('Exercise', () {
    test('assigns provided id and fields', () {
      final exercise = Exercise(id: 'ex-1', name: 'Squat', category: 'Legs');

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

  group('WorkoutSet', () {
    test('defaults to a working set that counts when completed', () {
      final set = WorkoutSet()
        ..reps = 5
        ..weight = 100
        ..isCompleted = true;

      expect(set.kind, WorkoutSetKind.working);
      expect(set.countsTowardTotals, isTrue);
    });

    test('a completed warmup set is logged but left out of totals', () {
      final set = WorkoutSet()
        ..reps = 10
        ..weight = 20
        ..isCompleted = true
        ..kind = WorkoutSetKind.warmup;

      expect(set.countsTowardTotals, isFalse);
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

  group('FoodEntry', () {
    test('scales per-serving macros by servings', () {
      final entry = FoodEntry(
        id: 'f-1',
        name: 'Yogurt',
        meal: 'breakfast',
        loggedAt: DateTime(2026, 9, 20),
        servings: 2,
        calories: 100,
        proteinG: 10,
        carbsG: 12,
        fatG: 3,
        source: 'ocr',
      );

      expect(entry.totalCalories, 200);
      expect(entry.totalProteinG, 20);
      expect(entry.totalCarbsG, 24);
      expect(entry.totalFatG, 6);
    });

    test('keeps missing macros null after scaling', () {
      final entry = FoodEntry(
        name: 'Unknown',
        meal: 'snack',
        loggedAt: DateTime(2026, 9, 20),
        calories: 80,
      );

      expect(entry.id, isNotEmpty);
      expect(entry.source, 'manual');
      expect(entry.servings, 1);
      expect(entry.totalCalories, 80);
      expect(entry.totalProteinG, isNull);
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
