import 'package:hive/hive.dart';
import '../models/program.dart';

class ProgramService {
  static const String boxName = 'programs';

  Future<List<Program>> getAll() async {
    final box = await Hive.openBox<Program>(boxName);
    return box.values.toList();
  }

  Future<void> add(Program program) async {
    final box = await Hive.openBox<Program>(boxName);
    await box.add(program);
  }

  Future<void> updateAt(int index, Program program) async {
    final box = await Hive.openBox<Program>(boxName);
    await box.putAt(index, program);
  }

  Future<void> deleteAt(int index) async {
    final box = await Hive.openBox<Program>(boxName);
    await box.deleteAt(index);
  }

  Future<int?> indexById(String id) async {
    final box = await Hive.openBox<Program>(boxName);
    for (int i = 0; i < box.length; i++) {
      if (box.getAt(i)?.id == id) return i;
    }
    return null;
  }

  Future<void> updateById(String id, Program program) async {
    final idx = await indexById(id);
    if (idx == null) return;
    await updateAt(idx, program);
  }

  Future<void> deleteById(String id) async {
    final idx = await indexById(id);
    if (idx == null) return;
    await deleteAt(idx);
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<Program>(boxName);
    await box.clear();
  }
}
