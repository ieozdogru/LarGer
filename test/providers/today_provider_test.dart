import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/today_provider.dart';

void main() {
  final now = DateTime(2026, 7, 26, 12);

  WorkoutSession session({
    required String routineName,
    required DateTime start,
  }) {
    return WorkoutSession()
      ..routineName = routineName
      ..startTime = start
      ..endTime = start.add(const Duration(hours: 1))
      ..isCompleted = true
      ..exercises = []
      ..totalVolume = 0;
  }

  test('empty routines yields emptyRoutines suggestion', () {
    final suggestion = TodaySuggestionEngine.build(
      routines: const [],
      sessions: const [],
      now: now,
    );

    expect(suggestion.type, TodaySuggestionType.emptyRoutines);
    expect(suggestion.title, contains('first routine'));
    expect(suggestion.routineId, isNull);
  });

  test('never-used routine is preferred over recently used', () {
    final push = Routine(id: 'push', name: 'Push');
    final pull = Routine(id: 'pull', name: 'Pull');

    final suggestion = TodaySuggestionEngine.build(
      routines: [push, pull],
      sessions: [
        session(
          routineName: 'Push',
          start: now.subtract(const Duration(days: 1)),
        ),
      ],
      now: now,
    );

    expect(suggestion.routineId, 'pull');
    expect(suggestion.title, contains('Pull'));
    expect(
      suggestion.type,
      anyOf(TodaySuggestionType.nextRoutine, TodaySuggestionType.skippedDays),
    );
  });

  test('least recently used routine wins among used routines', () {
    final push = Routine(id: 'push', name: 'Push');
    final pull = Routine(id: 'pull', name: 'Pull');
    final legs = Routine(id: 'legs', name: 'Legs');

    final suggestion = TodaySuggestionEngine.build(
      routines: [push, pull, legs],
      sessions: [
        session(
          routineName: 'Push',
          start: now.subtract(const Duration(days: 2)),
        ),
        session(
          routineName: 'Pull',
          start: now.subtract(const Duration(days: 4)),
        ),
        session(
          routineName: 'Legs',
          start: now.subtract(const Duration(days: 9)),
        ),
      ],
      now: now,
    );

    expect(suggestion.routineId, 'legs');
    expect(suggestion.type, TodaySuggestionType.skippedDays);
    expect(suggestion.subtitle, contains('days since last session'));
  });

  test('skippedDays requires at least 2 days since newest session', () {
    final push = Routine(id: 'push', name: 'Push');

    final recent = TodaySuggestionEngine.build(
      routines: [push],
      sessions: [
        session(
          routineName: 'Push',
          start: now.subtract(const Duration(days: 1)),
        ),
      ],
      now: now,
    );
    expect(recent.type, TodaySuggestionType.nextRoutine);

    final stale = TodaySuggestionEngine.build(
      routines: [push],
      sessions: [
        session(
          routineName: 'Push',
          start: now.subtract(const Duration(days: 3)),
        ),
      ],
      now: now,
    );
    expect(stale.type, TodaySuggestionType.skippedDays);
    expect(stale.subtitle, '3 days since last session');
  });
}
