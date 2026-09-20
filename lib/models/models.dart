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

@HiveType(typeId: 7)
class FoodEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String meal;

  @HiveField(3)
  late DateTime loggedAt;

  @HiveField(4)
  String? servingLabel;

  @HiveField(5)
  late double servings;

  @HiveField(6)
  double? calories;

  @HiveField(7)
  double? proteinG;

  @HiveField(8)
  double? carbsG;

  @HiveField(9)
  double? fatG;

  @HiveField(10)
  late String source;

  FoodEntry({
    String? id,
    required this.name,
    required this.meal,
    required this.loggedAt,
    this.servingLabel,
    this.servings = 1,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.source = 'manual',
  }) {
    this.id = id ?? uuid.v4();
  }

  double? get totalCalories => _scaled(calories);
  double? get totalProteinG => _scaled(proteinG);
  double? get totalCarbsG => _scaled(carbsG);
  double? get totalFatG => _scaled(fatG);

  double? _scaled(double? value) {
    if (value == null) return null;
    return value * servings;
  }
}
