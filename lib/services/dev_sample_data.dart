import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/services/calorie_intake.dart';

/// Debug sample-data personas for verifying Today suggestions.
enum SampleDataTier {
  beginner,
  intermediate,
  expert;

  static const settingsKey = 'sampleDataTier';

  String get storageValue => name;

  static SampleDataTier fromStorage(String? value) {
    return SampleDataTier.values.firstWhere(
      (t) => t.name == value,
      orElse: () => SampleDataTier.intermediate,
    );
  }

  String get label => switch (this) {
    SampleDataTier.beginner => 'Beginner',
    SampleDataTier.intermediate => 'Intermediate',
    SampleDataTier.expert => 'Expert',
  };
}

SampleDataTier readSampleDataTier() {
  final settings = Hive.box('settings');
  return SampleDataTier.fromStorage(
    settings.get(SampleDataTier.settingsKey) as String?,
  );
}

/// Debug builds, or a release built with `--dart-define=DEV_SETTINGS=true`.
bool get devSettingsEnabled =>
    kDebugMode || const bool.fromEnvironment('DEV_SETTINGS');

/// Seeds once on fresh debug installs (default: intermediate).
Future<void> seedDevSampleDataIfNeeded() async {
  if (!devSettingsEnabled) return;

  final settings = Hive.box('settings');
  if (settings.containsKey(SampleDataTier.settingsKey)) return;

  final sessionsEmpty = Hive.box<WorkoutSession>('sessions').isEmpty;
  final routinesEmpty = Hive.box<Routine>('routines').isEmpty;
  if (!sessionsEmpty || !routinesEmpty) {
    // Existing local data without a tier marker — don't wipe it.
    await settings.put(
      SampleDataTier.settingsKey,
      SampleDataTier.intermediate.storageValue,
    );
    return;
  }

  await seedDevSampleData(tier: SampleDataTier.intermediate);
}

/// Deterministic clear+seed path used by the Profile developer section.
Future<void> seedDevSampleData({required SampleDataTier tier}) async {
  if (!devSettingsEnabled) return;

  final exerciseBox = Hive.box<Exercise>('exercises');
  Exercise? byName(String name) {
    for (final ex in exerciseBox.values) {
      if (ex.name.toLowerCase() == name.toLowerCase()) return ex;
    }
    return null;
  }

  WorkoutExercise workoutExercise(
    Exercise exercise, {
    required List<(int reps, double weight)> sets,
  }) {
    return WorkoutExercise()
      ..exerciseId = exercise.id
      ..exerciseName = exercise.name
      ..sets = sets
          .map(
            (s) => WorkoutSet()
              ..reps = s.$1
              ..weight = s.$2
              ..isCompleted = true,
          )
          .toList();
  }

  double volumeOf(List<(int reps, double weight)> sets) {
    return sets.fold<double>(0, (sum, s) => sum + s.$1 * s.$2);
  }

  final sessionsBox = Hive.box<WorkoutSession>('sessions');
  final routinesBox = Hive.box<Routine>('routines');
  final weightBox = Hive.box<BodyWeightLog>('bodyWeightLogs');
  final foodBox = Hive.box<FoodEntry>('foodEntries');
  final settings = Hive.box('settings');
  final now = DateTime.now();

  await sessionsBox.clear();
  await routinesBox.clear();
  await weightBox.clear();
  await foodBox.clear();
  await settings.delete('height');
  for (final key in calorieSettingKeys) {
    await settings.delete(key);
  }

  await settings.put(SampleDataTier.settingsKey, tier.storageValue);

  if (tier == SampleDataTier.beginner) {
    // Catalog only — no routines, sessions, or body stats.
    return;
  }

  Future<void> putWeights() async {
    for (final entry in [(21, 82.0), (14, 81.4), (7, 81.0), (1, 80.6)]) {
      final log = BodyWeightLog(
        weight: entry.$2,
        date: now.subtract(Duration(days: entry.$1)),
      );
      await weightBox.put(log.id, log);
    }
    await settings.put('height', 178.0);
  }

  Future<void> putFood() async {
    DateTime at(int daysAgo, int hour) {
      final day = DateTime(now.year, now.month, now.day - daysAgo, hour);
      return day;
    }

    final entries = [
      FoodEntry(
        name: 'Oats',
        meal: 'breakfast',
        loggedAt: at(0, 8),
        servingLabel: '80 g',
        calories: 300,
        proteinG: 10,
        carbsG: 54,
        fatG: 6,
      ),
      FoodEntry(
        name: 'Eggs',
        meal: 'breakfast',
        loggedAt: at(0, 8),
        servingLabel: '1 egg',
        servings: 2,
        calories: 70,
        proteinG: 6,
        carbsG: 0,
        fatG: 5,
      ),
      FoodEntry(
        name: 'Chicken breast',
        meal: 'lunch',
        loggedAt: at(0, 13),
        servingLabel: '150 g',
        calories: 250,
        proteinG: 46,
        carbsG: 0,
        fatG: 5,
      ),
      FoodEntry(
        name: 'Rice',
        meal: 'lunch',
        loggedAt: at(0, 13),
        servingLabel: '200 g cooked',
        calories: 260,
        proteinG: 5,
        carbsG: 56,
        fatG: 1,
      ),
      FoodEntry(
        name: 'Greek yogurt',
        meal: 'snack',
        loggedAt: at(0, 16),
        servingLabel: '170 g',
        calories: 100,
        proteinG: 17,
        carbsG: 6,
        fatG: 0,
      ),
      FoodEntry(
        name: 'Salmon',
        meal: 'dinner',
        loggedAt: at(0, 19),
        servingLabel: '180 g',
        calories: 370,
        proteinG: 40,
        carbsG: 0,
        fatG: 22,
      ),
      FoodEntry(
        name: 'Potatoes',
        meal: 'dinner',
        loggedAt: at(0, 19),
        servingLabel: '250 g',
        calories: 215,
        proteinG: 5,
        carbsG: 47,
        fatG: 0,
      ),
      FoodEntry(
        name: 'Turkey sandwich',
        meal: 'lunch',
        loggedAt: at(1, 13),
        servingLabel: '1 sandwich',
        calories: 450,
        proteinG: 32,
        carbsG: 42,
        fatG: 14,
      ),
      FoodEntry(
        name: 'Pasta',
        meal: 'dinner',
        loggedAt: at(1, 19),
        servingLabel: '1 plate',
        calories: 620,
        proteinG: 28,
        carbsG: 80,
        fatG: 18,
      ),
      FoodEntry(
        name: 'Yogurt and berries',
        meal: 'breakfast',
        loggedAt: at(2, 8),
        servingLabel: '1 bowl',
        calories: 220,
        proteinG: 18,
        carbsG: 24,
        fatG: 4,
      ),
      FoodEntry(
        name: 'Protein bar',
        meal: 'snack',
        loggedAt: at(2, 16),
        servingLabel: '1 bar',
        calories: 200,
        proteinG: 20,
        carbsG: 22,
        fatG: 7,
      ),
    ];

    for (final entry in entries) {
      await foodBox.put(entry.id, entry);
    }

    await settings.put(calorieSexKey, BiologicalSex.male.name);
    await settings.put(calorieAgeKey, 30);
    await settings.put(calorieActivityKey, ActivityLevel.moderatelyActive.name);
    await settings.put(calorieGoalKey, CalorieGoal.maintain.name);
  }

  if (tier == SampleDataTier.intermediate) {
    final bench = byName('Bench Press');
    final ohp = byName('Overhead Press');
    final row = byName('Barbell Row');
    if (bench == null || ohp == null || row == null) return;

    final routine = Routine(
      name: 'Full Body A',
      exercises: [
        RoutineExercise(exerciseId: bench.id, targetSets: 3),
        RoutineExercise(exerciseId: ohp.id, targetSets: 3),
        RoutineExercise(exerciseId: row.id, targetSets: 3),
      ],
    );
    await routinesBox.put(routine.id, routine);

    final sets1 = <(int, double)>[(8, 60), (8, 60), (6, 65)];
    final sets2 = <(int, double)>[(8, 40), (8, 40), (6, 42.5)];
    final sets3 = <(int, double)>[(8, 50), (8, 50), (6, 55)];

    // Gap >= 2 days for skippedDays; single routine → nextRoutine for Full Body A.
    final sessions = [
      WorkoutSession()
        ..routineName = routine.name
        ..startTime = now.subtract(const Duration(days: 10))
        ..endTime = now.subtract(const Duration(days: 10, hours: -1))
        ..isCompleted = true
        ..exercises = [
          workoutExercise(bench, sets: sets1),
          workoutExercise(ohp, sets: sets2),
          workoutExercise(row, sets: sets3),
        ]
        ..totalVolume = volumeOf(sets1) + volumeOf(sets2) + volumeOf(sets3),
      WorkoutSession()
        ..routineName = routine.name
        ..startTime = now.subtract(const Duration(days: 3))
        ..endTime = now.subtract(const Duration(days: 3, hours: -1))
        ..isCompleted = true
        ..exercises = [
          workoutExercise(bench, sets: [(8, 62.5), (6, 67.5), (5, 70)]),
          workoutExercise(ohp, sets: [(8, 42.5), (6, 45), (5, 47.5)]),
          workoutExercise(row, sets: [(8, 52.5), (6, 55), (5, 57.5)]),
        ]
        ..totalVolume =
            62.5 * 8 +
            67.5 * 6 +
            70 * 5 +
            42.5 * 8 +
            45 * 6 +
            47.5 * 5 +
            52.5 * 8 +
            55 * 6 +
            57.5 * 5,
    ];

    for (final session in sessions) {
      await sessionsBox.put(session.id, session);
    }
    await putWeights();
    await putFood();
    return;
  }

  // Expert: Push / Pull / Legs / Upper with 26+ distinct exercises.
  final bench = byName('Bench Press');
  final incline = byName('Incline Bench Press');
  final dbBench = byName('Dumbbell Bench Press');
  final dips = byName('Dips');
  final ohp = byName('Overhead Press');
  final dbShoulder = byName('Dumbbell Shoulder Press');
  final lateral = byName('Lateral Raise');
  final cableLateral = byName('Cable Lateral Raise');
  final triceps = byName('Tricep Pushdown');
  final skulls = byName('Skullcrushers');
  final overheadTri = byName('Overhead Tricep Extension');
  final deadlift = byName('Deadlift');
  final pullUp = byName('Pull Up');
  final row = byName('Barbell Row');
  final pulldown = byName('Lat Pulldown');
  final cableRow = byName('Seated Cable Row');
  final facePull = byName('Face Pull');
  final curl = byName('Barbell Curl');
  final hammer = byName('Hammer Curl');
  final preacher = byName('Preacher Curl');
  final squat = byName('Squat');
  final frontSquat = byName('Front Squat');
  final legPress = byName('Leg Press');
  final rdl = byName('Romanian Deadlift');
  final legCurl = byName('Leg Curl');
  final legExt = byName('Leg Extension');
  final calf = byName('Standing Calf Raise');
  final seatedCalf = byName('Seated Calf Raise');
  final crunch = byName('Crunch');
  final plank = byName('Plank');

  final lifts = [
    bench,
    incline,
    dbBench,
    dips,
    ohp,
    dbShoulder,
    lateral,
    cableLateral,
    triceps,
    skulls,
    overheadTri,
    deadlift,
    pullUp,
    row,
    pulldown,
    cableRow,
    facePull,
    curl,
    hammer,
    preacher,
    squat,
    frontSquat,
    legPress,
    rdl,
    legCurl,
    legExt,
    calf,
    seatedCalf,
    crunch,
    plank,
  ];
  if (lifts.any((e) => e == null)) return;

  final push = Routine(
    name: 'Push',
    exercises: [
      RoutineExercise(exerciseId: bench!.id, targetSets: 3),
      RoutineExercise(exerciseId: incline!.id, targetSets: 3),
      RoutineExercise(exerciseId: dbBench!.id, targetSets: 3),
      RoutineExercise(exerciseId: dips!.id, targetSets: 3),
      RoutineExercise(exerciseId: ohp!.id, targetSets: 3),
      RoutineExercise(exerciseId: lateral!.id, targetSets: 3),
      RoutineExercise(exerciseId: cableLateral!.id, targetSets: 3),
      RoutineExercise(exerciseId: triceps!.id, targetSets: 3),
      RoutineExercise(exerciseId: skulls!.id, targetSets: 3),
    ],
  );
  final pull = Routine(
    name: 'Pull',
    exercises: [
      RoutineExercise(exerciseId: deadlift!.id, targetSets: 3),
      RoutineExercise(exerciseId: pullUp!.id, targetSets: 3),
      RoutineExercise(exerciseId: row!.id, targetSets: 3),
      RoutineExercise(exerciseId: pulldown!.id, targetSets: 3),
      RoutineExercise(exerciseId: cableRow!.id, targetSets: 3),
      RoutineExercise(exerciseId: facePull!.id, targetSets: 3),
      RoutineExercise(exerciseId: curl!.id, targetSets: 3),
      RoutineExercise(exerciseId: hammer!.id, targetSets: 3),
      RoutineExercise(exerciseId: preacher!.id, targetSets: 3),
    ],
  );
  final legs = Routine(
    name: 'Legs',
    exercises: [
      RoutineExercise(exerciseId: squat!.id, targetSets: 3),
      RoutineExercise(exerciseId: frontSquat!.id, targetSets: 3),
      RoutineExercise(exerciseId: legPress!.id, targetSets: 3),
      RoutineExercise(exerciseId: rdl!.id, targetSets: 3),
      RoutineExercise(exerciseId: legCurl!.id, targetSets: 3),
      RoutineExercise(exerciseId: legExt!.id, targetSets: 3),
      RoutineExercise(exerciseId: calf!.id, targetSets: 3),
      RoutineExercise(exerciseId: seatedCalf!.id, targetSets: 3),
    ],
  );
  final upper = Routine(
    name: 'Upper',
    exercises: [
      RoutineExercise(exerciseId: bench.id, targetSets: 3),
      RoutineExercise(exerciseId: row.id, targetSets: 3),
      RoutineExercise(exerciseId: dbShoulder!.id, targetSets: 3),
      RoutineExercise(exerciseId: overheadTri!.id, targetSets: 3),
      RoutineExercise(exerciseId: hammer.id, targetSets: 3),
      RoutineExercise(exerciseId: crunch!.id, targetSets: 3),
      RoutineExercise(exerciseId: plank!.id, targetSets: 3),
    ],
  );

  await routinesBox.put(push.id, push);
  await routinesBox.put(pull.id, pull);
  await routinesBox.put(legs.id, legs);
  await routinesBox.put(upper.id, upper);

  // Stagger so Legs is clearly least recently used (due).
  final expertSessions = [
    WorkoutSession()
      ..routineName = push.name
      ..startTime = now.subtract(const Duration(days: 2))
      ..endTime = now.subtract(const Duration(days: 2, hours: -1))
      ..isCompleted = true
      ..exercises = [
        workoutExercise(bench, sets: [(5, 80), (5, 82.5), (3, 85)]),
        workoutExercise(incline, sets: [(8, 55), (8, 55), (6, 60)]),
        workoutExercise(ohp, sets: [(8, 45), (6, 47.5), (5, 50)]),
        workoutExercise(lateral, sets: [(12, 10), (12, 10), (10, 12)]),
        workoutExercise(triceps, sets: [(12, 25), (10, 27.5), (10, 27.5)]),
      ]
      ..totalVolume =
          80 * 5 +
          82.5 * 5 +
          85 * 3 +
          55 * 8 * 2 +
          60 * 6 +
          45 * 8 +
          47.5 * 6 +
          50 * 5 +
          10 * 12 * 2 +
          12 * 10 +
          25 * 12 +
          27.5 * 10 * 2,
    WorkoutSession()
      ..routineName = pull.name
      ..startTime = now.subtract(const Duration(days: 4))
      ..endTime = now.subtract(const Duration(days: 4, hours: -1))
      ..isCompleted = true
      ..exercises = [
        workoutExercise(deadlift, sets: [(5, 140), (5, 140), (3, 150)]),
        workoutExercise(row, sets: [(8, 60), (8, 60), (6, 65)]),
        workoutExercise(pulldown, sets: [(10, 50), (10, 50), (8, 55)]),
        workoutExercise(facePull, sets: [(15, 20), (15, 20), (12, 22.5)]),
        workoutExercise(curl, sets: [(10, 30), (8, 32.5), (8, 32.5)]),
      ]
      ..totalVolume =
          140 * 5 * 2 +
          150 * 3 +
          60 * 8 * 2 +
          65 * 6 +
          50 * 10 * 2 +
          55 * 8 +
          20 * 15 * 2 +
          22.5 * 12 +
          30 * 10 +
          32.5 * 8 * 2,
    WorkoutSession()
      ..routineName = upper.name
      ..startTime = now.subtract(const Duration(days: 5))
      ..endTime = now.subtract(const Duration(days: 5, hours: -1))
      ..isCompleted = true
      ..exercises = [
        workoutExercise(bench, sets: [(8, 70), (6, 75), (5, 77.5)]),
        workoutExercise(row, sets: [(8, 55), (8, 55), (6, 60)]),
        workoutExercise(dbShoulder, sets: [(10, 22.5), (8, 25), (8, 25)]),
        workoutExercise(hammer, sets: [(10, 16), (10, 16), (8, 18)]),
      ]
      ..totalVolume =
          70 * 8 +
          75 * 6 +
          77.5 * 5 +
          55 * 8 * 2 +
          60 * 6 +
          22.5 * 10 +
          25 * 8 * 2 +
          16 * 10 * 2 +
          18 * 8,
    WorkoutSession()
      ..routineName = legs.name
      ..startTime = now.subtract(const Duration(days: 9))
      ..endTime = now.subtract(const Duration(days: 9, hours: -1))
      ..isCompleted = true
      ..exercises = [
        workoutExercise(squat, sets: [(5, 100), (5, 105), (5, 110)]),
        workoutExercise(rdl, sets: [(8, 80), (8, 80), (6, 85)]),
        workoutExercise(legPress, sets: [(10, 160), (10, 160), (8, 180)]),
        workoutExercise(legCurl, sets: [(12, 40), (10, 42.5), (10, 42.5)]),
        workoutExercise(calf, sets: [(12, 60), (12, 60), (10, 70)]),
      ]
      ..totalVolume =
          100 * 5 +
          105 * 5 +
          110 * 5 +
          80 * 8 * 2 +
          85 * 6 +
          160 * 10 * 2 +
          180 * 8 +
          40 * 12 +
          42.5 * 10 * 2 +
          60 * 12 * 2 +
          70 * 10,
    WorkoutSession()
      ..routineName = push.name
      ..startTime = now.subtract(const Duration(days: 8))
      ..endTime = now.subtract(const Duration(days: 8, hours: -1))
      ..isCompleted = true
      ..exercises = [
        workoutExercise(bench, sets: [(8, 70), (6, 75), (5, 77.5)]),
        workoutExercise(incline, sets: [(8, 50), (8, 50), (6, 55)]),
        workoutExercise(dips, sets: [(8, 0), (8, 0), (6, 5)]),
        workoutExercise(skulls, sets: [(10, 30), (10, 30), (8, 32.5)]),
      ]
      ..totalVolume =
          70 * 8 +
          75 * 6 +
          77.5 * 5 +
          50 * 8 * 2 +
          55 * 6 +
          0 * 8 * 2 +
          5 * 6 +
          30 * 10 * 2 +
          32.5 * 8,
  ];

  for (final session in expertSessions) {
    await sessionsBox.put(session.id, session);
  }
  await putWeights();
  await putFood();
}
