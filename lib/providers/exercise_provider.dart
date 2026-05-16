import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';

final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final box = Hive.box<Exercise>('exercises');
  final exercises = box.values.toList();
  exercises.sort((a, b) => a.name.compareTo(b.name));
  return exercises;
});
