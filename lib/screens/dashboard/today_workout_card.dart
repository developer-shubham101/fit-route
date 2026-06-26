import 'package:flutter/material.dart';
import '../../models/workout_entry.dart';
import '../../utils/units.dart';

class TodayWorkoutCard extends StatelessWidget {
  final List<WorkoutEntry> entries;
  final String units;

  const TodayWorkoutCard({required this.entries, required this.units, super.key});

  Map<String, List<WorkoutEntry>> _groupByExercise() {
    final map = <String, List<WorkoutEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.exerciseId, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No workout logged today yet.', style: TextStyle(fontSize: 14)),
        ),
      );
    }

    final grouped = _groupByExercise();

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
                  '${entries.length} set${entries.length == 1 ? '' : 's'} logged',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.check_circle, color: Colors.green.shade400),
              ],
            ),
            const SizedBox(height: 6),
            ...grouped.entries.take(4).map((kv) {
              final sets = kv.value;
              final totalReps = sets.fold<int>(0, (s, e) => s + e.reps);
              final bestW = sets
                  .where((e) => e.externalWeight != null)
                  .fold<double?>(null,
                      (best, e) => best == null || e.externalWeight! > best ? e.externalWeight : best);
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
            if (grouped.length > 4)
              Text('+ ${grouped.length - 4} more exercises',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
