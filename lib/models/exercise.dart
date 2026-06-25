import 'package:hive/hive.dart';
part 'exercise.g.dart';

@HiveType(typeId: 2)
class Exercise extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String defaultType; // 'Bodyweight' or 'External'
  @HiveField(3)
  String description;
  @HiveField(4)
  bool requiresExternal;
  @HiveField(5)
  List<String> equipment;
  @HiveField(6)
  bool suitableAtHome;
  @HiveField(7)
  bool suitableAtGym;
  @HiveField(8)
  List<String> mediaUrls;
  @HiveField(9)
  String category;
  @HiveField(10)
  String difficulty;
  @HiveField(11)
  List<String> locations;
  @HiveField(12)
  String instructions;
  @HiveField(13)
  String commonMistakes;
  @HiveField(14)
  String benefits;
  @HiveField(15)
  String safetyTips;
  @HiveField(16)
  List<String> primaryMuscles;
  @HiveField(17)
  List<String> secondaryMuscles;
  @HiveField(18)
  int setsRecommended;
  @HiveField(19)
  int repsRecommended;
  @HiveField(20)
  String? timeRecommended;
  @HiveField(21)
  int caloriesBurnEstimate;
  @HiveField(22)
  String progressionLevel;
  @HiveField(23)
  String regressionLevel;
  @HiveField(24)
  String imageUrl;
  @HiveField(25)
  String gifUrl;
  @HiveField(26)
  String videoUrl;
  @HiveField(27)
  String audioCue;
  @HiveField(28)
  List<String> tags;
  @HiveField(29)
  String indoorOutdoor;
  @HiveField(30)
  bool isFavorite;
  @HiveField(31)
  bool isBodyweight;
  @HiveField(32)
  bool requiresPartner;
  @HiveField(33)
  String warmupOrMain;

  Exercise({
    required this.id,
    required this.name,
    this.defaultType = 'Bodyweight',
    this.description = '',
    this.requiresExternal = false,
    List<String>? equipment,
    this.suitableAtHome = true,
    this.suitableAtGym = true,
    List<String>? mediaUrls,
    this.category = '',
    this.difficulty = '',
    List<String>? locations,
    this.instructions = '',
    this.commonMistakes = '',
    this.benefits = '',
    this.safetyTips = '',
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    this.setsRecommended = 0,
    this.repsRecommended = 0,
    this.timeRecommended,
    this.caloriesBurnEstimate = 0,
    this.progressionLevel = '',
    this.regressionLevel = '',
    this.imageUrl = '',
    this.gifUrl = '',
    this.videoUrl = '',
    this.audioCue = '',
    List<String>? tags,
    this.indoorOutdoor = '',
    this.isFavorite = false,
    this.isBodyweight = false,
    this.requiresPartner = false,
    this.warmupOrMain = '',
  })  : equipment = equipment ?? <String>[],
        mediaUrls = mediaUrls ?? <String>[],
        locations = locations ?? <String>[],
        primaryMuscles = primaryMuscles ?? <String>[],
        secondaryMuscles = secondaryMuscles ?? <String>[],
        tags = tags ?? <String>[];
}
