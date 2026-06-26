import 'package:flutter/material.dart';
import '../../state/history_state.dart';
import '../../utils/units.dart';

class RecentWorkoutCard extends StatelessWidget {
  final HistoryGroup group;
  final String units;

  const RecentWorkoutCard({required this.group, required this.units, super.key});

  @override
  Widget build(BuildContext context) {
    final byEx = <String, List<dynamic>>{};
    for (final e in group.entries) {
      byEx.putIfAbsent(e.exerciseId as String, () => []).add(e);
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
                      (best, e) => best == null || e.externalWeight > best
                          ? e.externalWeight as double
                          : best);
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
