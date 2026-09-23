import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/history_provider.dart';

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

  test('historyProvider returns sessions newest first', () async {
    final box = Hive.box<WorkoutSession>('sessions');
    final older = WorkoutSession(id: 'old')
      ..startTime = DateTime(2026, 1, 1)
      ..isCompleted = true;
    final newer = WorkoutSession(id: 'new')
      ..startTime = DateTime(2026, 2, 1)
      ..isCompleted = true;
    await box.put(older.id, older);
    await box.put(newer.id, newer);

    final sessions = await container.read(historyProvider.future);

    expect(sessions.map((s) => s.id).toList(), ['new', 'old']);
  });

  test('previousSessionProvider finds latest matching exercise', () async {
    final box = Hive.box<WorkoutSession>('sessions');
    final exercise = WorkoutExercise()
      ..exerciseId = 'ex-1'
      ..exerciseName = 'Bench'
      ..sets = [WorkoutSet()..reps = 8 ..weight = 60];

    final session = WorkoutSession(id: 's1')
      ..startTime = DateTime(2026, 2, 1)
      ..exercises = [exercise]
      ..isCompleted = true;
    await box.put(session.id, session);

    // Warm history first so family provider can read data.
    await container.read(historyProvider.future);
    final previous = container.read(previousSessionProvider('ex-1'));

    expect(previous, isNotNull);
    expect(previous!.exerciseName, 'Bench');
    expect(previous.sets.first.reps, 8);
  });

  test('previousSessionProvider returns null for unknown exercise', () async {
    await container.read(historyProvider.future);
    expect(container.read(previousSessionProvider('missing')), isNull);
    expect(container.read(previousSessionProvider(null)), isNull);
  });
}
