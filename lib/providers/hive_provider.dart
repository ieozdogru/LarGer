import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/services/dev_sample_data.dart';

Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(RoutineAdapter());
  Hive.registerAdapter(WorkoutSetAdapter());
  Hive.registerAdapter(WorkoutExerciseAdapter());
  Hive.registerAdapter(WorkoutSessionAdapter());
  Hive.registerAdapter(BodyWeightLogAdapter());
  Hive.registerAdapter(RoutineExerciseAdapter());
  Hive.registerAdapter(FoodEntryAdapter());

  await Hive.openBox<Exercise>('exercises');
  await Hive.openBox<Routine>('routines');
  await Hive.openBox<WorkoutSession>('sessions');
  await Hive.openBox<WorkoutSession>('activeWorkout');
  await Hive.openBox<BodyWeightLog>('bodyWeightLogs');
  await Hive.openBox<FoodEntry>('foodEntries');
  await Hive.openBox('settings');

  final exerciseBox = Hive.box<Exercise>('exercises');
  if (exerciseBox.isEmpty) {
    // Seed massive list of initial exercises
    final initialExercises = [
      // Chest
      Exercise(name: 'Bench Press', category: 'Chest'),
      Exercise(name: 'Incline Bench Press', category: 'Chest'),
      Exercise(name: 'Decline Bench Press', category: 'Chest'),
      Exercise(name: 'Dumbbell Bench Press', category: 'Chest'),
      Exercise(name: 'Incline Dumbbell Press', category: 'Chest'),
      Exercise(name: 'Cable Crossover', category: 'Chest'),
      Exercise(name: 'Pec Deck Fly', category: 'Chest'),
      Exercise(name: 'Push Up', category: 'Chest'),
      Exercise(name: 'Dips', category: 'Chest'),

      // Back
      Exercise(name: 'Deadlift', category: 'Back'),
      Exercise(name: 'Pull Up', category: 'Back'),
      Exercise(name: 'Lat Pulldown', category: 'Back'),
      Exercise(name: 'Barbell Row', category: 'Back'),
      Exercise(name: 'Dumbbell Row', category: 'Back'),
      Exercise(name: 'Seated Cable Row', category: 'Back'),
      Exercise(name: 'T-Bar Row', category: 'Back'),
      Exercise(name: 'Face Pull', category: 'Back'),
      Exercise(name: 'Straight Arm Pulldown', category: 'Back'),

      // Shoulders
      Exercise(name: 'Overhead Press', category: 'Shoulders'),
      Exercise(name: 'Dumbbell Shoulder Press', category: 'Shoulders'),
      Exercise(name: 'Arnold Press', category: 'Shoulders'),
      Exercise(name: 'Lateral Raise', category: 'Shoulders'),
      Exercise(name: 'Cable Lateral Raise', category: 'Shoulders'),
      Exercise(name: 'Front Raise', category: 'Shoulders'),
      Exercise(name: 'Reverse Pec Deck', category: 'Shoulders'),
      Exercise(name: 'Upright Row', category: 'Shoulders'),
      Exercise(name: 'Shrugs', category: 'Shoulders'),

      // Quads
      Exercise(name: 'Squat', category: 'Quads'),
      Exercise(name: 'Front Squat', category: 'Quads'),
      Exercise(name: 'Leg Press', category: 'Quads'),
      Exercise(name: 'Hack Squat', category: 'Quads'),
      Exercise(name: 'Bulgarian Split Squat', category: 'Quads'),
      Exercise(name: 'Lunges', category: 'Quads'),
      Exercise(name: 'Leg Extension', category: 'Quads'),

      // Hamstrings
      Exercise(name: 'Romanian Deadlift', category: 'Hamstrings'),
      Exercise(name: 'Leg Curl', category: 'Hamstrings'),
      Exercise(name: 'Seated Leg Curl', category: 'Hamstrings'),
      Exercise(name: 'Good Mornings', category: 'Hamstrings'),

      // Calves
      Exercise(name: 'Standing Calf Raise', category: 'Calves'),
      Exercise(name: 'Seated Calf Raise', category: 'Calves'),
      Exercise(name: 'Leg Press Calf Raise', category: 'Calves'),

      // Biceps
      Exercise(name: 'Barbell Curl', category: 'Biceps'),
      Exercise(name: 'Dumbbell Curl', category: 'Biceps'),
      Exercise(name: 'Hammer Curl', category: 'Biceps'),
      Exercise(name: 'Preacher Curl', category: 'Biceps'),
      Exercise(name: 'Cable Curl', category: 'Biceps'),
      Exercise(name: 'Concentration Curl', category: 'Biceps'),

      // Triceps
      Exercise(name: 'Tricep Pushdown', category: 'Triceps'),
      Exercise(name: 'Overhead Tricep Extension', category: 'Triceps'),
      Exercise(name: 'Skullcrushers', category: 'Triceps'),
      Exercise(name: 'Close Grip Bench Press', category: 'Triceps'),
      Exercise(name: 'Tricep Kickback', category: 'Triceps'),

      // Abs
      Exercise(name: 'Crunch', category: 'Abs'),
      Exercise(name: 'Plank', category: 'Abs'),
      Exercise(name: 'Leg Raise', category: 'Abs'),
      Exercise(name: 'Cable Crunch', category: 'Abs'),
      Exercise(name: 'Ab Wheel Rollout', category: 'Abs'),
      Exercise(name: 'Russian Twist', category: 'Abs'),
    ];
    for (var ex in initialExercises) {
      await exerciseBox.put(ex.id, ex);
    }
  }

  // Append user's specific exercises if missing
  final newExercises = [
    Exercise(name: 'Squat (Bar)', category: 'Quads'),
    Exercise(name: 'Deadlift (Bar)', category: 'Back'),
    Exercise(name: 'Romanian Deadlift (Bar)', category: 'Hamstrings'),
    Exercise(name: 'Leg Extension (machine)', category: 'Quads'),
    Exercise(name: 'Hip Abduction (machine)', category: 'Glutes'),
    Exercise(name: 'Calf Press (machine)', category: 'Calves'),
    Exercise(name: 'Jump Squat', category: 'Quads'),
    Exercise(name: 'Incline Bench Press (Smith Machine)', category: 'Chest'),
    Exercise(name: 'Cable Fly Crossovers', category: 'Chest'),
    Exercise(name: 'Cable Row - Wide Grip', category: 'Back'),
    Exercise(name: 'one handed Lat Pulldown', category: 'Back'),
    Exercise(name: 'Rope Straight Arm Pulldown', category: 'Back'),
    Exercise(name: 'Shoulder Press (machine)', category: 'Shoulders'),
    Exercise(name: 'Lateral Raise (Cable)', category: 'Shoulders'),
    Exercise(name: 'Rear Delt Reverse Fly (machine)', category: 'Shoulders'),
    Exercise(name: 'Hammer Curl (Cable)', category: 'Biceps'),
    Exercise(name: 'Overhead Curl (Cable)', category: 'Biceps'),
    Exercise(name: 'Overhead Triceps Extension (Cable)', category: 'Triceps'),
    Exercise(name: 'Triceps Pushdown', category: 'Triceps'),
    Exercise(name: 'Wrist Extension (Bar)', category: 'Forearms'),
  ];

  final existingNames = exerciseBox.values
      .map((e) => e.name.toLowerCase())
      .toSet();

  for (var ex in newExercises) {
    if (!existingNames.contains(ex.name.toLowerCase())) {
      await exerciseBox.put(ex.id, ex);
    }
  }

  await seedDevSampleDataIfNeeded();
}

final hiveInitProvider = FutureProvider<void>((ref) async {
  await initHive();
});
