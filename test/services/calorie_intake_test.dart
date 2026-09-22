import 'package:flutter_test/flutter_test.dart';
import 'package:larger/services/calorie_intake.dart';

void main() {
  test('Mifflin-St Jeor matches the guide formulas', () {
    expect(
      mifflinStJeorBmr(
        sex: BiologicalSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
      ),
      1780,
    );
    expect(
      mifflinStJeorBmr(
        sex: BiologicalSex.female,
        weightKg: 60,
        heightCm: 165,
        ageYears: 25,
      ),
      1345.25,
    );
  });

  test('activity multipliers match the guide table', () {
    expect(ActivityLevel.sedentary.multiplier, 1.2);
    expect(ActivityLevel.lightlyActive.multiplier, 1.375);
    expect(ActivityLevel.moderatelyActive.multiplier, 1.55);
    expect(ActivityLevel.veryActive.multiplier, 1.725);
    expect(ActivityLevel.extraActive.multiplier, 1.9);
  });

  test('body fat uses Katch-McArdle instead of Mifflin', () {
    final tdee = predictiveTdee(
      sex: BiologicalSex.male,
      weightKg: 80,
      heightCm: 180,
      ageYears: 30,
      activity: ActivityLevel.sedentary,
      bodyFatPercent: 20,
    );
    // LBM 64 kg → BMR 1752.4 → × 1.2
    expect(tdee, closeTo(2102.88, 0.001));
  });

  test('cold start target is maintenance, or 500 under it to lose weight', () {
    final asOf = DateTime(2026, 9, 22);
    final maintain = resolveCalorieTarget(
      sex: BiologicalSex.female,
      ageYears: 25,
      heightCm: 165,
      weightKg: 60,
      activity: ActivityLevel.lightlyActive,
      goal: CalorieGoal.maintain,
      weighIns: const [],
      intakes: const [],
      asOf: asOf,
    );
    expect(maintain.maintenanceKcal, 1850);
    expect(maintain.targetKcal, 1850);
    expect(maintain.basis, CalorieBasis.estimated);

    final lose = resolveCalorieTarget(
      sex: BiologicalSex.female,
      ageYears: 25,
      heightCm: 165,
      weightKg: 60,
      activity: ActivityLevel.lightlyActive,
      goal: CalorieGoal.lose,
      weighIns: const [],
      intakes: const [],
      asOf: asOf,
    );
    expect(lose.targetKcal, 1350);
  });

  test(
    'adaptive expenditure uses the 14-day weight trend and intake average',
    () {
      final today = DateTime(2026, 9, 22);
      final result = adaptiveExpenditure(
        weighIns: [
          WeighIn(at: DateTime(2026, 9, 8), kg: 80),
          WeighIn(at: DateTime(2026, 9, 22), kg: 79),
        ],
        intakes: [
          for (var day = 9; day <= 22; day++)
            DayIntake(day: DateTime(2026, 9, day), calories: 2500),
        ],
        asOf: today,
      );

      // Trend on Sep 22 = 0.1*79 + 0.9*80 = 79.9; delta = -0.1 kg.
      // Surplus/day = -0.1 * 7700 / 14. TDEE = 2500 - that surplus.
      expect(result.status, AdaptiveStatus.ready);
      expect(result.kcal, closeTo(2555, 0.001));
    },
  );

  test('more than two missed food logs in a week pauses the update', () {
    final today = DateTime(2026, 9, 22);
    final paused = adaptiveExpenditure(
      weighIns: [WeighIn(at: DateTime(2026, 9, 1), kg: 80)],
      intakes: [
        for (final day in [19, 20, 21, 22])
          DayIntake(day: DateTime(2026, 9, day), calories: 2000),
      ],
      asOf: today,
    );
    expect(paused.status, AdaptiveStatus.paused);

    final ready = adaptiveExpenditure(
      weighIns: [WeighIn(at: DateTime(2026, 9, 1), kg: 80)],
      intakes: [
        for (final day in [18, 19, 20, 21, 22])
          DayIntake(day: DateTime(2026, 9, day), calories: 2000),
      ],
      asOf: today,
    );
    expect(ready.status, AdaptiveStatus.ready);
    expect(ready.kcal, 2000);
  });

  test('14 calendar days still resolve across a daylight-saving change', () {
    final today = DateTime(2026, 3, 15);
    final result = adaptiveExpenditure(
      weighIns: [WeighIn(at: DateTime(2026, 3, 1), kg: 80)],
      intakes: [
        for (
          var day = DateTime(2026, 3, 2);
          !day.isAfter(today);
          day = DateTime(day.year, day.month, day.day + 1)
        )
          DayIntake(day: day, calories: 2000),
      ],
      asOf: today,
    );
    expect(result.status, AdaptiveStatus.ready);
    expect(result.kcal, 2000);
  });

  test('short weight history stays on the estimate', () {
    final result = adaptiveExpenditure(
      weighIns: [WeighIn(at: DateTime(2026, 9, 20), kg: 80)],
      intakes: [
        for (var day = 9; day <= 22; day++)
          DayIntake(day: DateTime(2026, 9, day), calories: 2000),
      ],
      asOf: DateTime(2026, 9, 22),
    );
    expect(result.status, AdaptiveStatus.notEnoughData);
  });

  test('weekly step moves the target by at most 150 kcal', () {
    final asOf = DateTime(2026, 9, 22);
    final first = _resolveAdaptive(memory: CalorieMemory.empty, asOf: asOf);
    // Flat 80 kg and 2,500 kcal/day → expenditure 2,500, lose-weight target 2,000.
    // The estimate for this profile is 2,259, so the first week only moves 150.
    expect(first.basis, CalorieBasis.adaptive);
    expect(first.targetKcal, 2109);

    final held = _resolveAdaptive(
      memory: first.memory,
      asOf: asOf.add(const Duration(days: 3)),
    );
    expect(held.targetKcal, 2109);

    final nextWeek = _resolveAdaptive(
      memory: first.memory,
      asOf: asOf.add(const Duration(days: 7)),
    );
    expect(nextWeek.targetKcal, 2000);
  });

  test('a goal change applies immediately', () {
    final asOf = DateTime(2026, 9, 22);
    final switched = resolveCalorieTarget(
      sex: BiologicalSex.male,
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      activity: ActivityLevel.moderatelyActive,
      goal: CalorieGoal.lose,
      weighIns: const [],
      intakes: const [],
      memory: CalorieMemory(
        lastAdaptiveTdee: 2500,
        clampedTarget: 2500,
        targetUpdatedAt: asOf.subtract(const Duration(days: 1)),
        goalKey: CalorieGoal.maintain.name,
      ),
      asOf: asOf,
    );
    expect(switched.targetKcal, 2000);
    expect(switched.maintenanceKcal, 2500);
  });

  test('missed logs keep the current target', () {
    final asOf = DateTime(2026, 9, 22);
    final held = resolveCalorieTarget(
      sex: BiologicalSex.male,
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      activity: ActivityLevel.moderatelyActive,
      goal: CalorieGoal.maintain,
      weighIns: [WeighIn(at: DateTime(2026, 9, 1), kg: 80)],
      intakes: [
        for (final day in [19, 20, 21, 22])
          DayIntake(day: DateTime(2026, 9, day), calories: 2000),
      ],
      memory: CalorieMemory(
        lastAdaptiveTdee: 2800,
        clampedTarget: 2800,
        targetUpdatedAt: DateTime(2026, 9, 20),
        goalKey: CalorieGoal.maintain.name,
      ),
      asOf: asOf,
    );
    expect(held.basis, CalorieBasis.held);
    expect(held.targetKcal, 2800);
  });

  test('macro percents are shares of calories and sum to 100', () {
    final share = macroCalorieShare(proteinG: 10, carbsG: 10, fatG: 10);
    expect(share, isNotNull);
    expect(share!.proteinPercent + share.carbsPercent + share.fatPercent, 100);
    expect(share.fatPercent, greaterThan(share.proteinPercent));

    expect(macroCalorieShare(proteinG: 0, carbsG: 0, fatG: 0), isNull);
  });

  test('percent of target uses rounded calories', () {
    expect(percentOfTarget(amount: 1240, target: 2200), 56);
    expect(percentOfTarget(amount: 10, target: 0), 0);
  });
}

CalorieResolution _resolveAdaptive({
  required CalorieMemory memory,
  required DateTime asOf,
}) {
  final start = DateTime(2026, 9, 1);
  return resolveCalorieTarget(
    sex: BiologicalSex.male,
    ageYears: 30,
    heightCm: 180,
    weightKg: 80,
    activity: ActivityLevel.moderatelyActive,
    goal: CalorieGoal.lose,
    weighIns: [WeighIn(at: start, kg: 80)],
    intakes: [
      for (
        var day = start;
        !day.isAfter(asOf);
        day = day.add(const Duration(days: 1))
      )
        DayIntake(day: day, calories: 2500),
    ],
    memory: memory,
    asOf: asOf,
  );
}
