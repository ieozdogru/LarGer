import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/food_provider.dart';
import 'package:larger/providers/profile_provider.dart';
import 'package:larger/services/calorie_intake.dart';

const calorieSexKey = 'calorieSex';
const calorieAgeKey = 'calorieAge';
const calorieActivityKey = 'calorieActivity';
const calorieBodyFatKey = 'calorieBodyFat';
const calorieGoalKey = 'calorieGoal';
const calorieProteinGoalKey = 'calorieProteinGoal';
const calorieCarbGoalKey = 'calorieCarbGoal';
const calorieLastAdaptiveTdeeKey = 'calorieLastAdaptiveTdee';
const calorieClampedTargetKey = 'calorieClampedTarget';
const calorieTargetUpdatedAtKey = 'calorieTargetUpdatedAt';
const calorieTargetGoalKey = 'calorieTargetGoal';
const welcomeCompletedKey = 'welcomeCompleted';

const calorieSettingKeys = <String>[
  calorieSexKey,
  calorieAgeKey,
  calorieActivityKey,
  calorieBodyFatKey,
  calorieGoalKey,
  calorieProteinGoalKey,
  calorieCarbGoalKey,
  calorieLastAdaptiveTdeeKey,
  calorieClampedTargetKey,
  calorieTargetUpdatedAtKey,
  calorieTargetGoalKey,
];

class CalorieProfile {
  const CalorieProfile({
    this.sex,
    this.ageYears,
    this.activity,
    this.bodyFatPercent,
    this.goal,
    this.proteinGoalG,
    this.carbGoalG,
  });

  final BiologicalSex? sex;
  final int? ageYears;
  final ActivityLevel? activity;
  final double? bodyFatPercent;
  final CalorieGoal? goal;
  final int? proteinGoalG;
  final int? carbGoalG;

  bool get isComplete =>
      sex != null && ageYears != null && activity != null && goal != null;
}

enum CalorieTargetGap { needsProfile, needsWeight }

class CalorieTargetView {
  const CalorieTargetView._({this.resolution, this.gap});

  const CalorieTargetView.ready(CalorieResolution resolution)
    : this._(resolution: resolution);

  const CalorieTargetView.gap(CalorieTargetGap gap) : this._(gap: gap);

  final CalorieResolution? resolution;
  final CalorieTargetGap? gap;
}

final welcomeCompletedProvider = Provider<bool>((ref) {
  return Hive.box('settings').get(welcomeCompletedKey) == true;
});

/// True while the welcome screen's closing reveal is playing.
class WelcomeFarewellController extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;

  void hide() => state = false;
}

final welcomeFarewellProvider =
    NotifierProvider<WelcomeFarewellController, bool>(
      WelcomeFarewellController.new,
    );

final calorieProfileProvider = Provider<CalorieProfile>((ref) {
  final box = Hive.box('settings');
  return CalorieProfile(
    sex: BiologicalSex.parse(box.get(calorieSexKey) as String?),
    ageYears: _asInt(box.get(calorieAgeKey)),
    activity: ActivityLevel.parse(box.get(calorieActivityKey) as String?),
    bodyFatPercent: _asDouble(box.get(calorieBodyFatKey)),
    goal: CalorieGoal.parse(box.get(calorieGoalKey) as String?),
    proteinGoalG: _asInt(box.get(calorieProteinGoalKey)),
    carbGoalG: _asInt(box.get(calorieCarbGoalKey)),
  );
});

final calorieMemoryProvider = Provider<CalorieMemory>((ref) {
  final box = Hive.box('settings');
  final updatedAtMs = _asInt(box.get(calorieTargetUpdatedAtKey));
  return CalorieMemory(
    lastAdaptiveTdee: _asDouble(box.get(calorieLastAdaptiveTdeeKey)),
    clampedTarget: _asDouble(box.get(calorieClampedTargetKey)),
    targetUpdatedAt: updatedAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    goalKey: box.get(calorieTargetGoalKey) as String?,
  );
});

final calorieTargetProvider = Provider<AsyncValue<CalorieTargetView>>((ref) {
  final profile = ref.watch(calorieProfileProvider);
  if (!profile.isComplete) {
    return const AsyncValue.data(
      CalorieTargetView.gap(CalorieTargetGap.needsProfile),
    );
  }

  final height = ref.watch(heightProvider);
  final weights = ref.watch(bodyWeightProvider);
  final foods = ref.watch(foodEntriesProvider);
  final memory = ref.watch(calorieMemoryProvider);

  if (weights.isLoading || foods.isLoading) {
    return const AsyncValue.loading();
  }
  if (weights.hasError) {
    return AsyncValue.error(weights.error!, weights.stackTrace!);
  }
  if (foods.hasError) {
    return AsyncValue.error(foods.error!, foods.stackTrace!);
  }

  final logs = weights.requireValue;
  if (logs.isEmpty) {
    return const AsyncValue.data(
      CalorieTargetView.gap(CalorieTargetGap.needsWeight),
    );
  }

  final resolution = resolveCalorieTarget(
    sex: profile.sex!,
    ageYears: profile.ageYears!,
    heightCm: height,
    weightKg: logs.first.weight,
    activity: profile.activity!,
    bodyFatPercent: profile.bodyFatPercent,
    goal: profile.goal!,
    weighIns: [for (final log in logs) WeighIn(at: log.date, kg: log.weight)],
    intakes: _intakesByDay(foods.requireValue),
    memory: memory,
    asOf: DateTime.now(),
  );
  if (!memory.sameAs(resolution.memory)) {
    Future.microtask(() {
      ref.read(calorieSettingsProvider).syncMemory(resolution.memory);
    });
  }
  return AsyncValue.data(CalorieTargetView.ready(resolution));
});

class CalorieSettingsNotifier {
  CalorieSettingsNotifier(this.ref);

  final Ref ref;

  Future<void> saveProfile({
    required BiologicalSex sex,
    required int ageYears,
    required ActivityLevel activity,
    required double? bodyFatPercent,
    required CalorieGoal goal,
  }) async {
    final box = Hive.box('settings');
    await box.put(calorieSexKey, sex.name);
    await box.put(calorieAgeKey, ageYears);
    await box.put(calorieActivityKey, activity.name);
    if (bodyFatPercent == null) {
      await box.delete(calorieBodyFatKey);
    } else {
      await box.put(calorieBodyFatKey, bodyFatPercent);
    }
    await box.put(calorieGoalKey, goal.name);
    ref.invalidate(calorieProfileProvider);
  }

  Future<void> saveMacroGoals({int? proteinG, int? carbsG}) async {
    final box = Hive.box('settings');
    await _putOrDelete(box, calorieProteinGoalKey, proteinG);
    await _putOrDelete(box, calorieCarbGoalKey, carbsG);
    ref.invalidate(calorieProfileProvider);
  }

  Future<void> markWelcomeCompleted() async {
    ref.read(welcomeFarewellProvider.notifier).show();
    await Hive.box('settings').put(welcomeCompletedKey, true);
    ref.invalidate(welcomeCompletedProvider);
  }

  Future<void> resetWelcome() async {
    ref.read(welcomeFarewellProvider.notifier).hide();
    await Hive.box('settings').delete(welcomeCompletedKey);
    ref.invalidate(welcomeCompletedProvider);
  }

  Future<void> syncMemory(CalorieMemory memory) async {
    final current = ref.read(calorieMemoryProvider);
    if (current.sameAs(memory)) return;

    final box = Hive.box('settings');
    await _putOrDelete(
      box,
      calorieLastAdaptiveTdeeKey,
      memory.lastAdaptiveTdee,
    );
    await _putOrDelete(box, calorieClampedTargetKey, memory.clampedTarget);
    await _putOrDelete(
      box,
      calorieTargetUpdatedAtKey,
      memory.targetUpdatedAt?.millisecondsSinceEpoch,
    );
    await _putOrDelete(box, calorieTargetGoalKey, memory.goalKey);
    ref.invalidate(calorieMemoryProvider);
  }
}

final calorieSettingsProvider = Provider<CalorieSettingsNotifier>((ref) {
  return CalorieSettingsNotifier(ref);
});

List<DayIntake> _intakesByDay(List<FoodEntry> entries) {
  final byDay = <DateTime, DayIntake>{};
  for (final entry in entries) {
    final day = normalizeFoodDay(entry.loggedAt);
    final existing = byDay[day];
    byDay[day] = DayIntake(
      day: day,
      calories: (existing?.calories ?? 0) + (entry.totalCalories ?? 0),
    );
  }
  return byDay.values.toList();
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return null;
}

Future<void> _putOrDelete(Box<dynamic> box, String key, Object? value) async {
  if (value == null) {
    await box.delete(key);
  } else {
    await box.put(key, value);
  }
}
