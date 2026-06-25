import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/routines_state.dart';
import '../models/exercise.dart';
import '../state/workout_state.dart';
import '../state/app_state.dart';
import 'active_exercise_screen.dart';

class RoutineDetailScreen extends ConsumerWidget {
  final String routineId;
  const RoutineDetailScreen({required this.routineId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);
    final routine = routines.firstWhere((r) => r.id == routineId);

    Future<void> addExerciseDialog() async {
      final nameController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Exercise'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Exercise name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('Add')),
          ],
        ),
      );
      if (result != null && result.trim().isNotEmpty) {
        await ref.read(routinesProvider.notifier).addExerciseToRoutine(
              routineId,
              Exercise(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: result.trim()),
            );
      }
    }

    // Display routine details
    List<Widget> routineDetails = [
      Text(routine.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      if (routine.goal.isNotEmpty)
        Text('Goal: ${routine.goal}',
            style: Theme.of(context).textTheme.bodyMedium),
      if (routine.level.isNotEmpty)
        Text('Level: ${routine.level}',
            style: Theme.of(context).textTheme.bodyMedium),
      if (routine.durationMinutes > 0)
        Text('Duration: ${routine.durationMinutes} min',
            style: Theme.of(context).textTheme.bodyMedium),
      if (routine.equipmentNeeded.isNotEmpty)
        Text('Equipment: ${routine.equipmentNeeded.join(", ")}',
            style: Theme.of(context).textTheme.bodyMedium),
      if (routine.indoorOutdoor.isNotEmpty)
        Text('Location: ${routine.indoorOutdoor.join(", ")}',
            style: Theme.of(context).textTheme.bodyMedium),
      if (routine.tags.isNotEmpty)
        Wrap(
          spacing: 8,
          children: [for (final tag in routine.tags) Chip(label: Text(tag))],
        ),
      const SizedBox(height: 16),
    ];

    Future<void> renameExerciseDialog(Exercise ex) async {
      final nameController = TextEditingController(text: ex.name);
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename Exercise'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Exercise name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('Save')),
          ],
        ),
      );
      if (result != null && result.trim().isNotEmpty) {
        await ref
            .read(routinesProvider.notifier)
            .renameExercise(routineId, ex.id, result.trim());
      }
    }

    Future<void> confirmDeleteExercise(Exercise ex) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete exercise?'),
          content: Text('Delete "${ex.name}" from this routine?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (confirmed == true) {
        await ref
            .read(routinesProvider.notifier)
            .removeExerciseFromRoutine(routineId, ex.id);
      }
    }

    void openExerciseSetup(Exercise exercise) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) =>
            ExerciseSetupSheet(exercise: exercise, routineId: routineId),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(routine.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...routineDetails,
            const Text('Exercises',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (routine.exercises.isEmpty)
              const Text('No exercises yet. Tap + to add one.')
            else
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: routine.exercises.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(routinesProvider.notifier)
                        .reorderExercises(routineId, oldIndex, newIndex);
                  },
                  itemBuilder: (context, idx) {
                    final ex = routine.exercises[idx];
                    return ListTile(
                      key: ValueKey(ex.id),
                      title: Text(ex.name),
                      onTap: () => openExerciseSetup(ex),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') {
                            renameExerciseDialog(ex);
                          } else if (value == 'delete') {
                            confirmDeleteExercise(ex);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addExerciseDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Exercise',
      ),
    );
  }
}

// ExerciseSetupSheet remains below (unchanged except earlier polish edits)
class ExerciseSetupSheet extends ConsumerStatefulWidget {
  final Exercise exercise;
  final String routineId;
  const ExerciseSetupSheet(
      {required this.exercise, required this.routineId, super.key});

  @override
  ConsumerState<ExerciseSetupSheet> createState() => _ExerciseSetupSheetState();
}

class _ExerciseSetupSheetState extends ConsumerState<ExerciseSetupSheet> {
  String _type = 'Bodyweight';
  final _weightController = TextEditingController();
  String _units = 'metric'; // metric=kg, imperial=lb
  bool _loading = true;

  List<double> get _presetsKg => [5, 10, 15, 20, 25, 30, 40];
  List<double> get _presetsLb => [5, 10, 15, 20, 25, 35, 45];
  List<double> get _presets => _units == 'metric' ? _presetsKg : _presetsLb;
  String get _unitLabel => _units == 'metric' ? 'kg' : 'lb';

  @override
  void initState() {
    super.initState();
    _type = widget.exercise.defaultType;
    _load();
  }

  Future<void> _load() async {
    final units = await ref.read(prefsServiceProvider).getDefaultUnits();
    double? last = await ref
        .read(lastUsedServiceProvider)
        .getLastExternalWeight(widget.exercise.id, units);
    setState(() {
      _units = units;
      if (last != null) _weightController.text = last.toStringAsFixed(0);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: SizedBox(
            height: 80, child: Center(child: CircularProgressIndicator())),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exercise.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(
                        value: 'Bodyweight', child: Text('Bodyweight')),
                    DropdownMenuItem(
                        value: 'External', child: Text('External weight')),
                  ],
                  onChanged: (v) =>
                      setState(() => _type = v ?? widget.exercise.defaultType),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ),
              const SizedBox(width: 12),
              if (_type == 'External')
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration:
                        InputDecoration(labelText: 'Weight (${_unitLabel})'),
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          if (_type == 'External') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final w in _presets)
                  ActionChip(
                    label: Text('${w.toStringAsFixed(0)} ${_unitLabel}'),
                    onPressed: () {
                      _weightController.text = w.toStringAsFixed(0);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final extWeight = _type == 'External'
                      ? double.tryParse(_weightController.text)
                      : null;
                  if (_type == 'External' &&
                      (extWeight == null || extWeight <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Enter a valid weight in ${_unitLabel}')));
                    return;
                  }
                  if (_type == 'External' && extWeight != null) {
                    await ref
                        .read(lastUsedServiceProvider)
                        .setLastExternalWeight(
                            widget.exercise.id, _units, extWeight);
                  }
                  ref.read(activeWorkoutProvider.notifier).state =
                      ActiveWorkoutState(
                    routineId: widget.routineId,
                    exerciseId: widget.exercise.id,
                    exerciseName: widget.exercise.name,
                    type: _type,
                    externalWeight: extWeight,
                    startedAt: DateTime.now().toUtc(),
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ActiveExerciseScreen()));
                },
                child: const Text('Start'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
