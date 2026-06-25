import 'package:hive/hive.dart';
part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  int age;
  @HiveField(2)
  String gender;
  @HiveField(3)
  double weight;
  @HiveField(4)
  String weightUnit;
  @HiveField(5)
  double height;
  @HiveField(6)
  String heightUnit;
  @HiveField(7)
  double bmi;
  @HiveField(8)
  DateTime lastUpdated;

  UserProfile({
    required this.id,
    required this.age,
    required this.gender,
    required this.weight,
    required this.weightUnit,
    required this.height,
    required this.heightUnit,
    required this.bmi,
    required this.lastUpdated,
  });
}
