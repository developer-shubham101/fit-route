import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';
import '../models/workout_entry.dart';
import '../models/program.dart';
import '../services/exercise_service.dart';
import '../services/workout_entry_service.dart';
import '../services/program_service.dart';
import '../services/prefs_service.dart';

class SeedService {
  final ExerciseService _exercises;
  final WorkoutEntryService _entries;
  final ProgramService _programs;
  final PrefsService _prefs;

  SeedService(this._exercises, this._entries, this._programs, this._prefs);

  Future<void> seedIfNeeded() async {
    final done = await _prefs.getSeededSampleData();
    if (done) return;
    await _seedExercises();
    await _seedFromJson();
    await _prefs.setSeededSampleData(true);
  }

  // ── Exercises from fitroute_exercises_detailed.json ───────────────────────
  Future<void> _seedExercises() async {
    final jsonStr = await rootBundle
        .loadString('assets/json/fitroute_exercises_detailed.json');
    final List<dynamic> data = json.decode(jsonStr);
    for (final ex in data) {
      await _exercises.addExercise(Exercise(
        id: ex['id'].toString(),
        name: ex['name'] ?? '',
        defaultType: ex['type'] ?? 'Bodyweight',
        description: ex['description'] ?? '',
        requiresExternal: ex['requires_external'] ?? false,
        equipment: (ex['equipment'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        suitableAtHome: (ex['locations'] as List<dynamic>?)
                ?.contains('Home') ??
            false,
        suitableAtGym: (ex['locations'] as List<dynamic>?)
                ?.contains('Gym') ??
            false,
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
        setsRecommended: (ex['sets_recommended'] as num?)?.toInt() ?? 0,
        repsRecommended: (ex['reps_recommended'] as num?)?.toInt() ?? 0,
        timeRecommended: ex['time_recommended'],
        caloriesBurnEstimate:
            (ex['calories_burn_estimate'] as num?)?.toInt() ?? 0,
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
      ));
    }
  }

  // ── Programs + workout entries from fitroute_seed_data.json ───────────────
  Future<void> _seedFromJson() async {
    final raw =
        await rootBundle.loadString('assets/json/fitroute_seed_data.json');
    final data = json.decode(raw) as Map<String, dynamic>;

    // Programs
    for (final p in (data['programs'] as List? ?? [])) {
      final days = (p['days'] as List? ?? []).map<ProgramDay>((d) {
        final exercises =
            (d['exercises'] as List? ?? []).map<ProgramExercise>((e) {
          return ProgramExercise(
            exerciseId: e['exercise_id'] ?? '',
            exerciseName: e['exercise_name'] ?? '',
            targetSets: (e['target_sets'] as num?)?.toInt() ?? 3,
            targetReps: (e['target_reps'] as num?)?.toInt() ?? 10,
            targetWeightKg: (e['target_weight_kg'] as num?)?.toDouble(),
            targetRestSeconds:
                (e['target_rest_seconds'] as num?)?.toInt() ?? 60,
            notes: e['notes'] ?? '',
          );
        }).toList();
        return ProgramDay(name: d['name'] ?? '', exercises: exercises);
      }).toList();

      await _programs.add(Program(
        id: p['id'] ?? '',
        name: p['name'] ?? '',
        type: p['type'] ?? 'Custom',
        description: p['description'] ?? '',
        goal: p['goal'] ?? '',
        level: p['level'] ?? '',
        durationMinutes: (p['duration_minutes'] as num?)?.toInt() ?? 0,
        equipmentNeeded: (p['equipment_needed'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        location: (p['location'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        tags: (p['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        days: days,
      ));
    }

    // Workout entries
    final now = DateTime.now();
    final rawEntries = (data['workout_entries'] as List? ?? []);
    for (int i = 0; i < rawEntries.length; i++) {
      final e = rawEntries[i];
      final daysAgo = (e['days_ago'] as num?)?.toInt() ?? 0;
      final hour = (e['hour'] as num?)?.toInt() ?? 10;
      final ts =
          DateTime(now.year, now.month, now.day - daysAgo, hour, i % 60, 0)
              .toUtc();
      await _entries.addEntry(WorkoutEntry(
        id: '${ts.millisecondsSinceEpoch}_${e['exercise_id']}_$i',
        exerciseId: e['exercise_id'] ?? '',
        exerciseName: e['exercise_name'] ?? '',
        routineId: e['routine_id'] ?? '',
        type: e['type'] ?? 'Bodyweight',
        externalWeight: (e['external_weight'] as num?)?.toDouble(),
        reps: (e['reps'] as num?)?.toInt() ?? 0,
        timestamp: ts,
        durationSeconds: 45 + ((e['reps'] as num?)?.toInt() ?? 0) * 3,
      ));
    }
  }
}
