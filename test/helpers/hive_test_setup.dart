import 'dart:io';

import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';

Directory? _tempDir;

Future<void> setUpHiveForTests() async {
  if (Hive.isBoxOpen('routines')) {
    await Hive.box<Routine>('routines').clear();
  }
  if (Hive.isBoxOpen('sessions')) {
    await Hive.box<WorkoutSession>('sessions').clear();
  }
  if (Hive.isBoxOpen('activeWorkout')) {
    await Hive.box<WorkoutSession>('activeWorkout').clear();
  }
  if (Hive.isBoxOpen('bodyWeightLogs')) {
    await Hive.box<BodyWeightLog>('bodyWeightLogs').clear();
  }
  if (Hive.isBoxOpen('foodEntries')) {
    await Hive.box<FoodEntry>('foodEntries').clear();
  }
  if (Hive.isBoxOpen('settings')) {
    await Hive.box('settings').clear();
  }

  if (_tempDir != null) {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.openBox<WorkoutSession>('sessions');
    }
    if (!Hive.isBoxOpen('activeWorkout')) {
      await Hive.openBox<WorkoutSession>('activeWorkout');
    }
    if (!Hive.isBoxOpen('bodyWeightLogs')) {
      await Hive.openBox<BodyWeightLog>('bodyWeightLogs');
    }
    if (!Hive.isBoxOpen('foodEntries')) {
      await Hive.openBox<FoodEntry>('foodEntries');
    }
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
    return;
  }

  _tempDir = await Directory.systemTemp.createTemp('larger_hive_test_');
  Hive.init(_tempDir!.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExerciseAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(RoutineAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(WorkoutSetAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(WorkoutExerciseAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(WorkoutSessionAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(BodyWeightLogAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(RoutineExerciseAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(FoodEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(WorkoutSetKindAdapter());
  }

  await Hive.openBox<Routine>('routines');
  await Hive.openBox<WorkoutSession>('sessions');
  await Hive.openBox<WorkoutSession>('activeWorkout');
  await Hive.openBox<BodyWeightLog>('bodyWeightLogs');
  await Hive.openBox<FoodEntry>('foodEntries');
  await Hive.openBox('settings');
}

Future<void> tearDownHiveForTests() async {
  if (Hive.isBoxOpen('routines')) {
    await Hive.box<Routine>('routines').clear();
  }
  if (Hive.isBoxOpen('sessions')) {
    await Hive.box<WorkoutSession>('sessions').clear();
  }
  if (Hive.isBoxOpen('activeWorkout')) {
    await Hive.box<WorkoutSession>('activeWorkout').clear();
  }
  if (Hive.isBoxOpen('bodyWeightLogs')) {
    await Hive.box<BodyWeightLog>('bodyWeightLogs').clear();
  }
  if (Hive.isBoxOpen('foodEntries')) {
    await Hive.box<FoodEntry>('foodEntries').clear();
  }
  if (Hive.isBoxOpen('settings')) {
    await Hive.box('settings').clear();
  }
}
