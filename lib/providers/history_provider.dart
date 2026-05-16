import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';

final historyProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final box = Hive.box<WorkoutSession>('sessions');
  final sessions = box.values.toList();
  sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
  return sessions;
});

Future<void> deleteSession(WidgetRef ref, String sessionId) async {
  final box = Hive.box<WorkoutSession>('sessions');
  await box.delete(sessionId);
  ref.invalidate(historyProvider);
}

final previousSessionProvider = Provider.family<WorkoutExercise?, String?>((
  ref,
  exerciseId,
) {
  if (exerciseId == null) return null;
  final historyAsync = ref.watch(historyProvider);
  return historyAsync.maybeWhen(
    data: (sessions) {
      for (var session in sessions) {
        for (var ex in session.exercises) {
          if (ex.exerciseId == exerciseId && ex.sets.isNotEmpty) {
            return ex;
          }
        }
      }
      return null;
    },
    orElse: () => null,
  );
});
