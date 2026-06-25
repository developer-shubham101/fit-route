import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';
import '../services/user_profile_service.dart';
import '../services/last_used_service.dart';
import '../models/user_profile.dart';

final prefsServiceProvider = Provider<PrefsService>((ref) => PrefsService());
final lastUsedServiceProvider =
    Provider<LastUsedService>((ref) => LastUsedService());
final userProfileServiceProvider =
    Provider<UserProfileService>((ref) => UserProfileService());

final unitsProvider = FutureProvider<String>((ref) async {
  return ref.read(prefsServiceProvider).getDefaultUnits();
});

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>(
        (ref) => OnboardingNotifier(ref));

class OnboardingNotifier extends StateNotifier<bool> {
  final Ref ref;
  OnboardingNotifier(this.ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(prefsServiceProvider);
    state = await prefs.getOnboardingComplete();
  }

  Future<void> setComplete(bool value) async {
    final prefs = ref.read(prefsServiceProvider);
    await prefs.setOnboardingComplete(value);
    state = value;
  }
}

final profileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
        (ref) => UserProfileNotifier(ref));

// Theme mode provider for app-wide theme switching
final appThemeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final Ref ref;
  UserProfileNotifier(this.ref) : super(null) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final service = ref.read(userProfileServiceProvider);
    final profile = await service.getProfile();
    state = profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final service = ref.read(userProfileServiceProvider);
    await service.saveProfile(profile);
    state = profile;
  }

  Future<void> clearProfile() async {
    final service = ref.read(userProfileServiceProvider);
    await service.clearProfile();
    state = null;
  }
}
