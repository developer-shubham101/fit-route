// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgramExerciseAdapter extends TypeAdapter<ProgramExercise> {
  @override
  final int typeId = 4;

  @override
  ProgramExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgramExercise(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      targetSets: fields[2] as int,
      targetReps: fields[3] as int,
      targetWeightKg: fields[4] as double?,
      targetRestSeconds: fields[5] as int,
      notes: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProgramExercise obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.targetSets)
      ..writeByte(3)
      ..write(obj.targetReps)
      ..writeByte(4)
      ..write(obj.targetWeightKg)
      ..writeByte(5)
      ..write(obj.targetRestSeconds)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgramDayAdapter extends TypeAdapter<ProgramDay> {
  @override
  final int typeId = 5;

  @override
  ProgramDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgramDay(
      name: fields[0] as String,
      exercises: (fields[1] as List).cast<ProgramExercise>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProgramDay obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.exercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgramAdapter extends TypeAdapter<Program> {
  @override
  final int typeId = 6;

  @override
  Program read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Program(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      description: fields[3] as String,
      days: (fields[4] as List).cast<ProgramDay>(),
    );
  }

  @override
  void write(BinaryWriter writer, Program obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
