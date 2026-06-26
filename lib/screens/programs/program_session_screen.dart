import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../models/workout_entry.dart';
import '../../state/workout_state.dart';
import '../../state/program_state.dart';
import '../../state/app_state.dart';
import '../../utils/units.dart';
import 'set_entry_screen.dart';

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

  Map<String, List<WorkoutEntry>> _todayByEx = {};

  ProgramDay get _day => widget.program.days[widget.dayIndex];

  @override
  void initState() {
    super.initState();
    _workoutTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() => _workoutElapsed++) : null);
    _loadUnits();
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
    final totalSets =
        _todayByEx.values.fold(0, (sum, list) => sum + list.length);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finish Session?'),
        content: Text(
            'You logged $totalSets set${totalSets == 1 ? '' : 's'} across ${_todayByEx.keys.length} exercise${_todayByEx.keys.length == 1 ? '' : 's'}.\n\nGreat work! 💪'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Going')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finish')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(activeSessionProvider.notifier).clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(entriesProvider);
    _refreshTodayEntries(allEntries);

    final exercises = _day.exercises;
    final doneCount = exercises.where((ex) {
      final done = _todayByEx[ex.exerciseId]?.length ?? 0;
      return done >= ex.targetSets;
    }).length;
    final progress = exercises.isEmpty ? 0.0 : doneCount / exercises.length;
    final colorScheme = Theme.of(context).colorScheme;

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
      body: Column(
        children: [
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$doneCount of ${exercises.length} exercises done',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: exercises.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                if (idx == exercises.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: _finishSession,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Finish Session'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: doneCount == exercises.length
                            ? Colors.green
                            : colorScheme.primary,
                      ),
                    ),
                  );
                }

                final ex = exercises[idx];
                final doneSets = _todayByEx[ex.exerciseId] ?? [];
                final targetWKg = ex.targetWeightKg;
                final targetWDisplay =
                    targetWKg != null ? UnitsUtil.fromKg(targetWKg, _units) : null;
                final unitLabel = UnitsUtil.unitLabel(_units);
                final allDone = doneSets.length >= ex.targetSets;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: allDone
                        ? Colors.green.withOpacity(0.07)
                        : colorScheme.surface,
                    border: Border.all(
                      color: allDone
                          ? Colors.green.withOpacity(0.4)
                          : colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(ex.exerciseName,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: allDone
                                          ? Colors.green.shade700
                                          : colorScheme.onSurface)),
                            ),
                            if (allDone)
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20)
                            else
                              Text(
                                '${doneSets.length}/${ex.targetSets}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ex.targetSets} sets × ${ex.targetReps} reps'
                          '${targetWDisplay != null ? ' · ${targetWDisplay.toStringAsFixed(1)} $unitLabel' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (ex.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(ex.notes,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey)),
                          ),
                        const SizedBox(height: 10),

                        Row(
                          children: List.generate(
                            math.max(ex.targetSets, doneSets.length),
                            (i) {
                              final done = i < doneSets.length;
                              final isExtra = i >= ex.targetSets;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: done
                                        ? isExtra ? Colors.orange : Colors.green
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: done
                                          ? isExtra ? Colors.orange : Colors.green
                                          : colorScheme.outlineVariant,
                                      width: 2,
                                    ),
                                  ),
                                  child: done
                                      ? Icon(
                                          isExtra ? Icons.add : Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : Center(
                                          child: Text('${i + 1}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurfaceVariant)),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openSetEntry(context, ex, doneSets.length + 1, targetWKg),
                            icon: Icon(allDone ? Icons.add : Icons.play_arrow, size: 18),
                            label: Text(doneSets.isEmpty
                                ? 'Start Set 1'
                                : allDone
                                    ? 'Add Extra Set'
                                    : 'Start Set ${doneSets.length + 1}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allDone
                                  ? Colors.grey.shade600
                                  : colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSetEntry(
    BuildContext context,
    ProgramExercise ex,
    int setNumber,
    double? targetWeightKg,
  ) async {
    final result = await Navigator.push<SetResult>(
      context,
      MaterialPageRoute(
        builder: (_) => SetEntryScreen(
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
