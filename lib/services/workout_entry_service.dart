import 'package:hive/hive.dart';
import '../models/workout_entry.dart';

class WorkoutEntryService {
  static const String boxName = 'workout_entries';

  Future<List<WorkoutEntry>> getEntries() async {
    final box = await Hive.openBox<WorkoutEntry>(boxName);
    return box.values.toList();
  }

  Future<int> addEntry(WorkoutEntry entry) async {
    final box = await Hive.openBox<WorkoutEntry>(boxName);
    final index = await box.add(entry);
    return index;
  }

  Future<void> updateEntry(int index, WorkoutEntry entry) async {
    final box = await Hive.openBox<WorkoutEntry>(boxName);
    await box.putAt(index, entry);
  }

  Future<void> deleteEntryAt(int index) async {
    final box = await Hive.openBox<WorkoutEntry>(boxName);
    await box.deleteAt(index);
  }

  Future<int?> findIndexById(String id) async {
    final box = await Hive.openBox<WorkoutEntry>(boxName);
    for (int i = 0; i < box.length; i++) {
      final e = box.getAt(i);
      if (e != null && e.id == id) return i;
    }
    return null;
  }

  Future<void> updateEntryById(String id, WorkoutEntry updated) async {
    final idx = await findIndexById(id);
    if (idx == null) return;
    await updateEntry(idx, updated);
  }

  Future<void> deleteEntryById(String id) async {
    final idx = await findIndexById(id);
    if (idx == null) return;
    await deleteEntryAt(idx);
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<WorkoutEntry>(boxName);
    await box.clear();
  }
}
