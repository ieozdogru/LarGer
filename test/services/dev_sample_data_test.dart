import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/services/dev_sample_data.dart';

import '../helpers/hive_test_setup.dart';

Future<void> _seedCatalog() async {
  if (!Hive.isBoxOpen('exercises')) {
    await Hive.openBox<Exercise>('exercises');
  }
  final box = Hive.box<Exercise>('exercises');
  await box.clear();

  final names = [
    'Bench Press',
    'Incline Bench Press',
    'Dumbbell Bench Press',
    'Dips',
    'Overhead Press',
    'Dumbbell Shoulder Press',
    'Lateral Raise',
    'Cable Lateral Raise',
    'Tricep Pushdown',
    'Skullcrushers',
    'Overhead Tricep Extension',
    'Deadlift',
    'Pull Up',
    'Barbell Row',
    'Lat Pulldown',
    'Seated Cable Row',
    'Face Pull',
    'Barbell Curl',
    'Hammer Curl',
    'Preacher Curl',
    'Squat',
    'Front Squat',
    'Leg Press',
    'Romanian Deadlift',
    'Leg Curl',
    'Leg Extension',
    'Standing Calf Raise',
    'Seated Calf Raise',
    'Crunch',
    'Plank',
  ];

  for (final name in names) {
    final exercise = Exercise(name: name, category: 'Test');
    await box.put(exercise.id, exercise);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveForTests();
    await _seedCatalog();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('exercises')) {
      await Hive.box<Exercise>('exercises').clear();
    }
    await tearDownHiveForTests();
  });

  test('beginner tier has zero routines and sessions', () async {
    await seedDevSampleData(tier: SampleDataTier.beginner);

    expect(Hive.box<Routine>('routines').isEmpty, isTrue);
    expect(Hive.box<WorkoutSession>('sessions').isEmpty, isTrue);
    expect(Hive.box<FoodEntry>('foodEntries').isEmpty, isTrue);
    expect(Hive.box('settings').containsKey(calorieSexKey), isFalse);
    expect(
      Hive.box('settings').get(SampleDataTier.settingsKey),
      SampleDataTier.beginner.storageValue,
    );
  });

  test('intermediate tier has 1 routine with 3 exercises', () async {
    await seedDevSampleData(tier: SampleDataTier.intermediate);

    final routines = Hive.box<Routine>('routines').values.toList();
    expect(routines, hasLength(1));
    expect(routines.first.exercises, hasLength(3));
    expect(Hive.box<WorkoutSession>('sessions').isNotEmpty, isTrue);

    final ids = routines.first.exercises.map((e) => e.exerciseId).toSet();
    expect(ids, hasLength(3));

    final foods = Hive.box<FoodEntry>('foodEntries').values.toList();
    final today = DateTime.now();
    final todayFoods = foods.where((entry) {
      return entry.loggedAt.year == today.year &&
          entry.loggedAt.month == today.month &&
          entry.loggedAt.day == today.day;
    });
    expect(todayFoods, isNotEmpty);
    expect(todayFoods.every((entry) => entry.calories != null), isTrue);
    expect(Hive.box('settings').get(calorieSexKey), 'male');
    expect(Hive.box('settings').get(calorieGoalKey), 'maintain');
  });

  test('expert tier has 3+ routines and 26+ distinct exercises', () async {
    await seedDevSampleData(tier: SampleDataTier.expert);

    final routines = Hive.box<Routine>('routines').values.toList();
    expect(routines.length, greaterThanOrEqualTo(3));

    final ids = <String>{};
    for (final routine in routines) {
      ids.addAll(routine.exercises.map((e) => e.exerciseId));
    }
    expect(ids.length, greaterThanOrEqualTo(26));
    expect(
      Hive.box<WorkoutSession>('sessions').length,
      greaterThanOrEqualTo(3),
    );
    expect(Hive.box<FoodEntry>('foodEntries').isNotEmpty, isTrue);
  });
}
