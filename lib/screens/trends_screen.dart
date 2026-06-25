import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/trends_state.dart';
import '../state/app_state.dart';
import '../utils/units.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyTrendsProvider);
    final monthly = ref.watch(monthlyTrendsProvider);
    final unitsAsync = ref.watch(unitsProvider);

    Widget barChart(List<TrendBucket> buckets, double Function(TrendBucket) valueGetter, {required Color color}) {
      final maxVal = buckets.isEmpty ? 0.0 : buckets.map(valueGetter).reduce((a, b) => a > b ? a : b);
      return SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final b in buckets)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: maxVal == 0 ? 0 : (valueGetter(b) / maxVal) * 120,
                      color: color,
                    ),
                    const SizedBox(height: 6),
                    Text(b.label, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: unitsAsync.when(
        data: (units) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Weekly Reps (last 8 weeks)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            barChart(weekly, (b) => b.totalReps.toDouble(), color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text('Weekly Volume', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            barChart(weekly, (b) => b.totalVolumeKg, color: Colors.deepPurpleAccent),
            Text('Units: ${UnitsUtil.unitLabel(units)} (volume shown converted)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 32),
            const Text('Monthly Reps (last 6 months)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            barChart(monthly, (b) => b.totalReps.toDouble(), color: Colors.teal),
            const SizedBox(height: 16),
            const Text('Monthly Volume', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            barChart(monthly, (b) => b.totalVolumeKg, color: Colors.orangeAccent),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load units')),
      ),
    );
  }
}
