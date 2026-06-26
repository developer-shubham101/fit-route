import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_entry.dart';
import 'workout_state.dart';

class TrendBucket {
  final String label;
  final DateTime start;
  final DateTime end;
  final int totalReps;
  final double totalVolumeKg;
  final int totalSets;
  TrendBucket({
    required this.label,
    required this.start,
    required this.end,
    required this.totalReps,
    required this.totalVolumeKg,
    this.totalSets = 0,
  });
}

// ── Exercise progression point ────────────────────────────────────────────────
class ExercisePoint {
  final DateTime date;
  final double bestWeightKg; // best weight in that session
  final int totalReps;       // total reps in that session
  final int totalSets;       // total sets in that session
  final double avgRestSecs;  // avg rest (durationSeconds proxy)
  ExercisePoint(this.date, this.bestWeightKg, this.totalReps, this.totalSets,
      this.avgRestSecs);
}

// ── Trend range enum ──────────────────────────────────────────────────────────
enum TrendRange { daily, weekly, monthly, yearly, custom }

// ── Selected range / exercise / body-part state ───────────────────────────────
final trendRangeProvider = StateProvider<TrendRange>((ref) => TrendRange.weekly);
final trendCustomStartProvider = StateProvider<DateTime?>((ref) => null);
final trendCustomEndProvider = StateProvider<DateTime?>((ref) => null);
final trendExerciseIdProvider = StateProvider<String?>((ref) => null);
final trendExerciseNameProvider = StateProvider<String>((ref) => '');
final trendBodyPartProvider = StateProvider<String?>((ref) => null);

DateTime _startOfWeekLocal(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final weekday = d.weekday; // Mon=1
  return d.subtract(Duration(days: weekday - 1));
}

DateTime _startOfMonthLocal(DateTime date) =>
    DateTime(date.year, date.month, 1);

// ── Bucket builders ───────────────────────────────────────────────────────────
TrendBucket _makeBucket(String label, DateTime start, DateTime end,
    List<WorkoutEntry> entries) {
  final pe = entries.where((e) {
    final t = e.timestamp.toLocal();
    return !t.isBefore(start) && t.isBefore(end);
  });
  int reps = 0, sets = 0;
  double vol = 0;
  for (final e in pe) {
    reps += e.reps;
    sets++;
    if (e.externalWeight != null) vol += e.externalWeight! * e.reps;
  }
  return TrendBucket(
      label: label,
      start: start,
      end: end,
      totalReps: reps,
      totalVolumeKg: vol,
      totalSets: sets);
}

int _weekOfYear(DateTime date) {
  final firstDay = DateTime(date.year, 1, 1);
  final firstWeekStart = _startOfWeekLocal(firstDay);
  final diff = date.difference(firstWeekStart).inDays;
  return (diff ~/ 7) + 1;
}

List<TrendBucket> _buildDailyBuckets(List<WorkoutEntry> entries,
    {int days = 14}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(days, (i) {
    final start = today.subtract(Duration(days: days - 1 - i));
    final end = start.add(const Duration(days: 1));
    final label = '${start.month}/${start.day}';
    return _makeBucket(label, start, end, entries);
  });
}

List<TrendBucket> _buildWeeklyBuckets(List<WorkoutEntry> entries,
    {int weeks = 8}) {
  final now = DateTime.now();
  final startWeek = _startOfWeekLocal(now);
  return List.generate(weeks, (i) {
    final start = startWeek.subtract(Duration(days: 7 * (weeks - 1 - i)));
    final end = start.add(const Duration(days: 7));
    final woy = _weekOfYear(start).toString().padLeft(2, '0');
    return _makeBucket('Wk $woy', start, end, entries);
  });
}

List<TrendBucket> _buildMonthlyBuckets(List<WorkoutEntry> entries,
    {int months = 6}) {
  final now = DateTime.now();
  return List.generate(months, (i) {
    final offset = months - 1 - i;
    int y = now.year;
    int m = now.month - offset;
    while (m <= 0) { m += 12; y--; }
    final start = DateTime(y, m, 1);
    final end = DateTime(start.year, start.month + 1, 1);
    final label = '${start.year}-${start.month.toString().padLeft(2, '0')}';
    return _makeBucket(label, start, end, entries);
  });
}

List<TrendBucket> _buildYearlyBuckets(List<WorkoutEntry> entries,
    {int years = 3}) {
  final now = DateTime.now();
  return List.generate(years, (i) {
    final y = now.year - (years - 1 - i);
    final start = DateTime(y, 1, 1);
    final end = DateTime(y + 1, 1, 1);
    return _makeBucket('$y', start, end, entries);
  });
}

List<TrendBucket> _buildCustomBuckets(
    List<WorkoutEntry> entries, DateTime from, DateTime to) {
  // Split into ~10 equal segments
  final totalDays = to.difference(from).inDays.clamp(1, 3650);
  final segDays = (totalDays / 10).ceil().clamp(1, 365);
  final List<TrendBucket> buckets = [];
  DateTime cur = DateTime(from.year, from.month, from.day);
  while (cur.isBefore(to)) {
    final end = cur.add(Duration(days: segDays));
    final label = '${cur.month}/${cur.day}';
    buckets.add(_makeBucket(label, cur, end, entries));
    cur = end;
  }
  return buckets;
}

// ── Overview providers (range-aware) ─────────────────────────────────────────
final overviewBucketsProvider = Provider<List<TrendBucket>>((ref) {
  final entries = ref.watch(entriesProvider);
  final range = ref.watch(trendRangeProvider);
  final customStart = ref.watch(trendCustomStartProvider);
  final customEnd = ref.watch(trendCustomEndProvider);
  switch (range) {
    case TrendRange.daily:
      return _buildDailyBuckets(entries);
    case TrendRange.weekly:
      return _buildWeeklyBuckets(entries);
    case TrendRange.monthly:
      return _buildMonthlyBuckets(entries);
    case TrendRange.yearly:
      return _buildYearlyBuckets(entries);
    case TrendRange.custom:
      if (customStart != null && customEnd != null &&
          customEnd.isAfter(customStart)) {
        return _buildCustomBuckets(entries, customStart, customEnd);
      }
      return _buildWeeklyBuckets(entries);
  }
});

// legacy (keep for any existing references)
final weeklyTrendsProvider = Provider<List<TrendBucket>>((ref) {
  final entries = ref.watch(entriesProvider);
  return _buildWeeklyBuckets(entries);
});

final monthlyTrendsProvider = Provider<List<TrendBucket>>((ref) {
  final entries = ref.watch(entriesProvider);
  return _buildMonthlyBuckets(entries);
});

// ── Exercise progression provider ────────────────────────────────────────────
final exerciseProgressionProvider =
    Provider.family<List<ExercisePoint>, String>((ref, exerciseId) {
  final entries = ref.watch(entriesProvider);
  final filtered =
      entries.where((e) => e.exerciseId == exerciseId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Group by calendar day
  final Map<DateTime, List<WorkoutEntry>> byDay = {};
  for (final e in filtered) {
    final t = e.timestamp.toLocal();
    final key = DateTime(t.year, t.month, t.day);
    byDay.putIfAbsent(key, () => []).add(e);
  }

  return byDay.entries.map((kv) {
    final day = kv.key;
    final sets = kv.value;
    final bestW = sets
        .where((e) => e.externalWeight != null)
        .fold<double>(0.0, (b, e) => e.externalWeight! > b ? e.externalWeight! : b);
    final totalReps = sets.fold(0, (s, e) => s + e.reps);
    final avgRest = sets.isEmpty
        ? 0.0
        : sets.fold(0.0, (s, e) => s + e.durationSeconds) / sets.length;
    return ExercisePoint(day, bestW, totalReps, sets.length, avgRest);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// ── All exercise IDs that have entries ───────────────────────────────────────
final trackedExercisesProvider =
    Provider<List<MapEntry<String, String>>>((ref) {
  final entries = ref.watch(entriesProvider);
  final Map<String, String> seen = {};
  for (final e in entries) {
    seen.putIfAbsent(e.exerciseId, () => e.exerciseName);
  }
  return seen.entries.toList();
});

// ── Body part volume provider ─────────────────────────────────────────────────
// Groups by exerciseName — each exercise treated as its own category
final bodyPartVolumeProvider = Provider<Map<String, double>>((ref) {
  final entries = ref.watch(entriesProvider);
  final Map<String, double> vol = {};
  for (final e in entries) {
    if (e.externalWeight == null) continue;
    // group key = exerciseName (each exercise treated as its own category)
    vol[e.exerciseName] =
        (vol[e.exerciseName] ?? 0) + e.externalWeight! * e.reps;
  }
  // Sort descending
  final sorted = Map.fromEntries(
      vol.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  return sorted;
});
