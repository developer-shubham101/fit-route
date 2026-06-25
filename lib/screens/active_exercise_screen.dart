import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/workout_state.dart';
import '../models/workout_entry.dart';

class ActiveExerciseScreen extends ConsumerStatefulWidget {
  const ActiveExerciseScreen({super.key});

  @override
  ConsumerState<ActiveExerciseScreen> createState() =>
      _ActiveExerciseScreenState();
}

class _ActiveExerciseScreenState extends ConsumerState<ActiveExerciseScreen> {
  Timer? _timer;
  int _elapsed = 0; // seconds

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _finishAndSave() async {
    final active = ref.read(activeWorkoutProvider);
    if (active == null) return;
    final repsController = TextEditingController();
    final reps = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter reps'),
        content: TextField(
          controller: repsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Reps'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(repsController.text)),
              child: const Text('Save')),
        ],
      ),
    );
    if (reps == null || reps <= 0) return;

    final entry = WorkoutEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: active.exerciseId,
      exerciseName: active.exerciseName,
      routineId: active.routineId,
      type: active.type,
      externalWeight: active.externalWeight,
      reps: reps,
      timestamp: DateTime.now().toUtc(),
      durationSeconds: _elapsed,
    );

    final idx = await ref.read(entriesProvider.notifier).addEntry(entry);
    ref.read(activeWorkoutProvider.notifier).state = null;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry saved'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ref.read(entriesProvider.notifier).deleteEntryAt(idx);
          },
        ),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);
    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Exercise')),
        body: const Center(child: Text('No active exercise')),
      );
    }

    String formatDuration(int seconds) {
      final m = (seconds ~/ 60).toString().padLeft(2, '0');
      final s = (seconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Scaffold(
      appBar: AppBar(title: Text(active.exerciseName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Type: ${active.type}${active.externalWeight != null ? ' @ ${active.externalWeight}kg' : ''}'),
            const SizedBox(height: 12),
            Text('Elapsed: ${formatDuration(_elapsed)}',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _finishAndSave,
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}
