import 'package:hive/hive.dart';
import '../models/routine.dart';

class RoutineService {
  static const String boxName = 'routines';

  Future<List<Routine>> getRoutines() async {
    final box = await Hive.openBox<Routine>(boxName);
    return box.values.toList();
  }

  Future<void> addRoutine(Routine routine) async {
    final box = await Hive.openBox<Routine>(boxName);
    await box.add(routine);
  }

  Future<void> updateRoutine(int index, Routine routine) async {
    final box = await Hive.openBox<Routine>(boxName);
    await box.putAt(index, routine);
  }

  Future<void> deleteRoutine(int index) async {
    final box = await Hive.openBox<Routine>(boxName);
    await box.deleteAt(index);
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<Routine>(boxName);
    await box.clear();
  }
}
