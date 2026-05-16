import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  Future<void> exportData() async {
    final exercisesBox = Hive.box<Exercise>('exercises');
    final routinesBox = Hive.box<Routine>('routines');
    final sessionsBox = Hive.box<WorkoutSession>('sessions');
    final bodyWeightLogsBox = Hive.box<BodyWeightLog>('bodyWeightLogs');
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
      'settings': settingsBox.toMap().map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };

    final jsonString = jsonEncode(data);

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/larger_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
    );
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'LarGer App Backup');
  }

  Future<bool> importData() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return false; // User canceled
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final exercisesBox = Hive.box<Exercise>('exercises');
      final routinesBox = Hive.box<Routine>('routines');
      final sessionsBox = Hive.box<WorkoutSession>('sessions');
      final bodyWeightLogsBox = Hive.box<BodyWeightLog>('bodyWeightLogs');
      final settingsBox = Hive.box('settings');

      // CRITICAL: Strict overwrite
      await exercisesBox.clear();
      await routinesBox.clear();
      await sessionsBox.clear();
      await bodyWeightLogsBox.clear();
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

      // Restore Settings
      if (data['settings'] != null) {
        final settingsData = data['settings'] as Map<String, dynamic>;
        for (var entry in settingsData.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      print('Error importing data: \$e');
      return false;
    }
  }
}
