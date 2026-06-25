import 'package:hive/hive.dart';
part 'workout_entry.g.dart';

@HiveType(typeId: 3)
class WorkoutEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String exerciseId;
  @HiveField(2)
  String exerciseName;
  @HiveField(3)
  String routineId;
  @HiveField(4)
  String type; // Bodyweight or External
  @HiveField(5)
  double? externalWeight;
  @HiveField(6)
  int reps;
  @HiveField(7)
  DateTime timestamp;
  @HiveField(8)
  int durationSeconds;

  WorkoutEntry({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.routineId,
    required this.type,
    this.externalWeight,
    required this.reps,
    required this.timestamp,
    required this.durationSeconds,
  });
}
