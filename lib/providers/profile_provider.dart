import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/history_provider.dart';

final bodyWeightProvider = FutureProvider<List<BodyWeightLog>>((ref) async {
  final box = Hive.box<BodyWeightLog>('bodyWeightLogs');
  final logs = box.values.toList();
  logs.sort((a, b) => b.date.compareTo(a.date)); // Newest first
  return logs;
});

final heightProvider = Provider<double>((ref) {
  return Hive.box('settings').get('height', defaultValue: 170.0) as double;
});

final profileNotifierProvider = Provider<ProfileNotifier>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier {
  final Ref ref;
  ProfileNotifier(this.ref);

  Future<void> logBodyWeight(double weight) async {
    final box = Hive.box<BodyWeightLog>('bodyWeightLogs');
    final log = BodyWeightLog(weight: weight, date: DateTime.now());
    await box.put(log.id, log);
    ref.invalidate(bodyWeightProvider);
  }

  double getHeight() {
    return ref.read(heightProvider);
  }

  Future<void> setHeight(double height) async {
    await Hive.box('settings').put('height', height);
    ref.invalidate(heightProvider);
  }
}

class ExerciseAnalytics {
  final double prWeight;
  final List<ProgressionEntry> progression;
  ExerciseAnalytics(this.prWeight, this.progression);
}

class ProgressionEntry {
  final DateTime date;
  final double maxWeight;
  final int reps;
  ProgressionEntry(this.date, this.maxWeight, this.reps);
}

final exerciseAnalyticsProvider =
    Provider.family<AsyncValue<ExerciseAnalytics?>, String?>((ref, exerciseId) {
      if (exerciseId == null) return const AsyncValue.data(null);

      final historyAsync = ref.watch(historyProvider);
      return historyAsync.whenData((sessions) {
        double prWeight = 0.0;
        List<ProgressionEntry> progression = [];

        final reversedSessions = sessions.reversed.toList();

        for (var session in reversedSessions) {
          for (var ex in session.exercises) {
            if (ex.exerciseId == exerciseId) {
              double maxWeightInSession = 0.0;
              int repsForMaxWeight = 0;
              bool lifted = false;

              for (var set in ex.sets) {
                if (set.isCompleted) {
                  lifted = true;
                  if (set.weight > maxWeightInSession) {
                    maxWeightInSession = set.weight;
                    repsForMaxWeight = set.reps;
                  }
                  if (set.weight > prWeight) {
                    prWeight = set.weight;
                  }
                }
              }

              if (lifted) {
                progression.add(
                  ProgressionEntry(
                    session.startTime,
                    maxWeightInSession,
                    repsForMaxWeight,
                  ),
                );
              }
            }
          }
        }

        return ExerciseAnalytics(prWeight, progression);
      });
    });
