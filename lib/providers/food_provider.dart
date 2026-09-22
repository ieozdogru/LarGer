import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';

const foodMeals = ['breakfast', 'lunch', 'dinner', 'snack'];

DateTime normalizeFoodDay(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

class FoodDayTotals {
  const FoodDayTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.hasAllMacros = false,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final bool hasAllMacros;
}

final foodEntriesProvider = FutureProvider<List<FoodEntry>>((ref) async {
  final box = Hive.box<FoodEntry>('foodEntries');
  final entries = box.values.toList()
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  return entries;
});

final foodEntriesForDayProvider =
    Provider.family<AsyncValue<List<FoodEntry>>, DateTime>((ref, day) {
      final normalized = normalizeFoodDay(day);
      return ref.watch(foodEntriesProvider).whenData((entries) {
        return entries.where((entry) {
          final logged = normalizeFoodDay(entry.loggedAt);
          return logged == normalized;
        }).toList();
      });
    });

final foodDayTotalsProvider =
    Provider.family<AsyncValue<FoodDayTotals>, DateTime>((ref, day) {
      return ref
          .watch(foodEntriesForDayProvider(normalizeFoodDay(day)))
          .whenData((entries) {
            var calories = 0.0;
            var protein = 0.0;
            var carbs = 0.0;
            var fat = 0.0;
            var sawProtein = false;
            var sawCarbs = false;
            var sawFat = false;
            for (final entry in entries) {
              calories += entry.totalCalories ?? 0;
              if (entry.totalProteinG != null) {
                protein += entry.totalProteinG!;
                sawProtein = true;
              }
              if (entry.totalCarbsG != null) {
                carbs += entry.totalCarbsG!;
                sawCarbs = true;
              }
              if (entry.totalFatG != null) {
                fat += entry.totalFatG!;
                sawFat = true;
              }
            }
            return FoodDayTotals(
              calories: calories,
              proteinG: protein,
              carbsG: carbs,
              fatG: fat,
              hasAllMacros: sawProtein && sawCarbs && sawFat,
            );
          });
    });

final foodDaysWithEntriesProvider = Provider<AsyncValue<Set<DateTime>>>((ref) {
  return ref.watch(foodEntriesProvider).whenData((entries) {
    return entries.map((entry) => normalizeFoodDay(entry.loggedAt)).toSet();
  });
});

class FoodNotifier {
  FoodNotifier(this.ref);

  final Ref ref;

  Future<void> save(FoodEntry entry) async {
    await Hive.box<FoodEntry>('foodEntries').put(entry.id, entry);
    ref.invalidate(foodEntriesProvider);
  }

  Future<void> delete(String id) async {
    await Hive.box<FoodEntry>('foodEntries').delete(id);
    ref.invalidate(foodEntriesProvider);
  }
}

final foodNotifierProvider = Provider<FoodNotifier>((ref) {
  return FoodNotifier(ref);
});
