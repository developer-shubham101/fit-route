import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_entry.dart';
import '../state/history_state.dart';
import '../state/app_state.dart';
import '../utils/units.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final HistoryGroup group;
  const WorkoutDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider).valueOrNull ?? 'metric';
    final allRecords = ref.watch(personalRecordsProvider);

    // Group entries by exercise
    final byExercise = <String, List<WorkoutEntry>>{};
    for (final e in group.entries) {
      byExercise.putIfAbsent(e.exerciseName, () => []).add(e);
    }

    // Session summary stats
    final totalSets = group.entries.length;
    final totalReps = group.entries.fold(0, (s, e) => s + e.reps);
    final totalVolume = group.entries
        .where((e) => e.externalWeight != null)
        .fold(0.0, (s, e) => s + e.externalWeight! * e.reps);
    final exerciseCount = byExercise.length;

    // PRs achieved on this day
    final sessionExerciseIds =
        group.entries.map((e) => e.exerciseId).toSet();
    final sessionPRs = allRecords
        .where((pr) =>
            sessionExerciseIds.contains(pr.exerciseId) &&
            _isSameDay(pr.achievedAt, group.date))
        .toList();

    final dateLabel =
        '${_month(group.date.month)} ${group.date.day}, ${group.date.year}';

    return Scaffold(
      appBar: AppBar(title: Text(dateLabel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Session Summary ──────────────────────────────────────────────
          _SectionHeader('Session Summary'),
          const SizedBox(height: 8),
          Row(children: [
            _StatCard(label: 'Exercises', value: '$exerciseCount',
                icon: Icons.fitness_center, color: Colors.teal),
            const SizedBox(width: 8),
            _StatCard(label: 'Sets', value: '$totalSets',
                icon: Icons.layers, color: Colors.deepPurple),
            const SizedBox(width: 8),
            _StatCard(label: 'Reps', value: '$totalReps',
                icon: Icons.repeat, color: Colors.orange),
            const SizedBox(width: 8),
            _StatCard(
                label: 'Volume',
                value: UnitsUtil.formatWeight(totalVolume, units),
                icon: Icons.monitor_weight_outlined,
                color: Colors.blue),
          ]),

          const SizedBox(height: 24),

          // ── Exercise Timeline ────────────────────────────────────────────
          _SectionHeader('Exercise Timeline'),
          const SizedBox(height: 8),
          ...byExercise.entries.map((kv) =>
              _ExerciseTile(name: kv.key, sets: kv.value, units: units)),

          // ── Personal Records ─────────────────────────────────────────────
          if (sessionPRs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader('Personal Records 🏆'),
            const SizedBox(height: 8),
            ...sessionPRs.map((pr) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(pr.exerciseName),
                  subtitle: Text(
                      '${UnitsUtil.formatWeight(pr.bestWeightKg, units)} × ${pr.repsAtBest} reps'),
                )),
          ],
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── Exercise timeline tile ────────────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final String name;
  final List<WorkoutEntry> sets;
  final String units;
  const _ExerciseTile(
      {required this.name, required this.sets, required this.units});

  @override
  Widget build(BuildContext context) {
    final bestWeight = sets
        .where((e) => e.externalWeight != null)
        .fold<double?>(null,
            (best, e) => best == null || e.externalWeight! > best ? e.externalWeight : best);
    final totalReps = sets.fold(0, (s, e) => s + e.reps);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text('${sets.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${sets.length} sets  •  $totalReps reps'
          '${bestWeight != null ? '  •  best ${UnitsUtil.formatWeight(bestWeight, units)}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          const Divider(height: 1),
          ...sets.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final time =
                '${e.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${e.timestamp.toLocal().minute.toString().padLeft(2, '0')}';
            return ListTile(
              dense: true,
              leading: Text('Set ${i + 1}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
              title: Text(
                e.externalWeight != null
                    ? '${e.reps} reps @ ${UnitsUtil.formatWeight(e.externalWeight, units)}'
                    : '${e.reps} reps',
              ),
              trailing: Text(time,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            );
          }),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
