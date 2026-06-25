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
    await svc.seedDefaultsIfEmpty();
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

final filteredExerciseLibraryProvider = Provider<List<Exercise>>((ref) {
  final list = ref.watch(exerciseLibraryProvider);
  final q = ref.watch(exerciseSearchQueryProvider);
  if (q.isEmpty) return list;
  final qq = q.toLowerCase();
  return list
      .where((e) =>
          e.name.toLowerCase().contains(qq) ||
          e.description.toLowerCase().contains(qq))
      .toList();
});
