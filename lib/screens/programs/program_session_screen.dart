import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../models/workout_entry.dart';
import '../../state/workout_state.dart';
import '../../state/app_state.dart';
import '../../utils/units.dart';

class ProgramSessionScreen extends ConsumerStatefulWidget {
  final Program program;
  final int dayIndex;
  const ProgramSessionScreen(
      {required this.program, required this.dayIndex, super.key});

  @override
  ConsumerState<ProgramSessionScreen> createState() =>
      _ProgramSessionScreenState();
}

class _ProgramSessionScreenState extends ConsumerState<ProgramSessionScreen> {
  // workout timer
  Timer? _workoutTimer;
  int _workoutElapsed = 0;

  // rest timer
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _restActive = false;

  // actual sets per exercise: Map<exerciseIndex, List<_ActualSet>>
  late Map<int, List<_ActualSet>> _actualSets;
  String _units = 'metric';

  ProgramDay get _day => widget.program.days[widget.dayIndex];

  @override
  void initState() {
    super.initState();
    _actualSets = {
      for (int i = 0; i < _day.exercises.length; i++)
        i: List.generate(
          _day.exercises[i].targetSets,
          (_) => _ActualSet(),
        ),
    };
    _workoutTimer = Timer.periodic(const Duration(seconds: 1),
        (_) => mounted ? setState(() => _workoutElapsed++) : null);
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
    for (final sets in _actualSets.values) {
      for (final s in sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

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

  Future<void> _saveSet(int exIdx, int setIdx) async {
    final ex = _day.exercises[exIdx];
    final set = _actualSets[exIdx]![setIdx];
    final reps = int.tryParse(set.repsCtrl.text.trim()) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter reps')));
      return;
    }
    double? weightKg;
    final wDisplay = double.tryParse(set.weightCtrl.text.trim());
    if (wDisplay != null && wDisplay > 0) {
      weightKg = UnitsUtil.toKg(wDisplay, _units);
    }

    final entry = WorkoutEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${exIdx}_$setIdx',
      exerciseId: ex.exerciseId,
      exerciseName: ex.exerciseName,
      routineId: widget.program.id,
      type: weightKg != null ? 'External' : 'Bodyweight',
      externalWeight: weightKg,
      reps: reps,
      timestamp: DateTime.now().toUtc(),
      durationSeconds: _workoutElapsed,
    );
    await ref.read(entriesProvider.notifier).addEntry(entry);
    setState(() => set.saved = true);
    _startRest(ex.targetRestSeconds);
  }

  int get _totalSets =>
      _actualSets.values.fold(0, (acc, sets) => acc + sets.length);

  int get _savedSets => _actualSets.values
      .fold(0, (acc, sets) => acc + sets.where((s) => s.saved).length);

  Future<void> _finish() async {
    if (_savedSets == 0) {
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
      await _showSummary();
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showSummary() async {
    final unitLabel = UnitsUtil.unitLabel(_units);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Program: ${widget.program.name}'),
              Text('Day: ${_day.name}'),
              Text('Duration: ${_fmt(_workoutElapsed)}'),
              Text('Sets completed: $_savedSets / $_totalSets'),
              const Divider(),
              for (int i = 0; i < _day.exercises.length; i++) ...[
                Text(_day.exercises[i].exerciseName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                for (int j = 0; j < _actualSets[i]!.length; j++)
                  if (_actualSets[i]![j].saved)
                    Builder(builder: (_) {
                      final set = _actualSets[i]![j];
                      final ex = _day.exercises[i];
                      final actualReps =
                          int.tryParse(set.repsCtrl.text) ?? 0;
                      final actualW =
                          double.tryParse(set.weightCtrl.text);
                      final targetW = ex.targetWeightKg != null
                          ? UnitsUtil.fromKg(ex.targetWeightKg!, _units)
                          : null;
                      final repsOk = actualReps >= ex.targetReps;
                      final wOk = targetW == null ||
                          (actualW != null && actualW >= targetW);
                      return Padding(
                        padding: const EdgeInsets.only(left: 12, top: 2),
                        child: Row(children: [
                          Icon(
                              repsOk && wOk
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 14,
                              color: repsOk && wOk
                                  ? Colors.green
                                  : Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                              'Set ${j + 1}: $actualReps reps'
                              '${actualW != null ? ' @ ${actualW.toStringAsFixed(0)} $unitLabel' : ''}',
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                              '(target: ${ex.targetReps} reps'
                              '${targetW != null ? ' @ ${targetW.toStringAsFixed(0)} $unitLabel' : ''})',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                      );
                    }),
                const SizedBox(height: 4),
              ],
            ],
          ),
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
    final unitLabel = UnitsUtil.unitLabel(_units);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.program.name} · ${_day.name}'),
        actions: [
          if (_restActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_fmt(_restRemaining),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary)),
                  GestureDetector(
                    onTap: _stopRest,
                    child: const Text('skip rest',
                        style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_fmt(_workoutElapsed),
                      style: const TextStyle(fontSize: 16)),
                  const Text('elapsed',
                      style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _day.exercises.length,
        itemBuilder: (context, exIdx) {
          final ex = _day.exercises[exIdx];
          final sets = _actualSets[exIdx]!;
          final allSaved = sets.every((s) => s.saved);
          final targetWDisplay = ex.targetWeightKg != null
              ? UnitsUtil.fromKg(ex.targetWeightKg!, _units)
              : null;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(ex.exerciseName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    if (allSaved)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ]),
                  Text(
                    'Target: ${ex.targetSets} × ${ex.targetReps}'
                    '${targetWDisplay != null ? ' @ ${targetWDisplay.toStringAsFixed(0)} $unitLabel' : ''}  •  Rest: ${ex.targetRestSeconds}s',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (ex.notes.isNotEmpty)
                    Text(ex.notes,
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey)),
                  const SizedBox(height: 8),
                  // sets header
                  Row(children: [
                    const SizedBox(
                        width: 32,
                        child: Text('Set',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Reps (target: ${ex.targetReps})',
                            style: const TextStyle(fontSize: 11))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Weight $unitLabel${targetWDisplay != null ? ' (${targetWDisplay.toStringAsFixed(0)})' : ''}',
                            style: const TextStyle(fontSize: 11))),
                    const SizedBox(width: 48),
                  ]),
                  for (int si = 0; si < sets.length; si++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        SizedBox(
                          width: 32,
                          child: Text('${si + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: sets[si].saved
                                      ? Colors.green
                                      : null)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: sets[si].repsCtrl,
                            keyboardType: TextInputType.number,
                            enabled: !sets[si].saved,
                            decoration: const InputDecoration(
                                isDense: true, hintText: 'reps'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: sets[si].weightCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            enabled: !sets[si].saved,
                            decoration: InputDecoration(
                                isDense: true, hintText: unitLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: sets[si].saved
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20)
                              : ElevatedButton(
                                  onPressed: () => _saveSet(exIdx, si),
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4)),
                                  child: const Text('✓',
                                      style: TextStyle(fontSize: 13)),
                                ),
                        ),
                      ]),
                    ),
                  // add extra set
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => sets.add(_ActualSet())),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add set',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finish,
        icon: const Icon(Icons.done_all),
        label: Text('Finish ($_savedSets/$_totalSets)'),
      ),
    );
  }
}

class _ActualSet {
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  bool saved;

  _ActualSet()
      : repsCtrl = TextEditingController(),
        weightCtrl = TextEditingController(),
        saved = false;

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
}
