import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/history_state.dart';
import '../state/app_state.dart';
import '../state/program_state.dart';
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
    final unitsAsync = ref.watch(unitsProvider);

    final units = unitsAsync.valueOrNull ?? 'metric';
    final unitLabel = UnitsUtil.unitLabel(units);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No workout logged today yet.',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    if (activeProgram != null)
                      OutlinedButton.icon(
                        onPressed: activeProgram.days.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProgramSessionScreen(
                                        program: activeProgram, dayIndex: 0),
                                  ),
                                ),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text('Start "${activeProgram.name}"'),
                      ),
                  ],
                ),
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

          // ── active program ──
          _SectionHeader('Active Program'),
          const SizedBox(height: 8),
          if (activeProgram == null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('No active program selected'),
                subtitle: const Text('Go to Programs to select one'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  // navigate to Programs tab via HomeScreen
                  final homeState = context
                      .findAncestorStateOfType<HomeScreenState>();
                  homeState?.setNavIndex(2);
                },
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
                        Expanded(
                          child: Text(activeProgram.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () {
                            final homeState = context
                                .findAncestorStateOfType<HomeScreenState>();
                            homeState?.setNavIndex(2);
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    if (activeProgram.goal.isNotEmpty ||
                        activeProgram.level.isNotEmpty ||
                        activeProgram.durationMinutes > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (activeProgram.goal.isNotEmpty)
                              Chip(
                                  label: Text('🎯 ${activeProgram.goal}'),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                            if (activeProgram.level.isNotEmpty)
                              Chip(
                                  label: Text('📶 ${activeProgram.level}'),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                            if (activeProgram.durationMinutes > 0)
                              Chip(
                                  label: Text(
                                      '⏱ ${activeProgram.durationMinutes} min'),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: activeProgram.days.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProgramSessionScreen(
                                        program: activeProgram, dayIndex: 0),
                                  ),
                                ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                            'Start ${activeProgram.days.isNotEmpty ? activeProgram.days.first.name : activeProgram.name}'),
                        style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    if (activeProgram.days.length > 1) ...[                      
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: activeProgram.days.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (context, di) => OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProgramSessionScreen(
                                    program: activeProgram, dayIndex: di),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            child: Text(activeProgram.days[di].name,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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

// ── recent workout card ───────────────────────────────────────────────────────
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
