import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/services/local_user_data_service.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveForTests();
  });

  tearDown(() async {
    await tearDownHiveForTests();
  });

  test(
    'clearLocalUserData removes user boxes but keeps exercises closed/absent',
    () async {
      final sessions = Hive.box<WorkoutSession>('sessions');
      final routines = Hive.box<Routine>('routines');
      final weights = Hive.box<BodyWeightLog>('bodyWeightLogs');
      final foods = Hive.box<FoodEntry>('foodEntries');
      final settings = Hive.box('settings');

      await sessions.put(
        's1',
        WorkoutSession(id: 's1')..startTime = DateTime(2026, 1, 1),
      );
      await routines.put('r1', Routine(id: 'r1', name: 'Push'));
      await weights.put(
        'w1',
        BodyWeightLog(id: 'w1', weight: 80, date: DateTime(2026, 1, 1)),
      );
      await foods.put(
        'f1',
        FoodEntry(
          id: 'f1',
          name: 'Oats',
          meal: 'breakfast',
          loggedAt: DateTime(2026, 1, 1),
          calories: 150,
        ),
      );
      await settings.put('height', 180.0);
      await settings.put('sampleDataTier', 'expert');
      await settings.put(calorieSexKey, 'male');
      await settings.put(calorieClampedTargetKey, 2200.0);

      await clearLocalUserData();

      expect(sessions.isEmpty, isTrue);
      expect(routines.isEmpty, isTrue);
      expect(weights.isEmpty, isTrue);
      expect(foods.isEmpty, isTrue);
      expect(settings.containsKey('height'), isFalse);
      expect(settings.containsKey('sampleDataTier'), isFalse);
      expect(settings.containsKey(calorieSexKey), isFalse);
      expect(settings.containsKey(calorieClampedTargetKey), isFalse);
    },
  );

  test('clearLocalUserData is safe when boxes are already empty', () async {
    await expectLater(clearLocalUserData(), completes);
    expect(Hive.box<WorkoutSession>('sessions').isEmpty, isTrue);
    expect(Hive.box<Routine>('routines').isEmpty, isTrue);
  });
}
