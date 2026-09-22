/// Daily calorie target from the vault note
/// "Precision Caloric Intake & Adaptive TDEE Guide".
///
/// Cold start uses Mifflin–St Jeor, or Katch–McArdle when body fat is set,
/// times the activity multiplier. After 14 days of weight and intake, expenditure
/// is back-calculated from the weight trend. The eaten target is that
/// expenditure, minus 500 kcal when the goal is to lose weight.
library;

/// Smoother end of the guide's 0.1–0.2 weight-trend range.
const weightTrendAlpha = 0.1;

const adaptiveWindowDays = 14;

/// Metric constant from the guide: 1 kg of tissue ≈ 7,700 kcal.
const kcalPerKgTissue = 7700.0;

/// Top of the guide's ±100–150 kcal weekly limit.
const maxWeeklyTargetChangeKcal = 150.0;

/// The guide's weight-loss example: maintenance minus 500 kcal.
const weightLossDeficitKcal = 500.0;

enum BiologicalSex {
  male('Men'),
  female('Women');

  const BiologicalSex(this.label);
  final String label;

  static BiologicalSex? parse(String? raw) {
    for (final sex in BiologicalSex.values) {
      if (sex.name == raw) return sex;
    }
    return null;
  }
}

enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Desk job, minimal walking'),
  lightlyActive(1.375, 'Lightly active', '1–3 light workouts/week'),
  moderatelyActive(1.55, 'Moderately active', '3–5 moderate workouts/week'),
  veryActive(1.725, 'Very active', '6–7 intense workouts/week'),
  extraActive(1.9, 'Extra active', 'Heavy manual labor + daily training');

  const ActivityLevel(this.multiplier, this.label, this.description);

  final double multiplier;
  final String label;
  final String description;

  static ActivityLevel? parse(String? raw) {
    for (final level in ActivityLevel.values) {
      if (level.name == raw) return level;
    }
    return null;
  }
}

enum CalorieGoal {
  lose('Lose weight', '500 kcal under maintenance'),
  maintain('Maintain', 'Match maintenance');

  const CalorieGoal(this.label, this.description);

  final String label;
  final String description;

  double get delta => this == CalorieGoal.lose ? -weightLossDeficitKcal : 0;

  static CalorieGoal? parse(String? raw) {
    for (final goal in CalorieGoal.values) {
      if (goal.name == raw) return goal;
    }
    return null;
  }
}

enum CalorieBasis { estimated, adaptive, held }

enum AdaptiveStatus { ready, paused, notEnoughData }

class WeighIn {
  const WeighIn({required this.at, required this.kg});

  final DateTime at;
  final double kg;
}

class DayIntake {
  const DayIntake({
    required this.day,
    required this.calories,
    this.logged = true,
  });

  final DateTime day;
  final double calories;
  final bool logged;
}

class CalorieMemory {
  const CalorieMemory({
    this.lastAdaptiveTdee,
    this.clampedTarget,
    this.targetUpdatedAt,
    this.goalKey,
  });

  static const empty = CalorieMemory();

  final double? lastAdaptiveTdee;
  final double? clampedTarget;
  final DateTime? targetUpdatedAt;
  final String? goalKey;

  bool sameAs(CalorieMemory other) {
    return lastAdaptiveTdee == other.lastAdaptiveTdee &&
        clampedTarget == other.clampedTarget &&
        goalKey == other.goalKey &&
        targetUpdatedAt?.millisecondsSinceEpoch ==
            other.targetUpdatedAt?.millisecondsSinceEpoch;
  }
}

class CalorieResolution {
  const CalorieResolution({
    required this.targetKcal,
    required this.maintenanceKcal,
    required this.basis,
    required this.memory,
  });

  final double targetKcal;
  final double maintenanceKcal;
  final CalorieBasis basis;
  final CalorieMemory memory;
}

class AdaptiveTdee {
  const AdaptiveTdee({required this.status, this.kcal});

  final AdaptiveStatus status;
  final double? kcal;
}

class MacroCalorieShare {
  const MacroCalorieShare({
    required this.proteinPercent,
    required this.carbsPercent,
    required this.fatPercent,
  });

  final int proteinPercent;
  final int carbsPercent;
  final int fatPercent;
}

double mifflinStJeorBmr({
  required BiologicalSex sex,
  required double weightKg,
  required double heightCm,
  required int ageYears,
}) {
  final base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
  return sex == BiologicalSex.male ? base + 5 : base - 161;
}

double katchMcArdleBmr({
  required double weightKg,
  required double bodyFatPercent,
}) {
  final leanKg = weightKg * (1 - bodyFatPercent / 100);
  return 370 + (21.6 * leanKg);
}

double predictiveTdee({
  required BiologicalSex sex,
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required ActivityLevel activity,
  double? bodyFatPercent,
}) {
  final bmr = bodyFatPercent == null
      ? mifflinStJeorBmr(
          sex: sex,
          weightKg: weightKg,
          heightCm: heightCm,
          ageYears: ageYears,
        )
      : katchMcArdleBmr(weightKg: weightKg, bodyFatPercent: bodyFatPercent);
  return bmr * activity.multiplier;
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

/// Calendar days, not 24-hour steps, so a DST change does not skip a date.
DateTime _shiftDays(DateTime value, int days) {
  final day = _day(value);
  return DateTime(day.year, day.month, day.day + days);
}

/// Back-calculates expenditure over the last 14 days.
///
/// Weight change is the smoothed trend today minus the trend 14 days earlier.
/// Intake is the average of days that were actually logged in that span
/// (today and the 13 days before it). More than 2 missed food logs in the
/// last 7 days pauses the update.
AdaptiveTdee adaptiveExpenditure({
  required List<WeighIn> weighIns,
  required List<DayIntake> intakes,
  required DateTime asOf,
}) {
  final today = _day(asOf);
  final trendStart = _shiftDays(today, -adaptiveWindowDays);

  final weightByDay = <DateTime, WeighIn>{};
  for (final sample in weighIns) {
    if (sample.at.isAfter(asOf)) continue;
    final day = _day(sample.at);
    final existing = weightByDay[day];
    if (existing == null || sample.at.isAfter(existing.at)) {
      weightByDay[day] = sample;
    }
  }
  if (weightByDay.isEmpty) {
    return const AdaptiveTdee(status: AdaptiveStatus.notEnoughData);
  }

  final firstDay = weightByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  if (firstDay.isAfter(trendStart)) {
    return const AdaptiveTdee(status: AdaptiveStatus.notEnoughData);
  }

  final intakeByDay = <DateTime, DayIntake>{};
  for (final intake in intakes) {
    final day = _day(intake.day);
    if (day.isAfter(today)) continue;
    intakeByDay[day] = intake;
  }

  var missedThisWeek = 0;
  for (var i = 0; i < 7; i++) {
    final day = _shiftDays(today, -i);
    final intake = intakeByDay[day];
    if (intake == null || !intake.logged) missedThisWeek++;
  }
  if (missedThisWeek > 2) {
    return const AdaptiveTdee(status: AdaptiveStatus.paused);
  }

  double? trend;
  double? trendAtStart;
  var cursor = firstDay;
  while (!cursor.isAfter(today)) {
    final sample = weightByDay[cursor];
    if (sample != null) {
      trend = trend == null
          ? sample.kg
          : (weightTrendAlpha * sample.kg) + ((1 - weightTrendAlpha) * trend);
    }
    if (cursor == trendStart) trendAtStart = trend;
    cursor = _shiftDays(cursor, 1);
  }
  if (trend == null || trendAtStart == null) {
    return const AdaptiveTdee(status: AdaptiveStatus.notEnoughData);
  }

  final windowStart = _shiftDays(today, -(adaptiveWindowDays - 1));
  final loggedCalories = <double>[];
  for (var i = 0; i < adaptiveWindowDays; i++) {
    final day = _shiftDays(windowStart, i);
    final intake = intakeByDay[day];
    if (intake != null && intake.logged) loggedCalories.add(intake.calories);
  }
  if (loggedCalories.isEmpty) {
    return const AdaptiveTdee(status: AdaptiveStatus.notEnoughData);
  }

  final averageIntake =
      loggedCalories.reduce((a, b) => a + b) / loggedCalories.length;
  final deltaKg = trend - trendAtStart;
  final surplusPerDay = (deltaKg * kcalPerKgTissue) / adaptiveWindowDays;
  return AdaptiveTdee(
    status: AdaptiveStatus.ready,
    kcal: averageIntake - surplusPerDay,
  );
}

double _stepToward(double from, double to) {
  final delta = (to - from).clamp(
    -maxWeeklyTargetChangeKcal,
    maxWeeklyTargetChangeKcal,
  );
  return (from + delta).roundToDouble();
}

CalorieResolution resolveCalorieTarget({
  required BiologicalSex sex,
  required int ageYears,
  required double heightCm,
  required double weightKg,
  required ActivityLevel activity,
  double? bodyFatPercent,
  required CalorieGoal goal,
  required List<WeighIn> weighIns,
  required List<DayIntake> intakes,
  CalorieMemory memory = CalorieMemory.empty,
  required DateTime asOf,
}) {
  final maintenanceEstimate = predictiveTdee(
    sex: sex,
    weightKg: weightKg,
    heightCm: heightCm,
    ageYears: ageYears,
    activity: activity,
    bodyFatPercent: bodyFatPercent,
  ).roundToDouble();
  final estimatedTarget = (maintenanceEstimate + goal.delta).roundToDouble();
  final goalChanged = memory.goalKey != null && memory.goalKey != goal.name;

  if (goalChanged && memory.clampedTarget != null) {
    final maintenance = (memory.lastAdaptiveTdee ?? maintenanceEstimate)
        .roundToDouble();
    final target = (maintenance + goal.delta).roundToDouble();
    return CalorieResolution(
      targetKcal: target,
      maintenanceKcal: maintenance,
      basis: memory.lastAdaptiveTdee == null
          ? CalorieBasis.estimated
          : CalorieBasis.adaptive,
      memory: CalorieMemory(
        lastAdaptiveTdee: memory.lastAdaptiveTdee,
        clampedTarget: target,
        targetUpdatedAt: asOf,
        goalKey: goal.name,
      ),
    );
  }

  final adaptive = adaptiveExpenditure(
    weighIns: weighIns,
    intakes: intakes,
    asOf: asOf,
  );

  if (adaptive.status == AdaptiveStatus.paused &&
      memory.clampedTarget != null) {
    return CalorieResolution(
      targetKcal: memory.clampedTarget!,
      maintenanceKcal: (memory.lastAdaptiveTdee ?? maintenanceEstimate)
          .roundToDouble(),
      basis: CalorieBasis.held,
      memory: memory,
    );
  }

  if (adaptive.status == AdaptiveStatus.ready && adaptive.kcal != null) {
    final maintenance = adaptive.kcal!.roundToDouble();
    final rawTarget = (maintenance + goal.delta).roundToDouble();

    if (memory.clampedTarget == null || memory.targetUpdatedAt == null) {
      final target = _stepToward(estimatedTarget, rawTarget);
      return CalorieResolution(
        targetKcal: target,
        maintenanceKcal: maintenance,
        basis: CalorieBasis.adaptive,
        memory: CalorieMemory(
          lastAdaptiveTdee: maintenance,
          clampedTarget: target,
          targetUpdatedAt: asOf,
          goalKey: goal.name,
        ),
      );
    }

    final nextUpdate = _shiftDays(memory.targetUpdatedAt!, 7);
    if (_day(asOf).isBefore(nextUpdate)) {
      return CalorieResolution(
        targetKcal: memory.clampedTarget!,
        maintenanceKcal: (memory.lastAdaptiveTdee ?? maintenance)
            .roundToDouble(),
        basis: CalorieBasis.adaptive,
        memory: memory,
      );
    }

    final target = _stepToward(memory.clampedTarget!, rawTarget);
    return CalorieResolution(
      targetKcal: target,
      maintenanceKcal: maintenance,
      basis: CalorieBasis.adaptive,
      memory: CalorieMemory(
        lastAdaptiveTdee: maintenance,
        clampedTarget: target,
        targetUpdatedAt: asOf,
        goalKey: goal.name,
      ),
    );
  }

  return CalorieResolution(
    targetKcal: estimatedTarget,
    maintenanceKcal: maintenanceEstimate,
    basis: CalorieBasis.estimated,
    memory: memory,
  );
}

/// Protein and carbs are 4 kcal/g, fat is 9 kcal/g.
/// Percents are each macro's share of those calories and sum to 100.
MacroCalorieShare? macroCalorieShare({
  required double proteinG,
  required double carbsG,
  required double fatG,
}) {
  final raw = [proteinG * 4, carbsG * 4, fatG * 9];
  final total = raw.fold<double>(0, (sum, value) => sum + value);
  if (total <= 0) return null;

  final exact = raw.map((value) => value / total * 100).toList();
  final floors = exact.map((value) => value.floor()).toList();
  var leftover = 100 - floors.fold<int>(0, (sum, value) => sum + value);
  final order = [0, 1, 2]
    ..sort((a, b) {
      final remainder = (exact[b] - floors[b]).compareTo(exact[a] - floors[a]);
      if (remainder != 0) return remainder;
      return a.compareTo(b);
    });
  for (var i = 0; i < leftover; i++) {
    floors[order[i]]++;
  }

  return MacroCalorieShare(
    proteinPercent: floors[0],
    carbsPercent: floors[1],
    fatPercent: floors[2],
  );
}

int percentOfTarget({required double amount, required double target}) {
  final whole = target.round();
  if (whole <= 0) return 0;
  return ((amount.round() / whole) * 100).round();
}

/// Starting protein goal: 30% of the calorie target, at 4 kcal per gram.
int defaultProteinGoalG(double targetKcal) {
  if (targetKcal <= 0) return 0;
  return (targetKcal * 0.30 / 4).round();
}

/// Starting carb goal: 45% of the calorie target, at 4 kcal per gram.
int defaultCarbGoalG(double targetKcal) {
  if (targetKcal <= 0) return 0;
  return (targetKcal * 0.45 / 4).round();
}

int resolvedGramGoal({required int? stored, required int fallback}) {
  if (stored != null && stored > 0) return stored;
  return fallback;
}
