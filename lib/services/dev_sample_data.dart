import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';

/// Seeds local demo workouts/routines/body weight for development only.
/// Runs once when sessions are empty in debug builds.
Future<void> seedDevSampleDataIfNeeded() async {
  if (!kDebugMode) return;

  final sessionsBox = Hive.box<WorkoutSession>('sessions');
  if (sessionsBox.isNotEmpty) return;

  final exerciseBox = Hive.box<Exercise>('exercises');
  Exercise? byName(String name) {
    for (final ex in exerciseBox.values) {
      if (ex.name.toLowerCase() == name.toLowerCase()) return ex;
    }
    return null;
  }

  final bench = byName('Bench Press');
  final squat = byName('Squat') ?? byName('Squat (Bar)');
  final deadlift = byName('Deadlift') ?? byName('Deadlift (Bar)');
  final row = byName('Barbell Row');
  final ohp = byName('Overhead Press');

  final available = [bench, squat, deadlift, row, ohp]
      .whereType<Exercise>()
      .toList();
  if (available.isEmpty) return;

  final routinesBox = Hive.box<Routine>('routines');
  if (routinesBox.isEmpty) {
    if (bench != null) {
      final push = Routine(
        name: 'Sample Push',
        exercises: [
          RoutineExercise(exerciseId: bench.id, targetSets: 3),
          if (ohp != null) RoutineExercise(exerciseId: ohp.id, targetSets: 3),
        ],
      );
      await routinesBox.put(push.id, push);
    }
    if (squat != null) {
      final pull = Routine(
        name: 'Sample Legs / Pull',
        exercises: [
          RoutineExercise(exerciseId: squat.id, targetSets: 3),
          if (deadlift != null)
            RoutineExercise(exerciseId: deadlift.id, targetSets: 3),
          if (row != null) RoutineExercise(exerciseId: row.id, targetSets: 3),
        ],
      );
      await routinesBox.put(pull.id, pull);
    }
  }

  WorkoutExercise workoutExercise(
    Exercise exercise, {
    required List<(int reps, double weight)> sets,
  }) {
    return WorkoutExercise()
      ..exerciseId = exercise.id
      ..exerciseName = exercise.name
      ..sets = sets
          .map(
            (s) => WorkoutSet()
              ..reps = s.$1
              ..weight = s.$2
              ..isCompleted = true,
          )
          .toList();
  }

  final now = DateTime.now();
  final sampleSessions = <WorkoutSession>[];

  if (bench != null) {
    sampleSessions.add(
      WorkoutSession()
        ..routineName = 'Sample Push'
        ..startTime = now.subtract(const Duration(days: 14))
        ..endTime = now.subtract(const Duration(days: 14, hours: -1))
        ..isCompleted = true
        ..exercises = [
          workoutExercise(
            bench,
            sets: [(8, 60), (8, 60), (6, 65)],
          ),
          if (ohp != null)
            workoutExercise(ohp, sets: [(8, 40), (8, 40), (6, 42.5)]),
        ]
        ..totalVolume = 60 * 8 + 60 * 8 + 65 * 6 + (ohp != null ? 40 * 8 * 2 + 42.5 * 6 : 0),
    );
    sampleSessions.add(
      WorkoutSession()
        ..routineName = 'Sample Push'
        ..startTime = now.subtract(const Duration(days: 7))
        ..endTime = now.subtract(const Duration(days: 7, hours: -1))
        ..isCompleted = true
        ..exercises = [
          workoutExercise(
            bench,
            sets: [(8, 62.5), (6, 67.5), (5, 70)],
          ),
        ]
        ..totalVolume = 62.5 * 8 + 67.5 * 6 + 70 * 5,
    );
    sampleSessions.add(
      WorkoutSession()
        ..routineName = 'Sample Push'
        ..startTime = now.subtract(const Duration(days: 2))
        ..endTime = now.subtract(const Duration(days: 2, hours: -1))
        ..isCompleted = true
        ..exercises = [
          workoutExercise(
            bench,
            sets: [(5, 72.5), (5, 75), (3, 80)],
          ),
        ]
        ..totalVolume = 72.5 * 5 + 75 * 5 + 80 * 3,
    );
  }

  if (squat != null) {
    sampleSessions.add(
      WorkoutSession()
        ..routineName = 'Sample Legs / Pull'
        ..startTime = now.subtract(const Duration(days: 10))
        ..endTime = now.subtract(const Duration(days: 10, hours: -1))
        ..isCompleted = true
        ..exercises = [
          workoutExercise(squat, sets: [(5, 100), (5, 100), (5, 105)]),
          if (deadlift != null)
            workoutExercise(deadlift, sets: [(5, 120), (5, 120), (3, 130)]),
        ]
        ..totalVolume = 100 * 5 * 2 +
            105 * 5 +
            (deadlift != null ? 120 * 5 * 2 + 130 * 3 : 0),
    );
  }

  for (final session in sampleSessions) {
    await sessionsBox.put(session.id, session);
  }

  final weightBox = Hive.box<BodyWeightLog>('bodyWeightLogs');
  if (weightBox.isEmpty) {
    for (final entry in [
      (21, 82.0),
      (14, 81.4),
      (7, 81.0),
      (1, 80.6),
    ]) {
      final log = BodyWeightLog(
        weight: entry.$2,
        date: now.subtract(Duration(days: entry.$1)),
      );
      await weightBox.put(log.id, log);
    }
  }

  final settings = Hive.box('settings');
  if (!settings.containsKey('height')) {
    await settings.put('height', 178.0);
  }
}
