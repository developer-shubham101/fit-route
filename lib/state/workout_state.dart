import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_entry.dart';
import '../services/workout_entry_service.dart';

final workoutEntryServiceProvider =
    Provider<WorkoutEntryService>((ref) => WorkoutEntryService());

final entriesProvider =
    StateNotifierProvider<WorkoutEntriesNotifier, List<WorkoutEntry>>(
        (ref) => WorkoutEntriesNotifier(ref));

class WorkoutEntriesNotifier extends StateNotifier<List<WorkoutEntry>> {
  final Ref ref;
  WorkoutEntriesNotifier(this.ref) : super(const []) {
    load();
  }

  Future<void> load() async {
    final service = ref.read(workoutEntryServiceProvider);
    state = await service.getEntries();
  }

  Future<int> addEntry(WorkoutEntry entry) async {
    final service = ref.read(workoutEntryServiceProvider);
    final idx = await service.addEntry(entry);
    await load();
    return idx;
  }

  Future<void> deleteEntryAt(int index) async {
    final service = ref.read(workoutEntryServiceProvider);
    await service.deleteEntryAt(index);
    await load();
  }

  Future<int?> findIndexById(String id) async {
    final service = ref.read(workoutEntryServiceProvider);
    return service.findIndexById(id);
  }

  Future<void> updateEntryById(String id, WorkoutEntry updated) async {
    final service = ref.read(workoutEntryServiceProvider);
    await service.updateEntryById(id, updated);
    await load();
  }

  Future<void> deleteEntryById(String id) async {
    final service = ref.read(workoutEntryServiceProvider);
    await service.deleteEntryById(id);
    await load();
  }
}
