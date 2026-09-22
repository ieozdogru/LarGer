// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 0;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String?,
      name: fields[1] as String,
      category: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 1;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine(
      id: fields[0] as String?,
      name: fields[1] as String,
      exercises: (fields[2] as List?)?.cast<RoutineExercise>(),
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.exercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final int typeId = 2;

  @override
  WorkoutSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSet()
      ..reps = fields[0] as int
      ..weight = fields[1] as double
      ..isCompleted = fields[2] as bool
      ..id = fields[3] as String? ?? uuid.v4();
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.reps)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutExerciseAdapter extends TypeAdapter<WorkoutExercise> {
  @override
  final int typeId = 3;

  @override
  WorkoutExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutExercise()
      ..exerciseId = fields[0] as String?
      ..exerciseName = fields[1] as String?
      ..sets = (fields[2] as List).cast<WorkoutSet>()
      ..notes = fields[3] as String?;
  }

  @override
  void write(BinaryWriter writer, WorkoutExercise obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.sets)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 4;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String?,
    )
      ..routineName = fields[1] as String?
      ..startTime = fields[2] as DateTime
      ..endTime = fields[3] as DateTime?
      ..exercises = (fields[4] as List).cast<WorkoutExercise>()
      ..totalVolume = fields[5] as double
      ..isCompleted = fields[6] as bool
      ..notes = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.routineName)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.exercises)
      ..writeByte(5)
      ..write(obj.totalVolume)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BodyWeightLogAdapter extends TypeAdapter<BodyWeightLog> {
  @override
  final int typeId = 5;

  @override
  BodyWeightLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyWeightLog(
      id: fields[0] as String?,
      weight: fields[1] as double,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BodyWeightLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyWeightLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoutineExerciseAdapter extends TypeAdapter<RoutineExercise> {
  @override
  final int typeId = 6;

  @override
  RoutineExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineExercise(
      exerciseId: fields[0] as String,
      targetSets: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineExercise obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.targetSets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 7;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      id: fields[0] as String?,
      name: fields[1] as String,
      meal: fields[2] as String,
      loggedAt: fields[3] as DateTime,
      servingLabel: fields[4] as String?,
      servings: fields[5] as double,
      calories: fields[6] as double?,
      proteinG: fields[7] as double?,
      carbsG: fields[8] as double?,
      fatG: fields[9] as double?,
      source: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.meal)
      ..writeByte(3)
      ..write(obj.loggedAt)
      ..writeByte(4)
      ..write(obj.servingLabel)
      ..writeByte(5)
      ..write(obj.servings)
      ..writeByte(6)
      ..write(obj.calories)
      ..writeByte(7)
      ..write(obj.proteinG)
      ..writeByte(8)
      ..write(obj.carbsG)
      ..writeByte(9)
      ..write(obj.fatG)
      ..writeByte(10)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
