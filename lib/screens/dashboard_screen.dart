import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/history_state.dart';
import '../state/app_state.dart';
import '../state/program_state.dart';
import '../models/program.dart';
import '../models/workout_entry.dart';
import 'home_screen.dart';
import '../utils/units.dart';
import 'programs/program_session_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final todayEntries = ref.watch(todayEntriesProvider);
    final weekSummary = ref.watch(weekSummaryProvider);
    final records = ref.watch(personalRecordsProvider);
    final lastGroup = ref.watch(lastWorkoutGroupProvider);
    final activeProgram = ref.watch(activeProgramProvider);
    final activeSession = ref.watch(activeSessionProvider);
    final programs = ref.watch(programsProvider);
    final unitsAsync = ref.watch(unitsProvider);

    final units = unitsAsync.valueOrNull ?? 'metric';

    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = profile != null ? '' : '';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(entriesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── greeting ──
          Text('$greeting${name.isNotEmpty ? ", $name" : ""}! 💪',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            _formatDate(now),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // ── active program / session card ──
          _SectionHeader(activeSession != null ? 'Session in Progress' : 'Active Program'),
          const SizedBox(height: 8),
          _ActiveProgramCard(
            activeProgram: activeProgram,
            activeSession: activeSession,
            programs: programs,
            allEntries: ref.watch(entriesProvider),
            units: units,
            onChangeProgram: () {
              context.findAncestorStateOfType<HomeScreenState>()?.setNavIndex(2);
            },
          ),

          const SizedBox(height: 20),

          // ── weekly summary ──
          _SectionHeader('This Week'),
          const SizedBox(height: 8),
          Row(children: [
            _StatCard(
              label: 'Workout Days',
              value: '${weekSummary.workoutDays}',
              icon: Icons.calendar_today,
              color: Colors.teal,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Total Reps',
              value: '${weekSummary.totalReps}',
              icon: Icons.repeat,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Volume',
              value: UnitsUtil.formatWeight(weekSummary.totalVolumeKg, units),
              icon: Icons.fitness_center,
              color: Colors.orange,
            ),
          ]),

          const SizedBox(height: 20),

          // ── today's workout ──
          _SectionHeader("Today's Workout"),
          const SizedBox(height: 8),
          if (todayEntries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const Text('No workout logged today yet.',
                    style: TextStyle(fontSize: 14)),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${todayEntries.length} set${todayEntries.length == 1 ? '' : 's'} logged',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.check_circle, color: Colors.green.shade400),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._groupByExercise(todayEntries)
                        .entries
                        .take(4)
                        .map((kv) {
                      final sets = kv.value;
                      final int totalReps = sets.fold<int>(
                        0,
                            (int s, e) => s + (e.reps as num).toInt(),
                      );
                      final bestW = sets
                          .where((e) => e.externalWeight != null)
                          .fold<double?>(
                              null,
                              (best, e) => best == null ||
                                      e.externalWeight! > best
                                  ? e.externalWeight
                                  : best);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          const Icon(Icons.circle, size: 6),
                          const SizedBox(width: 6),
                          Text(
                            '${sets.first.exerciseName}  •  ${sets.length} sets, $totalReps reps'
                            '${bestW != null ? '  •  best ${UnitsUtil.formatWeight(bestW, units)}' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ]),
                      );
                    }),
                    if (_groupByExercise(todayEntries).length > 4)
                      Text(
                        '+ ${_groupByExercise(todayEntries).length - 4} more exercises',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── recent workout ──
          if (lastGroup != null) ...[
            _SectionHeader('Recent Workout'),
            const SizedBox(height: 8),
            _RecentWorkoutCard(group: lastGroup, units: units),
            const SizedBox(height: 20),
          ],

          // ── personal records ──
          if (records.isNotEmpty) ...[
            _SectionHeader('Personal Records'),
            const SizedBox(height: 8),
            ...records.take(5).map((pr) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(pr.exerciseName),
                  subtitle: Text(
                      '${UnitsUtil.formatWeight(pr.bestWeightKg, units)} × ${pr.repsAtBest} reps'),
                  trailing: Text(
                    _formatDate(pr.achievedAt.toLocal()),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                )),
            if (records.length > 5)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('+ ${records.length - 5} more records',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Map<String, List<dynamic>> _groupByExercise(List entries) {
    final map = <String, List<dynamic>>{};
    for (final e in entries) {
      map.putIfAbsent(e.exerciseId as String, () => []).add(e);
    }
    return map;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold));
}

// ── stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ── unified active program / session card ──────────────────────────────────────────────
class _ActiveProgramCard extends ConsumerWidget {
  final Program? activeProgram;
  final ActiveSession? activeSession;
  final List<Program> programs;
  final List<WorkoutEntry> allEntries;
  final String units;
  final VoidCallback onChangeProgram;

  const _ActiveProgramCard({
    required this.activeProgram,
    required this.activeSession,
    required this.programs,
    required this.allEntries,
    required this.units,
    required this.onChangeProgram,
  });

  // Today's logged sets for this program/day
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

    // ── No active program at all ──
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

    // Resolve program from session or activeProgram
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

    // Find next incomplete exercise index
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
    final doneCount = exercises.where((ex) {
      return (todayByEx[ex.exerciseId]?.length ?? 0) >= ex.targetSets;
    }).length;
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
            // ── header row ──
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
                  child: Text(
                    program.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  style: TextStyle(fontSize: 13, color: colorScheme.primary, fontWeight: FontWeight.w500)),
            ],

            // ── meta chips ──
            if (!isActive && (program.goal.isNotEmpty || program.level.isNotEmpty || program.durationMinutes > 0)) ...[              
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  if (program.goal.isNotEmpty)
                    _MiniChip('🎯 ${program.goal}'),
                  if (program.level.isNotEmpty)
                    _MiniChip('📶 ${program.level}'),
                  if (program.durationMinutes > 0)
                    _MiniChip('⏱ ${program.durationMinutes} min'),
                ],
              ),
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
                        child: Text(
                          ex.exerciseName,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: allDone ? Colors.grey : colorScheme.onSurface),
                        ),
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
              // Continue → jump straight to SetEntryScreen
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final doneSets = todayByEx[nextEx.exerciseId]?.length ?? 0;
                    // Find last weight used for this exercise today
                    final lastEntry = todayByEx[nextEx.exerciseId]?.isNotEmpty == true
                        ? todayByEx[nextEx.exerciseId]!.last
                        : null;
                    final resumeWeightKg =
                        lastEntry?.externalWeight ?? nextEx.targetWeightKg;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgramSessionScreen(
                            program: program, dayIndex: dayIdx),
                      ),
                    );
                  },
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
                  label: Text(
                      'Start ${day?.name ?? program.name}'),
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

// ── recent workout card ───────────────────────────────────────────────
class _RecentWorkoutCard extends StatelessWidget {
  final HistoryGroup group;
  final String units;
  const _RecentWorkoutCard({required this.group, required this.units});

  @override
  Widget build(BuildContext context) {
    final byEx = <String, List<dynamic>>{};
    for (final e in group.entries) {
      byEx.putIfAbsent(e.exerciseId, () => []).add(e);
    }
    final isToday = _isToday(group.date);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? 'Today' : _fmtDate(group.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${group.entries.length} sets',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            ...byEx.entries.take(3).map((kv) {
              final sets = kv.value;
              final totalReps = sets.fold(0, (s, e) => s + (e.reps as int));
              final bestW = sets
                  .where((e) => e.externalWeight != null)
                  .fold<double?>(null,
                      (best, e) => best == null || e.externalWeight > best ? e.externalWeight as double : best);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  '${sets.first.exerciseName}  •  ${sets.length}×$totalReps reps'
                  '${bestW != null ? '  @  ${UnitsUtil.formatWeight(bestW, units)}' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }),
            if (byEx.length > 3)
              Text('+ ${byEx.length - 3} more',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
