import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/trends_state.dart';
import '../state/program_state.dart';
import '../state/workout_state.dart';
import '../state/app_state.dart';
import '../models/program.dart';
import '../utils/units.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Exercise'),
            Tab(text: 'Body Part'),
            Tab(text: 'Programs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _OverviewTab(),
          _ExerciseTab(),
          _BodyPartTab(),
          _ProgramProgressTab(),
        ],
      ),
    );
  }
}

// ── Shared bar chart ──────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<_Bar> bars;
  final Color color;
  const _BarChart({required this.bars, required this.color});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const SizedBox(height: 120,
          child: Center(child: Text('No data', style: TextStyle(color: Colors.grey))));
    }
    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((b) {
          final frac = maxVal == 0 ? 0.0 : b.value / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (b.value > 0)
                    Text(b.topLabel,
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Container(height: (frac * 90).clamp(2, 90), color: color),
                  const SizedBox(height: 4),
                  Text(b.label,
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Bar {
  final String label;
  final String topLabel;
  final double value;
  _Bar(this.label, this.value, {String? top})
      : topLabel = top ?? (value == 0 ? '' : value.toStringAsFixed(0));
}

// ── Range picker ──────────────────────────────────────────────────────────────
class _RangePicker extends ConsumerWidget {
  const _RangePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(trendRangeProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: TrendRange.values.map((r) {
          final label = r.name[0].toUpperCase() + r.name.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(label),
              selected: range == r,
              onSelected: (_) async {
                ref.read(trendRangeProvider.notifier).state = r;
                if (r == TrendRange.custom) {
                  await _pickCustom(context, ref);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(trendCustomStartProvider.notifier).state = picked.start;
      ref.read(trendCustomEndProvider.notifier).state = picked.end;
    }
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(overviewBucketsProvider);
    final units = ref.watch(unitsProvider).valueOrNull ?? 'metric';

    return ListView(
      children: [
        const _RangePicker(),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chartTitle('Volume (${UnitsUtil.unitLabel(units)})'),
              const SizedBox(height: 8),
              _BarChart(
                bars: buckets.map((b) => _Bar(b.label,
                    UnitsUtil.fromKg(b.totalVolumeKg, units))).toList(),
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 20),
              _chartTitle('Total Reps'),
              const SizedBox(height: 8),
              _BarChart(
                bars: buckets
                    .map((b) => _Bar(b.label, b.totalReps.toDouble()))
                    .toList(),
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              _chartTitle('Total Sets'),
              const SizedBox(height: 8),
              _BarChart(
                bars: buckets
                    .map((b) => _Bar(b.label, b.totalSets.toDouble()))
                    .toList(),
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _chartTitle(String t) => Text(t,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));

// ── Exercise tab ──────────────────────────────────────────────────────────────
class _ExerciseTab extends ConsumerStatefulWidget {
  const _ExerciseTab();

  @override
  ConsumerState<_ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends ConsumerState<_ExerciseTab> {
  String? _selectedId;
  String _selectedName = '';

  @override
  Widget build(BuildContext context) {
    final tracked = ref.watch(trackedExercisesProvider);
    final units = ref.watch(unitsProvider).valueOrNull ?? 'metric';

    if (tracked.isEmpty) {
      return const Center(child: Text('No workout data yet.'));
    }

    // Auto-select first
    if (_selectedId == null && tracked.isNotEmpty) {
      _selectedId = tracked.first.key;
      _selectedName = tracked.first.value;
    }

    final points = _selectedId != null
        ? ref.watch(exerciseProgressionProvider(_selectedId!))
        : <ExercisePoint>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedId,
          decoration: const InputDecoration(labelText: 'Exercise', isDense: true),
          items: tracked
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _selectedId = v;
              _selectedName =
                  tracked.firstWhere((e) => e.key == v).value;
            });
          },
        ),
        const SizedBox(height: 20),
        if (points.isEmpty)
          const Text('No data for this exercise.',
              style: TextStyle(color: Colors.grey))
        else ...[
          _chartTitle('Weight Progression (${UnitsUtil.unitLabel(units)})'),
          const SizedBox(height: 8),
          _BarChart(
            bars: points
                .map((p) => _Bar(_fmtDate(p.date),
                    UnitsUtil.fromKg(p.bestWeightKg, units)))
                .toList(),
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          _chartTitle('Reps per Session'),
          const SizedBox(height: 8),
          _BarChart(
            bars: points
                .map((p) => _Bar(_fmtDate(p.date), p.totalReps.toDouble()))
                .toList(),
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          _chartTitle('Sets per Session'),
          const SizedBox(height: 8),
          _BarChart(
            bars: points
                .map((p) => _Bar(_fmtDate(p.date), p.totalSets.toDouble()))
                .toList(),
            color: Colors.teal,
          ),
          const SizedBox(height: 20),
          _chartTitle('Avg Duration / Set (s)'),
          const SizedBox(height: 8),
          _BarChart(
            bars: points
                .map((p) => _Bar(_fmtDate(p.date), p.avgRestSecs))
                .toList(),
            color: Colors.pinkAccent,
          ),
        ],
      ],
    );
  }

  String _fmtDate(DateTime d) => '${d.month}/${d.day}';
}

// ── Body Part tab ─────────────────────────────────────────────────────────────
class _BodyPartTab extends ConsumerWidget {
  const _BodyPartTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volMap = ref.watch(bodyPartVolumeProvider);
    final units = ref.watch(unitsProvider).valueOrNull ?? 'metric';

    if (volMap.isEmpty) {
      return const Center(child: Text('No weighted exercises tracked yet.'));
    }

    final top = volMap.entries.take(15).toList();
    final totalVol = top.fold(0.0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _chartTitle('Volume by Exercise (${UnitsUtil.unitLabel(units)})'),
        const SizedBox(height: 8),
        _BarChart(
          bars: top
              .map((e) => _Bar(
                    _short(e.key),
                    UnitsUtil.fromKg(e.value, units),
                  ))
              .toList(),
          color: Colors.deepOrange,
        ),
        const SizedBox(height: 24),
        _chartTitle('Share of Total Volume'),
        const SizedBox(height: 8),
        ...top.map((e) {
          final pct = totalVol == 0 ? 0.0 : e.value / totalVol;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                  Text('${(pct * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.deepOrange,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _short(String name) =>
      name.length > 10 ? '${name.substring(0, 8)}..' : name;
}

// ── Program Progress tab ──────────────────────────────────────────────────────
class _ProgramProgressTab extends ConsumerWidget {
  const _ProgramProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    final allEntries = ref.watch(entriesProvider);
    final units = ref.watch(unitsProvider).valueOrNull ?? 'metric';

    if (programs.isEmpty) {
      return const Center(child: Text('No programs yet.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: programs.map((p) {
        return _ProgramCard(program: p, allEntries: allEntries, units: units);
      }).toList(),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Program program;
  final List allEntries;
  final String units;
  const _ProgramCard(
      {required this.program, required this.allEntries, required this.units});

  @override
  Widget build(BuildContext context) {
    // Collect all entries for this program
    final progEntries = allEntries
        .where((e) => e.routineId == program.id)
        .toList();

    // Per-exercise stats
    int totalTargetSets = 0;
    int totalActualSets = 0;
    int totalTargetReps = 0;
    int totalActualReps = 0;
    int missedTargets = 0;
    final List<_ExStats> exStats = [];

    for (final day in program.days) {
      for (final ex in day.exercises) {
        final exEntries = progEntries
            .where((e) => e.exerciseId == ex.exerciseId)
            .toList();
        final actualSets = exEntries.length;
        final actualReps = exEntries.fold(0, (s, e) => s + (e.reps as int));
        final targetTotal = ex.targetSets * ex.targetReps;
        final metTarget = actualReps >= targetTotal && actualSets >= ex.targetSets;

        totalTargetSets += ex.targetSets;
        totalActualSets += actualSets;
        totalTargetReps += targetTotal;
        totalActualReps += actualReps;
        if (!metTarget && exEntries.isNotEmpty) missedTargets++;

        exStats.add(_ExStats(
          name: ex.exerciseName,
          targetSets: ex.targetSets,
          actualSets: actualSets,
          targetReps: ex.targetReps,
          actualReps: actualReps,
          targetWeightKg: ex.targetWeightKg,
          bestActualWeightKg: exEntries
              .where((e) => e.externalWeight != null)
              .fold<double?>(null,
                  (b, e) => b == null || e.externalWeight > b ? e.externalWeight as double : b),
          met: metTarget,
        ));
      }
    }

    final goalPct = totalTargetSets == 0
        ? 0.0
        : (totalActualSets / totalTargetSets).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(program.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${program.type}  •  ${program.days.length} days'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(children: [
                  _MiniStat('Sets',
                      '$totalActualSets / $totalTargetSets', Colors.teal),
                  const SizedBox(width: 8),
                  _MiniStat('Reps',
                      '$totalActualReps / $totalTargetReps', Colors.deepPurple),
                  const SizedBox(width: 8),
                  _MiniStat('Missed', '$missedTargets', Colors.orange),
                ]),
                const SizedBox(height: 10),
                // Goal completion bar
                Row(children: [
                  const Text('Goal completion: ',
                      style: TextStyle(fontSize: 13)),
                  Text('${(goalPct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: goalPct >= 1.0
                              ? Colors.green
                              : goalPct >= 0.5
                                  ? Colors.orange
                                  : Colors.red)),
                ]),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goalPct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: goalPct >= 1.0
                      ? Colors.green
                      : goalPct >= 0.5
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Exercise breakdown
                ...exStats.map((s) => _ExerciseRow(s: s, units: units)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExStats {
  final String name;
  final int targetSets, actualSets, targetReps, actualReps;
  final double? targetWeightKg, bestActualWeightKg;
  final bool met;
  _ExStats({
    required this.name,
    required this.targetSets,
    required this.actualSets,
    required this.targetReps,
    required this.actualReps,
    this.targetWeightKg,
    this.bestActualWeightKg,
    required this.met,
  });
}

class _ExerciseRow extends StatelessWidget {
  final _ExStats s;
  final String units;
  const _ExerciseRow({required this.s, required this.units});

  @override
  Widget build(BuildContext context) {
    final hasData = s.actualSets > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasData
                ? (s.met ? Icons.check_circle : Icons.cancel)
                : Icons.radio_button_unchecked,
            size: 16,
            color: hasData
                ? (s.met ? Colors.green : Colors.orange)
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  'Sets: ${s.actualSets}/${s.targetSets}  •  '
                  'Reps: ${s.actualReps}/${s.targetSets * s.targetReps}'
                  '${s.targetWeightKg != null ? '  •  Target: ${UnitsUtil.formatWeight(s.targetWeightKg, units)}' : ''}'
                  '${s.bestActualWeightKg != null ? '  •  Best: ${UnitsUtil.formatWeight(s.bestActualWeightKg, units)}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      );
}
