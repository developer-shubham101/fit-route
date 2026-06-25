import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/program.dart';
import '../services/program_service.dart';

final programServiceProvider =
    Provider<ProgramService>((ref) => ProgramService());

final programsProvider =
    StateNotifierProvider<ProgramsNotifier, List<Program>>(
        (ref) => ProgramsNotifier(ref));

class ProgramsNotifier extends StateNotifier<List<Program>> {
  final Ref ref;
  ProgramsNotifier(this.ref) : super(const []) {
    load();
  }

  Future<void> load() async {
    state = await ref.read(programServiceProvider).getAll();
  }

  Future<void> add(Program p) async {
    await ref.read(programServiceProvider).add(p);
    await load();
  }

  Future<void> updateById(String id, Program p) async {
    await ref.read(programServiceProvider).updateById(id, p);
    await load();
  }

  Future<void> deleteById(String id) async {
    await ref.read(programServiceProvider).deleteById(id);
    await load();
  }

  Future<void> clearAll() async {
    await ref.read(programServiceProvider).clearAll();
    await load();
  }
}

final programSearchProvider = StateProvider<String>((ref) => '');

final filteredProgramsProvider = Provider<List<Program>>((ref) {
  final list = ref.watch(programsProvider);
  final q = ref.watch(programSearchProvider).toLowerCase();
  if (q.isEmpty) return list;
  return list
      .where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.type.toLowerCase().contains(q))
      .toList();
});
