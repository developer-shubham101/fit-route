import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../models/workout_entry.dart';
import '../../state/workout_state.dart';
import '../../state/program_state.dart';
import '../../state/app_state.dart';
import '../../utils/units.dart';

// ── Weight presets (kg) ───────────────────────────────────────────────────────
const _weightSteps = [
  0.0, 2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 22.5, 25.0,
  27.5, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 70.0, 80.0, 90.0, 100.0,
];

double _prevWeight(double kg) {
  for (int i = _weightSteps.length - 1; i >= 0; i--) {
    if (_weightSteps[i] < kg - 0.01) return _weightSteps[i];
  }
  return 0.0;
}

double _nextWeight(double kg) {
  for (final w in _weightSteps) {
    if (w > kg + 0.01) return w;
  }
  return kg + 2.5;
}

// ── Main session screen ───────────────────────────────────────────────────────
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
  Timer? _workoutTimer;
  int _workoutElapsed = 0;
  String _units = 'metric';

  // today's logged entries keyed by exerciseId
  Map<String, List<WorkoutEntry>> _todayByEx = {};

  ProgramDay get _day => widget.program.days[widget.dayIndex];

  @override
  void initState() {
    super.initState();
    _workoutTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() => _workoutElapsed++) : null);
    _loadUnits();
    // persist session so dashboard can resume
    ref
        .read(activeSessionProvider.notifier)
        .start(widget.program.id, widget.dayIndex);
  }

  Future<void> _loadUnits() async {
    final u = await ref.read(prefsServiceProvider).getDefaultUnits();
    if (mounted) setState(() => _units = u);
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _refreshTodayEntries(List<WorkoutEntry> all) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final programId = widget.program.id;
    _todayByEx = {};
    for (final e in all) {
      final t = e.timestamp.toLocal();
      if (e.routineId == programId && !t.isBefore(start) && t.isBefore(end)) {
        _todayByEx.putIfAbsent(e.exerciseId, () => []).add(e);
      }
    }
  }

  Future<void> _finishSession() async {
    await ref.read(activeSessionProvider.notifier).clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(entriesProvider);
    _refreshTodayEntries(allEntries);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.program.name} · ${_day.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_fmt(_workoutElapsed),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('elapsed',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _day.exercises.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, idx) {
          if (idx == _day.exercises.length) {
            // finish button at bottom
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton.icon(
                onPressed: _finishSession,
                icon: const Icon(Icons.done_all),
                label: const Text('Finish Session'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            );
          }
          final ex = _day.exercises[idx];
          final doneSets = _todayByEx[ex.exerciseId] ?? [];
          final targetWKg = ex.targetWeightKg;
          final targetWDisplay = targetWKg != null
              ? UnitsUtil.fromKg(targetWKg, _units)
              : null;
          final unitLabel = UnitsUtil.unitLabel(_units);
          final allDone = doneSets.length >= ex.targetSets;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── exercise header ──
                  Row(
                    children: [
                      Expanded(
                        child: Text(ex.exerciseName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (allDone)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target: ${ex.targetSets} sets × ${ex.targetReps} reps'
                    '${targetWDisplay != null ? ' @ ${targetWDisplay.toStringAsFixed(1)} $unitLabel' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (ex.notes.isNotEmpty)
                    Text(ex.notes,
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey)),
                  const SizedBox(height: 8),
                  // ── completed sets for today ──
                  if (doneSets.isNotEmpty) ...[
                    const Text('Completed today:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: doneSets.asMap().entries.map((e) {
                        final s = e.value;
                        final w = s.externalWeight != null
                            ? UnitsUtil.fromKg(s.externalWeight!, _units)
                            : null;
                        return Chip(
                          label: Text(
                            'Set ${e.key + 1}: ${s.reps} reps'
                            '${w != null ? ' @ ${w.toStringAsFixed(1)} $unitLabel' : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.green.withOpacity(0.15),
                          side: const BorderSide(color: Colors.green),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // ── start set button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openSetEntry(
                        context,
                        ex,
                        doneSets.length + 1,
                        targetWKg,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(doneSets.isEmpty
                          ? 'Start Set 1'
                          : allDone
                              ? 'Add Extra Set'
                              : 'Start Set ${doneSets.length + 1}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allDone
                            ? Colors.grey.shade600
                            : Theme.of(context).colorScheme.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSetEntry(
    BuildContext context,
    ProgramExercise ex,
    int setNumber,
    double? targetWeightKg,
  ) async {
    final result = await Navigator.push<_SetResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _SetEntryScreen(
          exerciseName: ex.exerciseName,
          setNumber: setNumber,
          targetReps: ex.targetReps,
          targetWeightKg: targetWeightKg,
          restSeconds: ex.targetRestSeconds,
          units: _units,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final entry = WorkoutEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${ex.exerciseId}_$setNumber',
      exerciseId: ex.exerciseId,
      exerciseName: ex.exerciseName,
      routineId: widget.program.id,
      type: result.weightKg != null ? 'External' : 'Bodyweight',
      externalWeight: result.weightKg,
      reps: result.reps,
      timestamp: DateTime.now().toUtc(),
      durationSeconds: result.durationSeconds,
    );
    await ref.read(entriesProvider.notifier).addEntry(entry);
  }
}

// ── Set entry screen (timer + stepper UX) ────────────────────────────────────
class _SetResult {
  final int reps;
  final double? weightKg;
  final int durationSeconds;
  const _SetResult(this.reps, this.weightKg, this.durationSeconds);
}

class _SetEntryScreen extends StatefulWidget {
  final String exerciseName;
  final int setNumber;
  final int targetReps;
  final double? targetWeightKg;
  final int restSeconds;
  final String units;

  const _SetEntryScreen({
    required this.exerciseName,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeightKg,
    required this.restSeconds,
    required this.units,
  });

  @override
  State<_SetEntryScreen> createState() => _SetEntryScreenState();
}

class _SetEntryScreenState extends State<_SetEntryScreen> {
  Timer? _setTimer;
  Timer? _restTimer;
  int _elapsed = 0;
  int _restRemaining = 0;

  bool _started = false;
  bool _finished = false;
  bool _resting = false;

  late int _reps;
  late double _weightKg;

  String get _unitLabel => UnitsUtil.unitLabel(widget.units);

  @override
  void initState() {
    super.initState();
    _reps = widget.targetReps;
    _weightKg = widget.targetWeightKg ?? 0.0;
  }

  @override
  void dispose() {
    _setTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _startSet() {
    setState(() => _started = true);
    _setTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() => _elapsed++) : null);
  }

  void _endSet() {
    _setTimer?.cancel();
    setState(() => _finished = true);
  }

  void _startRest() {
    setState(() {
      _resting = true;
      _restRemaining = widget.restSeconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        if (mounted) setState(() => _resting = false);
      } else {
        if (mounted) setState(() => _restRemaining--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _resting = false);
  }

  void _submit() {
    final wKg = _weightKg > 0 ? _weightKg : null;
    Navigator.pop(context, _SetResult(_reps, wKg, _elapsed));
  }

  Widget _stepperButton({
    required String label,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required String value,
  }) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleBtn(icon: Icons.remove, onTap: onMinus),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _editValue(label),
              child: Container(
                constraints: const BoxConstraints(minWidth: 80),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            _CircleBtn(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
    );
  }

  Future<void> _editValue(String label) async {
    final isReps = label.toLowerCase().contains('rep');
    final ctrl = TextEditingController(
        text: isReps
            ? '$_reps'
            : UnitsUtil.fromKg(_weightKg, widget.units)
                .toStringAsFixed(1));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
              labelText: label, suffixText: isReps ? '' : _unitLabel),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (isReps) {
                  final v = int.tryParse(ctrl.text);
                  if (v != null && v > 0) setState(() => _reps = v);
                } else {
                  final v = double.tryParse(ctrl.text);
                  if (v != null && v >= 0) {
                    setState(
                        () => _weightKg = UnitsUtil.toKg(v, widget.units));
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Set')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wDisplay = UnitsUtil.fromKg(_weightKg, widget.units);
    final wLabel = _weightKg > 0
        ? '${wDisplay.toStringAsFixed(1)} $_unitLabel'
        : 'Bodyweight';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} — Set ${widget.setNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── timer ──
            Center(
              child: Column(
                children: [
                  Text(
                    _fmt(_elapsed),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _started && !_finished
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _started
                        ? _finished
                            ? 'Set done'
                            : 'In progress…'
                        : 'Tap Start to begin',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── start / end button ──
            if (!_finished)
              ElevatedButton.icon(
                onPressed: _started ? _endSet : _startSet,
                icon: Icon(_started ? Icons.stop : Icons.play_arrow),
                label: Text(_started ? 'End Set' : 'Start Set'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _started
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                ),
              ),

            const SizedBox(height: 32),

            // ── steppers (reps + weight) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stepperButton(
                  label: 'Reps',
                  onMinus: () =>
                      setState(() => _reps = (_reps - 1).clamp(1, 999)),
                  onPlus: () => setState(() => _reps++),
                  value: '$_reps',
                ),
                _stepperButton(
                  label: 'Weight ($_unitLabel)',
                  onMinus: () => setState(
                      () => _weightKg = _prevWeight(_weightKg)),
                  onPlus: () =>
                      setState(() => _weightKg = _nextWeight(_weightKg)),
                  value: wLabel,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── rest timer ──
            if (_finished && widget.restSeconds > 0) ...[
              if (_resting)
                Column(
                  children: [
                    Text('Rest: ${_fmt(_restRemaining)}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    TextButton(
                        onPressed: _skipRest,
                        child: const Text('Skip rest')),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _startRest,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text('Rest ${widget.restSeconds}s'),
                ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // ── submit ──
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: Text(
                  'Submit — $_reps reps  ${_weightKg > 0 ? '@ $wLabel' : '(bodyweight)'}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Icon(icon,
            size: 20, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
