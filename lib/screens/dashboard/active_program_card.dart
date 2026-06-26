import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../models/workout_entry.dart';
import '../../state/program_state.dart';
import '../../utils/units.dart';
import '../programs/program_session_screen.dart';

class ActiveProgramCard extends ConsumerWidget {
  final Program? activeProgram;
  final ActiveSession? activeSession;
  final List<Program> programs;
  final List<WorkoutEntry> allEntries;
  final String units;
  final VoidCallback onChangeProgram;

  const ActiveProgramCard({
    required this.activeProgram,
    required this.activeSession,
    required this.programs,
    required this.allEntries,
    required this.units,
    required this.onChangeProgram,
    super.key,
  });

  Map<String, List<WorkoutEntry>> _todayByEx(String programId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final map = <String, List<WorkoutEntry>>{};
    for (final e in allEntries) {
      final t = e.timestamp.toLocal();
      if (e.routineId == programId && !t.isBefore(start) && t.isBefore(end)) {
        map.putIfAbsent(e.exerciseId, () => []).add(e);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    if (activeProgram == null && activeSession == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_month),
          title: const Text('No active program selected'),
          subtitle: const Text('Go to Programs to select one'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: onChangeProgram,
        ),
      );
    }

    final program = activeSession != null
        ? programs.cast<Program?>().firstWhere(
            (p) => p?.id == activeSession!.programId,
            orElse: () => activeProgram)
        : activeProgram;

    if (program == null) return const SizedBox.shrink();

    final dayIdx = activeSession != null
        ? activeSession!.dayIndex.clamp(0, program.days.length - 1)
        : 0;
    final day = program.days.isNotEmpty ? program.days[dayIdx] : null;
    final exercises = day?.exercises ?? [];
    final todayByEx = _todayByEx(program.id);

    int nextExIdx = 0;
    for (int i = 0; i < exercises.length; i++) {
      final done = todayByEx[exercises[i].exerciseId]?.length ?? 0;
      if (done < exercises[i].targetSets) {
        nextExIdx = i;
        break;
      }
      nextExIdx = i;
    }
    final nextEx = exercises.isNotEmpty ? exercises[nextExIdx] : null;
    final doneCount = exercises
        .where((ex) => (todayByEx[ex.exerciseId]?.length ?? 0) >= ex.targetSets)
        .length;
    final progress = exercises.isEmpty ? 0.0 : doneCount / exercises.length;
    final isActive = activeSession != null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header ──
            Row(
              children: [
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: colorScheme.onPrimary),
                        const SizedBox(width: 4),
                        Text('IN PROGRESS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary)),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(program.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                if (!isActive)
                  TextButton(
                    onPressed: onChangeProgram,
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Change'),
                  ),
              ],
            ),

            if (day != null) ...[
              const SizedBox(height: 2),
              Text(day.name,
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500)),
            ],

            // ── meta chips (only when not active) ──
            if (!isActive &&
                (program.goal.isNotEmpty ||
                    program.level.isNotEmpty ||
                    program.durationMinutes > 0)) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                if (program.goal.isNotEmpty) _MiniChip('🎯 ${program.goal}'),
                if (program.level.isNotEmpty) _MiniChip('📶 ${program.level}'),
                if (program.durationMinutes > 0)
                  _MiniChip('⏱ ${program.durationMinutes} min'),
              ]),
            ],

            const SizedBox(height: 10),

            // ── progress bar ──
            if (exercises.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$doneCount / ${exercises.length} exercises',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${(progress * 100).round()}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── exercise list ──
            if (exercises.isNotEmpty) ...[
              ...exercises.take(4).map((ex) {
                final doneSets = todayByEx[ex.exerciseId]?.length ?? 0;
                final allDone = doneSets >= ex.targetSets;
                final isCurrent = isActive && ex == nextEx && !allDone;
                final wDisplay = ex.targetWeightKg != null
                    ? UnitsUtil.fromKg(ex.targetWeightKg!, units)
                    : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        allDone
                            ? Icons.check_circle
                            : isCurrent
                                ? Icons.play_circle
                                : Icons.radio_button_unchecked,
                        size: 16,
                        color: allDone
                            ? Colors.green
                            : isCurrent
                                ? colorScheme.primary
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ex.exerciseName,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: allDone
                                    ? Colors.grey
                                    : colorScheme.onSurface)),
                      ),
                      Text(
                        '${ex.targetSets}×${ex.targetReps}'
                        '${wDisplay != null ? '  ${wDisplay.toStringAsFixed(1)} ${UnitsUtil.unitLabel(units)}' : ''}'
                        '${isActive ? '  $doneSets/${ex.targetSets}' : ''}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
              if (exercises.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 24),
                  child: Text('+ ${exercises.length - 4} more',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              const SizedBox(height: 12),
            ],

            // ── action buttons ──
            if (isActive && nextEx != null) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProgramSessionScreen(program: program, dayIndex: dayIdx),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Continue — ${nextEx.exerciseName}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else if (!isActive && exercises.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProgramSessionScreen(program: program, dayIndex: dayIdx),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start ${day?.name ?? program.name}'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (program.days.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: program.days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, di) => OutlinedButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProgramSessionScreen(program: program, dayIndex: di),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(program.days[di].name,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      );
}
