import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/history_state.dart';
import '../state/app_state.dart';
import '../state/program_state.dart';
import '../state/workout_state.dart';
import '../utils/units.dart';
import 'home_screen.dart';
import 'dashboard/section_header.dart';
import 'dashboard/stat_card.dart';
import 'dashboard/today_workout_card.dart';
import 'dashboard/recent_workout_card.dart';
import 'dashboard/active_program_card.dart';

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
    final units = ref.watch(unitsProvider).valueOrNull ?? 'metric';

    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = profile != null ? '' : '';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(entriesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── greeting ──
          Text('$greeting${name.isNotEmpty ? ", $name" : ""}! 💪',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(_formatDate(now),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 16),

          // ── active program / session ──
          DashboardSectionHeader(
              activeSession != null ? 'Session in Progress' : 'Active Program'),
          const SizedBox(height: 8),
          ActiveProgramCard(
            activeProgram: activeProgram,
            activeSession: activeSession,
            programs: programs,
            allEntries: ref.watch(entriesProvider),
            units: units,
            onChangeProgram: () =>
                context.findAncestorStateOfType<HomeScreenState>()?.setNavIndex(2),
          ),
          const SizedBox(height: 20),

          // ── weekly summary ──
          const DashboardSectionHeader('This Week'),
          const SizedBox(height: 8),
          Row(children: [
            DashboardStatCard(
              label: 'Workout Days',
              value: '${weekSummary.workoutDays}',
              icon: Icons.calendar_today,
              color: Colors.teal,
            ),
            const SizedBox(width: 10),
            DashboardStatCard(
              label: 'Total Reps',
              value: '${weekSummary.totalReps}',
              icon: Icons.repeat,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 10),
            DashboardStatCard(
              label: 'Volume',
              value: UnitsUtil.formatWeight(weekSummary.totalVolumeKg, units),
              icon: Icons.fitness_center,
              color: Colors.orange,
            ),
          ]),
          const SizedBox(height: 20),

          // ── today's workout ──
          const DashboardSectionHeader("Today's Workout"),
          const SizedBox(height: 8),
          TodayWorkoutCard(entries: todayEntries, units: units),
          const SizedBox(height: 20),

          // ── recent workout ──
          if (lastGroup != null) ...[
            const DashboardSectionHeader('Recent Workout'),
            const SizedBox(height: 8),
            RecentWorkoutCard(group: lastGroup, units: units),
            const SizedBox(height: 20),
          ],

          // ── personal records ──
          if (records.isNotEmpty) ...[
            const DashboardSectionHeader('Personal Records'),
            const SizedBox(height: 8),
            ...records.take(5).map((pr) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(pr.exerciseName),
                  subtitle: Text(
                      '${UnitsUtil.formatWeight(pr.bestWeightKg, units)} × ${pr.repsAtBest} reps'),
                  trailing: Text(_formatDate(pr.achievedAt.toLocal()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                )),
            if (records.length > 5)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('+ ${records.length - 5} more records',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
