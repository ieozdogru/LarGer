import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';

/// Clears per-user local data. Keeps the seeded exercises catalog.
Future<void> clearLocalUserData() async {
  await Hive.box<WorkoutSession>('sessions').clear();
  await Hive.box<Routine>('routines').clear();
  await Hive.box<BodyWeightLog>('bodyWeightLogs').clear();
  await Hive.box('settings').delete('height');
}
