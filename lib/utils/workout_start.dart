import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/active_workout_provider.dart';
import 'package:larger/providers/exercise_provider.dart';

Future<void> startEmptyWorkout(WidgetRef ref) async {
  ref.read(activeWorkoutProvider.notifier).startWorkout();
}

Future<void> startRoutineWorkout(WidgetRef ref, Routine routine) async {
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
}
