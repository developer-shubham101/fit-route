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

// ── Filter state ──────────────────────────────────────────────────────────────
class ProgramFilters {
  final String query;
  final String? type;
  final String? goal;
  final String? level;
  final String? equipment;
  final String? location;

  const ProgramFilters({
    this.query = '',
    this.type,
    this.goal,
    this.level,
    this.equipment,
    this.location,
  });

  ProgramFilters copyWith({
    String? query,
    Object? type = _s,
    Object? goal = _s,
    Object? level = _s,
    Object? equipment = _s,
    Object? location = _s,
  }) =>
      ProgramFilters(
        query: query ?? this.query,
        type: type == _s ? this.type : type as String?,
        goal: goal == _s ? this.goal : goal as String?,
        level: level == _s ? this.level : level as String?,
        equipment: equipment == _s ? this.equipment : equipment as String?,
        location: location == _s ? this.location : location as String?,
      );

  bool get isEmpty =>
      query.isEmpty &&
      type == null &&
      goal == null &&
      level == null &&
      equipment == null &&
      location == null;
}

const _s = Object();

final programFiltersProvider =
    StateNotifierProvider<ProgramFiltersNotifier, ProgramFilters>(
        (ref) => ProgramFiltersNotifier());

class ProgramFiltersNotifier extends StateNotifier<ProgramFilters> {
  ProgramFiltersNotifier() : super(const ProgramFilters());

  void setQuery(String v) => state = state.copyWith(query: v);
  void setType(String? v) => state = state.copyWith(type: v);
  void setGoal(String? v) => state = state.copyWith(goal: v);
  void setLevel(String? v) => state = state.copyWith(level: v);
  void setEquipment(String? v) => state = state.copyWith(equipment: v);
  void setLocation(String? v) => state = state.copyWith(location: v);
  void clear() => state = const ProgramFilters();
}

// ── Active program ───────────────────────────────────────────────────────────
final activeProgramIdProvider =
    StateNotifierProvider<ActiveProgramNotifier, String?>(
        (ref) => ActiveProgramNotifier(ref));

class ActiveProgramNotifier extends StateNotifier<String?> {
  final Ref ref;
  ActiveProgramNotifier(this.ref) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await ref.read(prefsServiceProvider).getActiveProgramId();
  }

  Future<void> setActive(String? id) async {
    await ref.read(prefsServiceProvider).setActiveProgramId(id);
    state = id;
  }
}

final activeProgramProvider = Provider<Program?>((ref) {
  final id = ref.watch(activeProgramIdProvider);
  if (id == null) return null;
  final programs = ref.watch(programsProvider);
  try {
    return programs.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

// keep legacy provider used by trends_screen
final programSearchProvider = StateProvider<String>((ref) => '');

final filteredProgramsProvider = Provider<List<Program>>((ref) {
  final list = ref.watch(programsProvider);
  final f = ref.watch(programFiltersProvider);

  return list.where((p) {
    if (f.query.isNotEmpty) {
      final q = f.query.toLowerCase();
      if (!p.name.toLowerCase().contains(q) &&
          !p.type.toLowerCase().contains(q) &&
          !p.goal.toLowerCase().contains(q)) return false;
    }
    if (f.type != null && p.type != f.type) return false;
    if (f.goal != null && p.goal != f.goal) return false;
    if (f.level != null && p.level != f.level) return false;
    if (f.equipment != null &&
        !p.equipmentNeeded.contains(f.equipment)) return false;
    if (f.location != null &&
        !p.location.contains(f.location)) return false;
    return true;
  }).toList();
});
