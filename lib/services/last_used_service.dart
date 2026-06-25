import 'package:shared_preferences/shared_preferences.dart';

class LastUsedService {
  String _key(String exerciseId, String units) =>
      'last_weight:$units:$exerciseId';

  Future<double?> getLastExternalWeight(String exerciseId, String units) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key(exerciseId, units));
  }

  Future<void> setLastExternalWeight(
      String exerciseId, String units, double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key(exerciseId, units), weight);
  }
}
