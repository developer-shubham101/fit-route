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
  String type;
  @HiveField(3)
  String description;
  @HiveField(4)
  List<ProgramDay> days;
  @HiveField(5, defaultValue: '')
  String goal;
  @HiveField(6, defaultValue: '')
  String level;
  @HiveField(7, defaultValue: 0)
  int durationMinutes;
  @HiveField(8, defaultValue: [])
  List<String> equipmentNeeded;
  @HiveField(9, defaultValue: [])
  List<String> location;
  @HiveField(10, defaultValue: [])
  List<String> tags;

  Program({
    required this.id,
    required this.name,
    this.type = 'Custom',
    this.description = '',
    required this.days,
    this.goal = '',
    this.level = '',
    this.durationMinutes = 0,
    List<String>? equipmentNeeded,
    List<String>? location,
    List<String>? tags,
  })  : equipmentNeeded = equipmentNeeded ?? [],
        location = location ?? [],
        tags = tags ?? [];
}
