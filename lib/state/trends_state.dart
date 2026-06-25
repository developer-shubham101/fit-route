import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_entry.dart';
import 'workout_state.dart';

class TrendBucket {
  final String label; // e.g., 'Wk 32' or '2025-08'
  final DateTime start; // period start (local)
  final DateTime end; // period end exclusive (local)
  final int totalReps;
  final double totalVolumeKg;
  TrendBucket({
    required this.label,
    required this.start,
    required this.end,
    required this.totalReps,
    required this.totalVolumeKg,
  });
}

DateTime _startOfWeekLocal(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final weekday = d.weekday; // Mon=1
  return d.subtract(Duration(days: weekday - 1));
}

DateTime _startOfMonthLocal(DateTime date) =>
    DateTime(date.year, date.month, 1);

List<TrendBucket> _buildWeeklyBuckets(List<WorkoutEntry> entries,
    {int weeks = 8}) {
  final now = DateTime.now();
  DateTime startWeek = _startOfWeekLocal(now);
  final List<TrendBucket> buckets = [];
  for (int i = weeks - 1; i >= 0; i--) {
    final start = startWeek.subtract(Duration(days: 7 * i));
    final end = start.add(const Duration(days: 7));
    final periodEntries = entries.where((e) {
      final t = e.timestamp.toLocal();
      return !t.isBefore(start) && t.isBefore(end);
    });
    int reps = 0;
    double vol = 0;
    for (final e in periodEntries) {
      reps += e.reps;
      if (e.externalWeight != null) vol += e.externalWeight! * e.reps;
    }
    final weekOfYear = int.parse(_weekOfYear(start).toString().padLeft(2, '0'));
    buckets.add(TrendBucket(
      label: 'Wk $weekOfYear',
      start: start,
      end: end,
      totalReps: reps,
      totalVolumeKg: vol,
    ));
  }
  return buckets;
}

int _weekOfYear(DateTime date) {
  final firstDay = DateTime(date.year, 1, 1);
  final firstWeekStart = _startOfWeekLocal(firstDay);
  final diff = date.difference(firstWeekStart).inDays;
  return (diff ~/ 7) + 1;
}

List<TrendBucket> _buildMonthlyBuckets(List<WorkoutEntry> entries,
    {int months = 6}) {
  final now = DateTime.now();
  DateTime cursor = DateTime(now.year, now.month, 1);
  final List<TrendBucket> buckets = [];
  for (int i = months - 1; i >= 0; i--) {
    final start = DateTime(cursor.year, cursor.month - i, 1);
    final end = DateTime(start.year, start.month + 1, 1);
    final periodEntries = entries.where((e) {
      final t = e.timestamp.toLocal();
      return !t.isBefore(start) && t.isBefore(end);
    });
    int reps = 0;
    double vol = 0;
    for (final e in periodEntries) {
      reps += e.reps;
      if (e.externalWeight != null) vol += e.externalWeight! * e.reps;
    }
    final label = '${start.year}-${start.month.toString().padLeft(2, '0')}';
    buckets.add(TrendBucket(
        label: label,
        start: start,
        end: end,
        totalReps: reps,
        totalVolumeKg: vol));
  }
  return buckets;
}

final weeklyTrendsProvider = Provider<List<TrendBucket>>((ref) {
  final entries = ref.watch(entriesProvider);
  return _buildWeeklyBuckets(entries);
});

final monthlyTrendsProvider = Provider<List<TrendBucket>>((ref) {
  final entries = ref.watch(entriesProvider);
  return _buildMonthlyBuckets(entries);
});
