import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String boxName = 'user_profile';

  Future<UserProfile?> getProfile() async {
    final box = await Hive.openBox<UserProfile>(boxName);
    if (box.isEmpty) return null;
    return box.getAt(0);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await Hive.openBox<UserProfile>(boxName);
    if (box.isEmpty) {
      await box.add(profile);
    } else {
      await box.putAt(0, profile);
    }
  }

  Future<void> clearProfile() async {
    final box = await Hive.openBox<UserProfile>(boxName);
    await box.clear();
  }
}
