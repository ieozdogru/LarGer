import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  Future<void> exportData() async {
    final exercisesBox = Hive.box<Exercise>('exercises');
    final routinesBox = Hive.box<Routine>('routines');
    final sessionsBox = Hive.box<WorkoutSession>('sessions');
    final bodyWeightLogsBox = Hive.box<BodyWeightLog>('bodyWeightLogs');
    final foodEntriesBox = Hive.box<FoodEntry>('foodEntries');
    final settingsBox = Hive.box('settings');

    final data = {
      'exercises': exercisesBox.values
          .map((e) => {'id': e.id, 'name': e.name, 'category': e.category})
          .toList(),
      'routines': routinesBox.values
          .map(
            (r) => {
              'id': r.id,
              'name': r.name,
              'exercises': r.exercises
                  .map(
                    (re) => {
                      'exerciseId': re.exerciseId,
                      'targetSets': re.targetSets,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'sessions': sessionsBox.values
          .map(
            (s) => {
              'id': s.id,
              'routineName': s.routineName,
              'startTime': s.startTime.toIso8601String(),
              'endTime': s.endTime?.toIso8601String(),
              'exercises': s.exercises
                  .map(
                    (we) => {
                      'exerciseId': we.exerciseId,
                      'exerciseName': we.exerciseName,
                      'sets': we.sets
                          .map(
                            (set) => {
                              'reps': set.reps,
                              'weight': set.weight,
                              'isCompleted': set.isCompleted,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
              'totalVolume': s.totalVolume,
              'isCompleted': s.isCompleted,
            },
          )
          .toList(),
      'bodyWeightLogs': bodyWeightLogsBox.values
          .map(
            (b) => {
              'id': b.id,
              'weight': b.weight,
              'date': b.date.toIso8601String(),
            },
          )
          .toList(),
      'foodEntries': foodEntriesBox.values
          .map(
            (f) => {
              'id': f.id,
              'name': f.name,
              'meal': f.meal,
              'loggedAt': f.loggedAt.toIso8601String(),
              'servingLabel': f.servingLabel,
              'servings': f.servings,
              'calories': f.calories,
              'proteinG': f.proteinG,
              'carbsG': f.carbsG,
              'fatG': f.fatG,
              'source': f.source,
            },
          )
          .toList(),
      'settings': settingsBox.toMap().map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final fileName =
        'larger_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        text: 'LarGer App Backup',
        fileNameOverrides: [fileName],
      ),
    );
  }

  Future<bool> importData() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (picked == null) {
      return false;
    }

    final jsonString = await _readPickedJson(picked);
    if (jsonString == null) {
      return false;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final exercisesBox = Hive.box<Exercise>('exercises');
      final routinesBox = Hive.box<Routine>('routines');
      final sessionsBox = Hive.box<WorkoutSession>('sessions');
      final bodyWeightLogsBox = Hive.box<BodyWeightLog>('bodyWeightLogs');
      final foodEntriesBox = Hive.box<FoodEntry>('foodEntries');
      final settingsBox = Hive.box('settings');

      // CRITICAL: Strict overwrite
      await exercisesBox.clear();
      await routinesBox.clear();
      await sessionsBox.clear();
      if (Hive.isBoxOpen('activeWorkout')) {
        await Hive.box<WorkoutSession>('activeWorkout').clear();
      }
      await bodyWeightLogsBox.clear();
      await foodEntriesBox.clear();
      await settingsBox.clear();

      // Restore Exercises
      if (data['exercises'] != null) {
        for (var eData in data['exercises']) {
          final exercise = Exercise(
            id: eData['id'],
            name: eData['name'],
            category: eData['category'],
          );
          await exercisesBox.put(exercise.id, exercise);
        }
      }

      // Restore Routines
      if (data['routines'] != null) {
        for (var rData in data['routines']) {
          List<RoutineExercise> exercises = [];
          if (rData['exercises'] != null) {
            for (var reData in rData['exercises']) {
              exercises.add(
                RoutineExercise(
                  exerciseId: reData['exerciseId'],
                  targetSets: reData['targetSets'] ?? 0,
                ),
              );
            }
          }
          final routine = Routine(
            id: rData['id'],
            name: rData['name'],
            exercises: exercises,
          );
          await routinesBox.put(routine.id, routine);
        }
      }

      // Restore Sessions
      if (data['sessions'] != null) {
        for (var sData in data['sessions']) {
          final session = WorkoutSession(id: sData['id']);
          session.routineName = sData['routineName'];
          session.startTime = DateTime.parse(sData['startTime']);
          if (sData['endTime'] != null) {
            session.endTime = DateTime.parse(sData['endTime']);
          }
          session.totalVolume = (sData['totalVolume'] ?? 0.0).toDouble();
          session.isCompleted = sData['isCompleted'] ?? false;

          List<WorkoutExercise> workoutExercises = [];
          if (sData['exercises'] != null) {
            for (var weData in sData['exercises']) {
              final we = WorkoutExercise();
              we.exerciseId = weData['exerciseId'];
              we.exerciseName = weData['exerciseName'];

              List<WorkoutSet> sets = [];
              if (weData['sets'] != null) {
                for (var setData in weData['sets']) {
                  final ws = WorkoutSet();
                  ws.reps = setData['reps'] ?? 0;
                  ws.weight = (setData['weight'] ?? 0.0).toDouble();
                  ws.isCompleted = setData['isCompleted'] ?? false;
                  sets.add(ws);
                }
              }
              we.sets = sets;
              workoutExercises.add(we);
            }
          }
          session.exercises = workoutExercises;

          await sessionsBox.put(session.id, session);
        }
      }

      // Restore Body Weight Logs
      if (data['bodyWeightLogs'] != null) {
        for (var bData in data['bodyWeightLogs']) {
          final log = BodyWeightLog(
            id: bData['id'],
            weight: (bData['weight'] ?? 0.0).toDouble(),
            date: DateTime.parse(bData['date']),
          );
          await bodyWeightLogsBox.put(log.id, log);
        }
      }

      if (data['foodEntries'] != null) {
        for (var fData in data['foodEntries']) {
          final entry = FoodEntry(
            id: fData['id'],
            name: fData['name'] ?? '',
            meal: fData['meal'] ?? 'snack',
            loggedAt: DateTime.parse(fData['loggedAt']),
            servingLabel: fData['servingLabel'],
            servings: (fData['servings'] ?? 1.0).toDouble(),
            calories: (fData['calories'] as num?)?.toDouble(),
            proteinG: (fData['proteinG'] as num?)?.toDouble(),
            carbsG: (fData['carbsG'] as num?)?.toDouble(),
            fatG: (fData['fatG'] as num?)?.toDouble(),
            source: fData['source'] ?? 'manual',
          );
          await foodEntriesBox.put(entry.id, entry);
        }
      }

      // Restore Settings
      if (data['settings'] != null) {
        final settingsData = data['settings'] as Map<String, dynamic>;
        for (var entry in settingsData.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  Future<String?> _readPickedJson(PlatformFile picked) async {
    try {
      final bytes = await picked.readAsBytes();
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }
}
