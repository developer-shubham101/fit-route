import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyDefaultUnits =
      'default_units'; // 'metric' or 'imperial'
  static const String keySeededDefaults = 'seeded_default_routines'; // legacy key, unused
  static const String keySeededSampleData = 'seeded_sample_data';

  Future<bool> getSeededSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keySeededSampleData) ?? false;
  }

  Future<void> setSeededSampleData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySeededSampleData, value);
  }

  Future<bool> getOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyOnboardingComplete, value);
  }

  Future<String> getDefaultUnits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultUnits) ?? 'metric';
  }

  Future<void> setDefaultUnits(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDefaultUnits, value);
  }

  Future<bool> getSeededDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keySeededDefaults) ?? false;
  }

  Future<void> setSeededDefaults(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySeededDefaults, value);
  }

  Future<String?> getActiveProgramId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_program_id');
  }

  Future<void> setActiveProgramId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('active_program_id');
    } else {
      await prefs.setString('active_program_id', id);
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final programId = prefs.getString('session_program_id');
    final dayIndex = prefs.getInt('session_day_index');
    if (programId == null) return null;
    return {'programId': programId, 'dayIndex': dayIndex ?? 0};
  }

  Future<void> setActiveSession(String? programId, int? dayIndex) async {
    final prefs = await SharedPreferences.getInstance();
    if (programId == null) {
      await prefs.remove('session_program_id');
      await prefs.remove('session_day_index');
    } else {
      await prefs.setString('session_program_id', programId);
      await prefs.setInt('session_day_index', dayIndex ?? 0);
    }
  }
}
