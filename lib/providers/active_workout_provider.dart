import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/providers/history_provider.dart';

class ActiveWorkoutState {
  final String? routineName;
  final DateTime startTime;
  final List<WorkoutExercise> exercises;

  ActiveWorkoutState({
    this.routineName,
    required this.startTime,
    this.exercises = const [],
  });

  ActiveWorkoutState copyWith({
    String? routineName,
    DateTime? startTime,
    List<WorkoutExercise>? exercises,
  }) {
    return ActiveWorkoutState(
      routineName: routineName ?? this.routineName,
      startTime: startTime ?? this.startTime,
      exercises: exercises ?? this.exercises,
    );
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref ref;

  ActiveWorkoutNotifier(this.ref) : super(null);

  void startWorkout({
    String? routineName,
    List<WorkoutExercise>? preparedExercises,
  }) {
    state = ActiveWorkoutState(
      routineName: routineName,
      startTime: DateTime.now(),
      exercises: preparedExercises ?? [],
    );
  }

  void addExercise(Exercise exercise) {
    if (state == null) return;

    if (state!.exercises.any((e) => e.exerciseId == exercise.id)) {
      return;
    }

    final newExercise = WorkoutExercise()
      ..exerciseId = exercise.id
      ..exerciseName = exercise.name
      ..sets = [WorkoutSet()];

    state = state!.copyWith(exercises: [...state!.exercises, newExercise]);
  }

  void addSet(int exerciseIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final sets = List<WorkoutSet>.from(exercises[exerciseIndex].sets);

    final lastSet = sets.isNotEmpty ? sets.last : null;
    final newSet = WorkoutSet()
      ..reps = lastSet?.reps ?? 0
      ..weight = lastSet?.weight ?? 0.0;

    sets.add(newSet);

    final newExercise = WorkoutExercise()
      ..exerciseId = exercises[exerciseIndex].exerciseId
      ..exerciseName = exercises[exerciseIndex].exerciseName
      ..sets = sets;

    exercises[exerciseIndex] = newExercise;
    state = state!.copyWith(exercises: exercises);
  }

  void updateSet(
    int exerciseIndex,
    int setIndex, {
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final sets = List<WorkoutSet>.from(exercises[exerciseIndex].sets);

    // Create a new instance instead of mutating the old one so Riverpod detects the state change properly
    final currentSet = sets[setIndex];
    final newSet = WorkoutSet()
      ..reps = reps ?? currentSet.reps
      ..weight = weight ?? currentSet.weight
      ..isCompleted = isCompleted ?? currentSet.isCompleted;

    sets[setIndex] = newSet;

    // Also copy the exercise to prevent mutating it
    final newExercise = WorkoutExercise()
      ..exerciseId = exercises[exerciseIndex].exerciseId
      ..exerciseName = exercises[exerciseIndex].exerciseName
      ..sets = sets;

    exercises[exerciseIndex] = newExercise;
    state = state!.copyWith(exercises: exercises);
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final sets = List<WorkoutSet>.from(exercises[exerciseIndex].sets);
    sets.removeAt(setIndex);

    final newExercise = WorkoutExercise()
      ..exerciseId = exercises[exerciseIndex].exerciseId
      ..exerciseName = exercises[exerciseIndex].exerciseName
      ..sets = sets;

    exercises[exerciseIndex] = newExercise;
    state = state!.copyWith(exercises: exercises);
  }

  void removeExercise(int exerciseIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    exercises.removeAt(exerciseIndex);
    state = state!.copyWith(exercises: exercises);
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    state = state!.copyWith(exercises: exercises);
  }

  void cancelWorkout() {
    state = null;
  }

  Future<WorkoutSession?> finishWorkout() async {
    if (state == null) return null;

    try {
      final box = Hive.box<WorkoutSession>('sessions');

      double totalVolume = 0.0;
      for (var ex in state!.exercises) {
        for (var s in ex.sets) {
          if (s.isCompleted) {
            totalVolume += (s.reps * s.weight);
          }
        }
      }

      final session = WorkoutSession()
        ..routineName = state!.routineName
        ..startTime = state!.startTime
        ..endTime = DateTime.now()
        ..exercises = state!.exercises
        ..totalVolume = totalVolume
        ..isCompleted = true;

      await box.put(session.id, session);

      // Force history screen to refresh automatically
      ref.invalidate(historyProvider);

      state = null;
      return session;
    } catch (e) {
      print('Error saving workout to Hive: $e');
      return null;
    }
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>((ref) {
      return ActiveWorkoutNotifier(ref);
    });
