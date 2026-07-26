import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/providers/routine_provider.dart';

enum TodaySuggestionType { emptyRoutines, nextRoutine, skippedDays }

class TodaySuggestion {
  final TodaySuggestionType type;
  final String title;
  final String? subtitle;
  final int priority;
  final String? routineId;

  const TodaySuggestion({
    required this.type,
    required this.title,
    this.subtitle,
    required this.priority,
    this.routineId,
  });
}

class TodaySuggestionEngine {
  /// Pure ranking logic for tests and the Today hero.
  static TodaySuggestion build({
    required List<Routine> routines,
    required List<WorkoutSession> sessions,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (routines.isEmpty) {
      return const TodaySuggestion(
        type: TodaySuggestionType.emptyRoutines,
        title: 'Create your first routine',
        subtitle: 'Build a plan, then hit play to start.',
        priority: 100,
      );
    }

    final lastSessionByRoutine = <String, DateTime>{};
    DateTime? newestSession;

    for (final session in sessions) {
      if (!session.isCompleted) continue;
      final name = session.routineName;
      if (name != null && name.isNotEmpty) {
        final previous = lastSessionByRoutine[name];
        if (previous == null || session.startTime.isAfter(previous)) {
          lastSessionByRoutine[name] = session.startTime;
        }
      }
      if (newestSession == null || session.startTime.isAfter(newestSession)) {
        newestSession = session.startTime;
      }
    }

    Routine? leastRecent;
    DateTime? leastRecentAt;
    for (final routine in routines) {
      final lastAt = lastSessionByRoutine[routine.name];
      if (leastRecent == null) {
        leastRecent = routine;
        leastRecentAt = lastAt;
        continue;
      }
      // Never-used wins over any used routine.
      if (lastAt == null && leastRecentAt != null) {
        leastRecent = routine;
        leastRecentAt = null;
        continue;
      }
      if (lastAt != null && leastRecentAt != null && lastAt.isBefore(leastRecentAt)) {
        leastRecent = routine;
        leastRecentAt = lastAt;
      }
      // If both never used, keep the first (stable).
    }

    final chosen = leastRecent!;
    final daysSinceLast = newestSession == null
        ? null
        : current.difference(newestSession).inDays;

    final skippedSubtitle = daysSinceLast != null && daysSinceLast >= 2
        ? '$daysSinceLast days since last session'
        : null;

    if (skippedSubtitle != null) {
      return TodaySuggestion(
        type: TodaySuggestionType.skippedDays,
        title: 'Do ${chosen.name} today?',
        subtitle: skippedSubtitle,
        priority: 80,
        routineId: chosen.id,
      );
    }

    return TodaySuggestion(
      type: TodaySuggestionType.nextRoutine,
      title: 'Do ${chosen.name} today?',
      subtitle: leastRecentAt == null
          ? 'You haven\'t run this routine yet'
          : 'Least recently trained',
      priority: 60,
      routineId: chosen.id,
    );
  }
}

final todaySuggestionProvider = Provider<AsyncValue<TodaySuggestion>>((ref) {
  final routinesAsync = ref.watch(routineNotifierProvider);
  final sessionsAsync = ref.watch(historyProvider);

  return routinesAsync.when(
    data: (routines) {
      return sessionsAsync.when(
        data: (sessions) => AsyncValue.data(
          TodaySuggestionEngine.build(
            routines: routines,
            sessions: sessions,
          ),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final lastCompletedSessionProvider = Provider<AsyncValue<WorkoutSession?>>((
  ref,
) {
  final sessionsAsync = ref.watch(historyProvider);
  return sessionsAsync.whenData((sessions) {
    final completed = sessions.where((s) => s.isCompleted).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return completed.isEmpty ? null : completed.first;
  });
});
