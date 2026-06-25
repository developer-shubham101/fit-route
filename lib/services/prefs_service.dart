import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyDefaultUnits =
      'default_units'; // 'metric' or 'imperial'
  static const String keySeededDefaults = 'seeded_default_routines';
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
}
