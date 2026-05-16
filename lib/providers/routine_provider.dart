import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';

final routinesProvider = FutureProvider<List<Routine>>((ref) async {
  final box = Hive.box<Routine>('routines');
  return box.values.toList();
});

class RoutineNotifier extends StateNotifier<AsyncValue<List<Routine>>> {
  RoutineNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final box = Hive.box<Routine>('routines');
      final routines = box.values.toList();
      state = AsyncValue.data(routines);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createRoutine(
    String name,
    List<RoutineExercise> exercises,
  ) async {
    final box = Hive.box<Routine>('routines');
    final routine = Routine(name: name, exercises: exercises);
    await box.put(routine.id, routine);
    await _load();
  }

  Future<void> updateRoutine(
    String id,
    String name,
    List<RoutineExercise> exercises,
  ) async {
    final box = Hive.box<Routine>('routines');
    final routine = Routine(id: id, name: name, exercises: exercises);
    await box.put(id, routine);
    await _load();
  }

  Future<void> deleteRoutine(String id) async {
    final box = Hive.box<Routine>('routines');
    await box.delete(id);
    await _load();
  }
}

final routineNotifierProvider =
    StateNotifierProvider<RoutineNotifier, AsyncValue<List<Routine>>>((ref) {
      return RoutineNotifier();
    });
