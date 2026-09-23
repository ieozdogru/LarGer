import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/providers/profile_provider.dart';

import '../helpers/hive_test_setup.dart';

WorkoutSession _session({
  required String id,
  required DateTime start,
  required List<WorkoutExercise> exercises,
}) {
  return WorkoutSession(id: id)
    ..startTime = start
    ..isCompleted = true
    ..exercises = exercises;
}

WorkoutExercise _lift({
  required String id,
  required String name,
  required bool completed,
}) {
  return WorkoutExercise()
    ..exerciseId = id
    ..exerciseName = name
    ..sets = [
      WorkoutSet()
        ..reps = 5
        ..weight = 60
        ..isCompleted = completed,
    ];
}

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

  test('trackedExercisesProvider ignores exercises with no completed sets',
      () async {
    final box = Hive.box<WorkoutSession>('sessions');
    await box.put(
      's1',
      _session(
        id: 's1',
        start: DateTime(2026, 1, 1),
        exercises: [
          _lift(id: 'bench', name: 'Bench Press', completed: false),
          _lift(id: 'squat', name: 'Squat', completed: true),
        ],
      ),
    );

    await container.read(historyProvider.future);
    final tracked = container.read(trackedExercisesProvider).value!;

    expect(tracked.map((e) => e.exerciseId), ['squat']);
  });

  test('recentTrackedExercisesProvider returns newest five only', () async {
    final box = Hive.box<WorkoutSession>('sessions');
    for (var i = 0; i < 6; i++) {
      await box.put(
        's$i',
        _session(
          id: 's$i',
          start: DateTime(2026, 1, i + 1),
          exercises: [
            _lift(id: 'ex-$i', name: 'Exercise $i', completed: true),
          ],
        ),
      );
    }

    await container.read(historyProvider.future);
    final recent = container.read(recentTrackedExercisesProvider).value!;

    expect(recent, hasLength(5));
    expect(recent.first.exerciseId, 'ex-5');
    expect(recent.last.exerciseId, 'ex-1');
    expect(recent.any((e) => e.exerciseId == 'ex-0'), isFalse);
  });
}
