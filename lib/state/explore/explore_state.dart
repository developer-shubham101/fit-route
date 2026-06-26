import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';

final exerciseServiceProvider =
    Provider<ExerciseService>((ref) => ExerciseService());

final exerciseLibraryProvider =
    StateNotifierProvider<ExerciseLibraryNotifier, List<Exercise>>(
        (ref) => ExerciseLibraryNotifier(ref));

class ExerciseLibraryNotifier extends StateNotifier<List<Exercise>> {
  final Ref ref;
  ExerciseLibraryNotifier(this.ref) : super(const []) {
    load();
  }

  Future<void> load() async {
    final svc = ref.read(exerciseServiceProvider);
    state = await svc.getExercises();
  }

  Future<void> add(Exercise exercise) async {
    final svc = ref.read(exerciseServiceProvider);
    await svc.addExercise(exercise);
    await load();
  }

  Future<void> updateById(String id, Exercise exercise) async {
    final svc = ref.read(exerciseServiceProvider);
    await svc.updateById(id, exercise);
    await load();
  }

  Future<void> deleteById(String id) async {
    final svc = ref.read(exerciseServiceProvider);
    await svc.deleteById(id);
    await load();
  }
}

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

class ExploreFilters {
  final String? category; // body part / category
  final String? equipment;
  final String? difficulty;
  final bool? homeOnly;
  final bool? bodyweightOnly;

  const ExploreFilters({
    this.category,
    this.equipment,
    this.difficulty,
    this.homeOnly,
    this.bodyweightOnly,
  });

  ExploreFilters copyWith({
    Object? category = _sentinel,
    Object? equipment = _sentinel,
    Object? difficulty = _sentinel,
    Object? homeOnly = _sentinel,
    Object? bodyweightOnly = _sentinel,
  }) {
    return ExploreFilters(
      category: category == _sentinel ? this.category : category as String?,
      equipment: equipment == _sentinel ? this.equipment : equipment as String?,
      difficulty:
          difficulty == _sentinel ? this.difficulty : difficulty as String?,
      homeOnly: homeOnly == _sentinel ? this.homeOnly : homeOnly as bool?,
      bodyweightOnly: bodyweightOnly == _sentinel
          ? this.bodyweightOnly
          : bodyweightOnly as bool?,
    );
  }
}

const _sentinel = Object();

final exploreFiltersProvider =
    StateNotifierProvider<ExploreFiltersNotifier, ExploreFilters>(
        (ref) => ExploreFiltersNotifier());

class ExploreFiltersNotifier extends StateNotifier<ExploreFilters> {
  ExploreFiltersNotifier() : super(const ExploreFilters());

  void setCategory(String? v) => state = state.copyWith(category: v);
  void setEquipment(String? v) => state = state.copyWith(equipment: v);
  void setDifficulty(String? v) => state = state.copyWith(difficulty: v);
  void setHomeOnly(bool? v) => state = state.copyWith(homeOnly: v);
  void setBodyweightOnly(bool? v) => state = state.copyWith(bodyweightOnly: v);
  void clear() => state = const ExploreFilters();
}

final filteredExerciseLibraryProvider = Provider<List<Exercise>>((ref) {
  final list = ref.watch(exerciseLibraryProvider);
  final q = ref.watch(exerciseSearchQueryProvider);
  final f = ref.watch(exploreFiltersProvider);

  return list.where((e) {
    if (q.isNotEmpty) {
      final qq = q.toLowerCase();
      if (!e.name.toLowerCase().contains(qq) &&
          !e.description.toLowerCase().contains(qq)) return false;
    }
    if (f.category != null &&
        f.category!.isNotEmpty &&
        e.category.toLowerCase() != f.category!.toLowerCase()) return false;
    if (f.equipment != null && f.equipment!.isNotEmpty) {
      final hasEquip = e.equipment
          .any((eq) => eq.toLowerCase() == f.equipment!.toLowerCase());
      if (!hasEquip) return false;
    }
    if (f.difficulty != null &&
        f.difficulty!.isNotEmpty &&
        e.difficulty.toLowerCase() != f.difficulty!.toLowerCase()) return false;
    if (f.homeOnly == true && !e.suitableAtHome) return false;
    if (f.bodyweightOnly == true && !e.isBodyweight) return false;
    return true;
  }).toList();
});
