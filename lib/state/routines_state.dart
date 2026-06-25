import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/routine_service.dart';
import 'app_state.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

final routineServiceProvider =
    Provider<RoutineService>((ref) => RoutineService());

final routinesProvider = StateNotifierProvider<RoutinesNotifier, List<Routine>>(
    (ref) => RoutinesNotifier(ref));

class RoutinesNotifier extends StateNotifier<List<Routine>> {
  final Ref ref;
  RoutinesNotifier(this.ref) : super(const []) {
    load();
  }

  Future<void> load() async {
    final service = ref.read(routineServiceProvider);
    final routines = await service.getRoutines();
    if (routines.isEmpty) {
      await _maybeSeedDefaults();
      state = await service.getRoutines();
    } else {
      state = routines;
    }
  }

  Future<void> _maybeSeedDefaults() async {
    final prefs = ref.read(prefsServiceProvider);
    final alreadySeeded = await prefs.getSeededDefaults();
    if (alreadySeeded) return;
    final service = ref.read(routineServiceProvider);
    final defaults = await _defaultRoutinesFromJson();
    for (final r in defaults) {
      await service.addRoutine(r);
    }
    await prefs.setSeededDefaults(true);
  }

  Future<List<Routine>> _defaultRoutinesFromJson() async {
    final jsonStr =
        await rootBundle.loadString('assets/json/fitroute_routines.json');
    final List<dynamic> data = json.decode(jsonStr);
    return data.map<Routine>((r) {
      return Routine(
        id: r['id'].toString(),
        name: r['name'] ?? '',
        goal: r['goal'] ?? '',
        level: r['level'] ?? '',
        durationMinutes: r['duration_minutes'] ?? 0,
        equipmentNeeded: (r['equipment_needed'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        indoorOutdoor: (r['indoor_outdoor'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        tags:
            (r['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                [],
        exercises: (r['exercises'] as List<dynamic>? ?? []).map<Exercise>((ex) {
          return Exercise(
            id: ex['id'].toString(),
            name: ex['name'] ?? '',
            defaultType: ex['type'] ?? 'Bodyweight',
            description: ex['description'] ?? '',
            requiresExternal: ex['requires_external'] ?? false,
            equipment: (ex['equipment'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            suitableAtHome: ex['locations']?.contains('Home') ?? false,
            suitableAtGym: ex['locations']?.contains('Gym') ?? false,
       /*     mediaUrls: [
              ex['image_url'] ?? '',
              ex['gif_url'] ?? '',
              ex['video_url'] ?? ''
            ].where((url) => url != null && url.isNotEmpty).map( e -> e.toString()).toList(),*/
            category: ex['category'] ?? '',
            difficulty: ex['difficulty'] ?? '',
            locations: (ex['locations'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            instructions: ex['instructions'] ?? '',
            commonMistakes: ex['common_mistakes'] ?? '',
            benefits: ex['benefits'] ?? '',
            safetyTips: ex['safety_tips'] ?? '',
            primaryMuscles: (ex['primary_muscles'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            secondaryMuscles: (ex['secondary_muscles'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            setsRecommended: ex['sets_recommended'] ?? 0,
            repsRecommended: ex['reps_recommended'] ?? 0,
            timeRecommended: ex['time_recommended'] ?? "",
            caloriesBurnEstimate: ex['calories_burn_estimate'] ?? 0,
            progressionLevel: ex['progression_level'] ?? '',
            regressionLevel: ex['regression_level'] ?? '',
            imageUrl: ex['image_url'] ?? '',
            gifUrl: ex['gif_url'] ?? '',
            videoUrl: ex['video_url'] ?? '',
            audioCue: ex['audio_cue'] ?? '',
            tags: (ex['tags'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            indoorOutdoor: ex['indoor_outdoor'] ?? '',
            isFavorite: ex['is_favorite'] ?? false,
            isBodyweight: ex['is_bodyweight'] ?? false,
            requiresPartner: ex['requires_partner'] ?? false,
            warmupOrMain: ex['warmup_or_main'] ?? '',
          );
        }).toList(),
      );
    }).toList();
  }

  Routine? getById(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addRoutine(Routine routine) async {
    final service = ref.read(routineServiceProvider);
    await service.addRoutine(routine);
    await load();
  }

  Future<void> renameRoutine(String routineId, String newName) async {
    final service = ref.read(routineServiceProvider);
    final routines = await service.getRoutines();
    final idx = routines.indexWhere((r) => r.id == routineId);
    if (idx == -1) return;
    final routine = routines[idx];
    final updated =
        Routine(id: routine.id, name: newName, exercises: routine.exercises);
    await service.updateRoutine(idx, updated);
    await load();
  }

  Future<void> deleteRoutineAt(int index) async {
    final service = ref.read(routineServiceProvider);
    await service.deleteRoutine(index);
    await load();
  }

  Future<void> addExerciseToRoutine(String routineId, Exercise exercise) async {
    final service = ref.read(routineServiceProvider);
    final routines = await service.getRoutines();
    final idx = routines.indexWhere((r) => r.id == routineId);
    if (idx == -1) return;
    final routine = routines[idx];
    final updated = Routine(
        id: routine.id,
        name: routine.name,
        exercises: [...routine.exercises, exercise]);
    await service.updateRoutine(idx, updated);
    await load();
  }

  Future<void> renameExercise(
      String routineId, String exerciseId, String newName) async {
    final service = ref.read(routineServiceProvider);
    final routines = await service.getRoutines();
    final idx = routines.indexWhere((r) => r.id == routineId);
    if (idx == -1) return;
    final routine = routines[idx];
    final updatedExercises = routine.exercises
        .map((e) => e.id == exerciseId ? Exercise(id: e.id, name: newName) : e)
        .toList();
    final updated = Routine(
        id: routine.id, name: routine.name, exercises: updatedExercises);
    await service.updateRoutine(idx, updated);
    await load();
  }

  Future<void> removeExerciseFromRoutine(
      String routineId, String exerciseId) async {
    final service = ref.read(routineServiceProvider);
    final routines = await service.getRoutines();
    final idx = routines.indexWhere((r) => r.id == routineId);
    if (idx == -1) return;
    final routine = routines[idx];
    final updated = Routine(
      id: routine.id,
      name: routine.name,
      exercises: routine.exercises.where((e) => e.id != exerciseId).toList(),
    );
    await service.updateRoutine(idx, updated);
    await load();
  }

  Future<void> reorderExercises(
      String routineId, int oldIndex, int newIndex) async {
    final service = ref.read(routineServiceProvider);
    final routines = await service.getRoutines();
    final idx = routines.indexWhere((r) => r.id == routineId);
    if (idx == -1) return;
    final routine = routines[idx];
    final exercises = [...routine.exercises];
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moved);
    final updated =
        Routine(id: routine.id, name: routine.name, exercises: exercises);
    await service.updateRoutine(idx, updated);
    await load();
  }
}
