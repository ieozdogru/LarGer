import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart';

const uuid = Uuid();

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String category;

  Exercise({String? id, required this.name, required this.category}) {
    this.id = id ?? uuid.v4();
  }
}

@HiveType(typeId: 1)
class Routine extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  List<RoutineExercise> exercises = [];

  Routine({String? id, required this.name, List<RoutineExercise>? exercises}) {
    this.id = id ?? uuid.v4();
    if (exercises != null) {
      this.exercises = exercises;
    }
  }
}

@HiveType(typeId: 2)
class WorkoutSet {
  @HiveField(0)
  int reps = 0;

  @HiveField(1)
  double weight = 0.0;

  @HiveField(2)
  bool isCompleted = false;
}

@HiveType(typeId: 3)
class WorkoutExercise {
  @HiveField(0)
  String? exerciseId;

  @HiveField(1)
  String? exerciseName;

  @HiveField(2)
  List<WorkoutSet> sets = [];

  @HiveField(3)
  String? notes;
}

@HiveType(typeId: 4)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String? routineName;

  @HiveField(2)
  late DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  List<WorkoutExercise> exercises = [];

  @HiveField(5)
  double totalVolume = 0.0;

  @HiveField(6)
  bool isCompleted = false;

  @HiveField(7)
  String? notes;

  WorkoutSession({String? id}) {
    this.id = id ?? uuid.v4();
  }
}

@HiveType(typeId: 5)
class BodyWeightLog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double weight;

  @HiveField(2)
  late DateTime date;

  BodyWeightLog({String? id, required this.weight, required this.date}) {
    this.id = id ?? uuid.v4();
  }
}

@HiveType(typeId: 6)
class RoutineExercise {
  @HiveField(0)
  String exerciseId;

  @HiveField(1)
  int targetSets;

  RoutineExercise({required this.exerciseId, required this.targetSets});
}
