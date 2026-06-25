import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/workout_state.dart';
import '../state/app_state.dart';
import '../models/workout_entry.dart';
import '../utils/units.dart';

// ─── per-set data (in-memory only during session) ───────────────────────────
class _SetRow {
  final TextEditingController reps;
  final TextEditingController weight;
  bool saved;
  _SetRow({String repsVal = '', String weightVal = ''})
      : reps = TextEditingController(text: repsVal),
        weight = TextEditingController(text: weightVal),
        saved = false;
  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

class ActiveExerciseScreen extends ConsumerStatefulWidget {
  const ActiveExerciseScreen({super.key});

  @override
  ConsumerState<ActiveExerciseScreen> createState() =>
      _ActiveExerciseScreenState();
}

class _ActiveExerciseScreenState extends ConsumerState<ActiveExerciseScreen> {
  // ── workout timer ──
  Timer? _workoutTimer;
  int _workoutElapsed = 0;

  // ── rest timer ──
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _restActive = false;

  // ── sets ──
  final List<_SetRow> _sets = [];

  // ── notes ──
  final _workoutNotesCtrl = TextEditingController();
  final _exerciseNotesCtrl = TextEditingController();

  String _units = 'metric';

  @override
  void initState() {
    super.initState();
    _sets.add(_SetRow());
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _workoutElapsed++);
    });
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final u = await ref.read(prefsServiceProvider).getDefaultUnits();
    if (mounted) setState(() => _units = u);
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    for (final s in _sets) {
      s.dispose();
    }
    _workoutNotesCtrl.dispose();
    _exerciseNotesCtrl.dispose();
    super.dispose();
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restActive = true;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        if (mounted) setState(() => _restActive = false);
      } else {
        if (mounted) setState(() => _restRemaining--);
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    setState(() => _restActive = false);
  }

  Future<void> _saveSet(int idx) async {
    final active = ref.read(activeWorkoutProvider);
    if (active == null) return;
    final row = _sets[idx];
    final reps = int.tryParse(row.reps.text.trim()) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter reps')));
      return;
    }
    double? weightKg;
    final wDisplay = double.tryParse(row.weight.text.trim());
    if (active.type == 'External') {
      if (wDisplay == null || wDisplay <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enter weight (${UnitsUtil.unitLabel(_units)})')));
        return;
      }
      weightKg = UnitsUtil.toKg(wDisplay, _units);
    }

    final entry = WorkoutEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_$idx',
      exerciseId: active.exerciseId,
      exerciseName: active.exerciseName,
      routineId: active.routineId,
      type: active.type,
      externalWeight: weightKg,
      reps: reps,
      timestamp: DateTime.now().toUtc(),
      durationSeconds: _workoutElapsed,
    );
    await ref.read(entriesProvider.notifier).addEntry(entry);
    setState(() => row.saved = true);
    _startRest(active.restSeconds);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Set saved ✓')));
  }

  Future<void> _finish() async {
    final saved = _sets.where((s) => s.saved).length;
    if (saved == 0) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No sets saved'),
          content: const Text('Finish without saving any sets?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard')),
          ],
        ),
      );
      if (go != true) return;
    } else {
      await _showSummary(saved);
    }
    ref.read(activeWorkoutProvider.notifier).state = null;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showSummary(int savedSets) async {
    final active = ref.read(activeWorkoutProvider)!;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Workout Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exercise: ${active.exerciseName}'),
            Text('Sets saved: $savedSets'),
            Text('Duration: ${_fmt(_workoutElapsed)}'),
            if (_workoutNotesCtrl.text.trim().isNotEmpty)
              Text('Notes: ${_workoutNotesCtrl.text.trim()}'),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
        ],
      ),
    );
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

    final unitLabel = UnitsUtil.unitLabel(_units);

    return Scaffold(
      appBar: AppBar(
        title: Text(active.exerciseName),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).state = null;
              Navigator.pop(context);
            },
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── workout timer + rest timer ──
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Workout', style: TextStyle(fontSize: 11)),
                  Text(_fmt(_workoutElapsed),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
                if (_restActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Rest', style: TextStyle(fontSize: 11)),
                      Text(_fmt(_restRemaining),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                      TextButton(
                          onPressed: _stopRest,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Skip rest',
                              style: TextStyle(fontSize: 11))),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          active.type == 'External' &&
                                  active.externalWeight != null
                              ? '${active.type} · ${UnitsUtil.formatWeight(active.externalWeight, _units)}'
                              : active.type,
                          style: const TextStyle(fontSize: 12)),
                      TextButton(
                        onPressed: () => _startRest(active.restSeconds),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Start rest',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // ── sets list ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // sets table header
                Row(children: [
                  const SizedBox(width: 36, child: Text('Set', style: TextStyle(fontSize: 12))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Reps',
                          style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 8),
                  if (active.type == 'External')
                    Expanded(
                        child: Text('Weight ($unitLabel)',
                            style: const TextStyle(fontSize: 12))),
                  if (active.type == 'External') const SizedBox(width: 8),
                  const SizedBox(width: 56),
                ]),
                const Divider(),
                for (int i = 0; i < _sets.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _sets[i].saved
                                      ? Theme.of(context).colorScheme.primary
                                      : null)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _sets[i].reps,
                            keyboardType: TextInputType.number,
                            enabled: !_sets[i].saved,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Reps',
                              suffixIcon: _sets[i].saved
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.green)
                                  : null,
                            ),
                          ),
                        ),
                        if (active.type == 'External') ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _sets[i].weight,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              enabled: !_sets[i].saved,
                              decoration: InputDecoration(
                                  isDense: true, hintText: unitLabel),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: _sets[i].saved
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _saveSet(i),
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6)),
                                  child: const Text('Save',
                                      style: TextStyle(fontSize: 12)),
                                ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        // Pre-fill weight from last set
                        final lastWeight = _sets.isNotEmpty
                            ? _sets.last.weight.text
                            : '';
                        _sets.add(_SetRow(weightVal: lastWeight));
                      }),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add set'),
                    ),
                    const SizedBox(width: 8),
                    if (_sets.length > 1)
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          final last = _sets.removeLast();
                          last.dispose();
                        }),
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Remove last'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── notes ──
                TextField(
                  controller: _exerciseNotesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Exercise notes', isDense: true),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _workoutNotesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Workout notes', isDense: true),
                  maxLines: 2,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finish,
        icon: const Icon(Icons.done_all),
        label: const Text('Finish'),
      ),
    );
  }
}
