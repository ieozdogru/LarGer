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

  if (_tempDir != null) {
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

  await Hive.openBox<Routine>('routines');
  await Hive.openBox<WorkoutSession>('sessions');
}

Future<void> tearDownHiveForTests() async {
  if (Hive.isBoxOpen('routines')) {
    await Hive.box<Routine>('routines').clear();
  }
  if (Hive.isBoxOpen('sessions')) {
    await Hive.box<WorkoutSession>('sessions').clear();
  }
}
