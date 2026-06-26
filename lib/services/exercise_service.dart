import 'package:hive/hive.dart';
import '../models/exercise.dart';

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
}
