import 'package:hive/hive.dart';
import 'exercise.dart';
part 'routine.g.dart';

@HiveType(typeId: 1)
class Routine extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  List<Exercise> exercises;
  @HiveField(3)
  String goal;
  @HiveField(4)
  String level;
  @HiveField(5)
  int durationMinutes;
  @HiveField(6)
  List<String> equipmentNeeded;
  @HiveField(7)
  List<String> indoorOutdoor;
  @HiveField(8)
  List<String> tags;

  Routine({
    required this.id,
    required this.name,
    required this.exercises,
    this.goal = '',
    this.level = '',
    this.durationMinutes = 0,
    List<String>? equipmentNeeded,
    List<String>? indoorOutdoor,
    List<String>? tags,
  })  : equipmentNeeded = equipmentNeeded ?? <String>[],
        indoorOutdoor = indoorOutdoor ?? <String>[],
        tags = tags ?? <String>[];
}
