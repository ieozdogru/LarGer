import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/food_provider.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    await setUpHiveForTests();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await tearDownHiveForTests();
  });

  test('save and delete update food entries', () async {
    final notifier = container.read(foodNotifierProvider);
    await notifier.save(
      FoodEntry(
        id: 'f1',
        name: 'Oats',
        meal: 'breakfast',
        loggedAt: DateTime(2026, 9, 20, 8),
        servings: 1,
        calories: 150,
        proteinG: 5,
      ),
    );

    final entries = await container.read(foodEntriesProvider.future);
    expect(entries, hasLength(1));
    expect(entries.first.name, 'Oats');

    await notifier.delete('f1');
    final afterDelete = await container.read(foodEntriesProvider.future);
    expect(afterDelete, isEmpty);
  });

  test('day totals scale servings', () async {
    await container.read(foodNotifierProvider).save(
      FoodEntry(
        id: 'f1',
        name: 'Yogurt',
        meal: 'snack',
        loggedAt: DateTime(2026, 9, 20, 15),
        servings: 2,
        calories: 100,
        proteinG: 10,
        carbsG: 12,
        fatG: 3,
      ),
    );
    await container.read(foodEntriesProvider.future);

    final day = DateTime(2026, 9, 20);
    final totals = container.read(foodDayTotalsProvider(day)).requireValue;
    expect(totals.calories, 200);
    expect(totals.proteinG, 20);
    expect(totals.carbsG, 24);
    expect(totals.fatG, 6);

    final otherDay = container
        .read(foodEntriesForDayProvider(DateTime(2026, 9, 21)))
        .requireValue;
    expect(otherDay, isEmpty);
  });
}
