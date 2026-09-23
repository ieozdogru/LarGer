import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/active_workout_provider.dart';
import 'package:larger/providers/exercise_provider.dart';
import 'package:larger/screens/active_workout_screen.dart';

Future<void> startEmptyWorkout(WidgetRef ref, BuildContext context) async {
  if (ref.read(activeWorkoutProvider) == null) {
    ref.read(activeWorkoutProvider.notifier).startWorkout();
  }
  if (!context.mounted) return;
  await _openActiveWorkout(context);
}

Future<void> startRoutineWorkout(
  WidgetRef ref,
  BuildContext context,
  Routine routine,
) async {
  if (ref.read(activeWorkoutProvider) != null) {
    if (!context.mounted) return;
    await _openActiveWorkout(context);
    return;
  }

  final allExercises = await ref.read(exercisesProvider.future);

  final preparedExercises = routine.exercises.map((re) {
    final ex = allExercises.firstWhere(
      (e) => e.id == re.exerciseId,
      orElse: () => Exercise(name: 'Unknown', category: ''),
    );
    return WorkoutExercise()
      ..exerciseId = ex.id
      ..exerciseName = ex.name
      ..sets = List.generate(re.targetSets, (_) => WorkoutSet());
  }).toList();

  ref
      .read(activeWorkoutProvider.notifier)
      .startWorkout(
        routineName: routine.name,
        preparedExercises: preparedExercises,
      );
  if (!context.mounted) return;
  await _openActiveWorkout(context);
}

Future<void> _openActiveWorkout(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const ActiveWorkoutScreen()),
  );
}
