import 'package:hive/hive.dart';
import '../models/exercise.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ExerciseService {
  static const String boxName = 'exercises';

  Future<List<Exercise>> getExercises() async {
    final box = await Hive.openBox<Exercise>(boxName);
    return box.values.toList();
  }

  Future<void> addExercise(Exercise exercise) async {
    final box = await Hive.openBox<Exercise>(boxName);
    await box.add(exercise);
  }

  Future<void> updateExercise(int index, Exercise exercise) async {
    final box = await Hive.openBox<Exercise>(boxName);
    await box.putAt(index, exercise);
  }

  Future<void> deleteExercise(int index) async {
    final box = await Hive.openBox<Exercise>(boxName);
    await box.deleteAt(index);
  }

  Future<int?> findIndexById(String id) async {
    final box = await Hive.openBox<Exercise>(boxName);
    for (int i = 0; i < box.length; i++) {
      final e = box.getAt(i);
      if (e != null && e.id == id) return i;
    }
    return null;
  }

  Future<void> updateById(String id, Exercise exercise) async {
    final idx = await findIndexById(id);
    if (idx == null) return;
    await updateExercise(idx, exercise);
  }

  Future<void> deleteById(String id) async {
    final idx = await findIndexById(id);
    if (idx == null) return;
    await deleteExercise(idx);
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<Exercise>(boxName);
    await box.clear();
  }

  Future<void> seedDefaultsIfEmpty() async {
    final box = await Hive.openBox<Exercise>(boxName);
    if (box.isNotEmpty) return;
    final jsonStr = await rootBundle
        .loadString('assets/json/fitroute_exercises_detailed.json');
    final List<dynamic> data = json.decode(jsonStr);
    final defaults = data.map<Exercise>((ex) {
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
        /*mediaUrls: [
          ex['image_url'] ?? '',
          ex['gif_url'] ?? '',
          ex['video_url'] ?? ''
        ].where((url) => url != null && url.isNotEmpty).toList(),*/
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
        timeRecommended: ex['time_recommended'],
        caloriesBurnEstimate: ex['calories_burn_estimate'] ?? 0,
        progressionLevel: ex['progression_level'] ?? '',
        regressionLevel: ex['regression_level'] ?? '',
        imageUrl: ex['image_url'] ?? '',
        gifUrl: ex['gif_url'] ?? '',
        videoUrl: ex['video_url'] ?? '',
        audioCue: ex['audio_cue'] ?? '',
        tags:
            (ex['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                [],
        indoorOutdoor: ex['indoor_outdoor'] ?? '',
        isFavorite: ex['is_favorite'] ?? false,
        isBodyweight: ex['is_bodyweight'] ?? false,
        requiresPartner: ex['requires_partner'] ?? false,
        warmupOrMain: ex['warmup_or_main'] ?? '',
      );
    }).toList();
    for (final e in defaults) {
      await box.add(e);
    }
  }
}
