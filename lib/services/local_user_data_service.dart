import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/calorie_target_provider.dart';

/// Clears per-user local data. Keeps the seeded exercises catalog.
/// Also clears [SampleDataTier.settingsKey] so debug can re-seed on next init.
Future<void> clearLocalUserData() async {
  await Hive.box<WorkoutSession>('sessions').clear();
  await Hive.box<Routine>('routines').clear();
  await Hive.box<BodyWeightLog>('bodyWeightLogs').clear();
  await Hive.box<FoodEntry>('foodEntries').clear();
  final settings = Hive.box('settings');
  await settings.delete('height');
  await settings.delete('sampleDataTier');
  for (final key in calorieSettingKeys) {
    await settings.delete(key);
  }
}
