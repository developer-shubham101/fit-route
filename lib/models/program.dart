import 'package:hive/hive.dart';
part 'program.g.dart';

@HiveType(typeId: 4)
class ProgramExercise extends HiveObject {
  @HiveField(0)
  String exerciseId;
  @HiveField(1)
  String exerciseName;
  @HiveField(2)
  int targetSets;
  @HiveField(3)
  int targetReps;
  @HiveField(4)
  double? targetWeightKg;
  @HiveField(5)
  int targetRestSeconds;
  @HiveField(6)
  String notes;

  ProgramExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeightKg,
    this.targetRestSeconds = 60,
    this.notes = '',
  });
}

@HiveType(typeId: 5)
class ProgramDay extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  List<ProgramExercise> exercises;

  ProgramDay({required this.name, required this.exercises});
}

@HiveType(typeId: 6)
class Program extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String type; // e.g. Full Body, PPL, Custom
  @HiveField(3)
  String description;
  @HiveField(4)
  List<ProgramDay> days;

  Program({
    required this.id,
    required this.name,
    this.type = 'Custom',
    this.description = '',
    required this.days,
  });
}
