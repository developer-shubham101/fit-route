import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_entry.dart';
import 'workout_state.dart';

class HistoryFilters {
  final String? programId;
  final String? exerciseId;
  final String? type;
  final String query;
  final String dateRange;

  const HistoryFilters({
    this.programId,
    this.exerciseId,
    this.type,
    this.query = '',
    this.dateRange = 'all',
  });

  HistoryFilters copyWith(
      {String? programId,
      String? exerciseId,
      String? type,
      String? query,
      String? dateRange}) {
    return HistoryFilters(
      programId: programId ?? this.programId,
      exerciseId: exerciseId ?? this.exerciseId,
      type: type ?? this.type,
      query: query ?? this.query,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

final historyFiltersProvider =
    StateNotifierProvider<HistoryFiltersNotifier, HistoryFilters>(
        (ref) => HistoryFiltersNotifier());

class HistoryFiltersNotifier extends StateNotifier<HistoryFilters> {
  HistoryFiltersNotifier() : super(const HistoryFilters());

  void setProgram(String? programId) =>
      state = state.copyWith(programId: programId);
  void setExercise(String? exerciseId) =>
      state = state.copyWith(exerciseId: exerciseId);
  void setType(String? type) => state = state.copyWith(type: type);
  void setQuery(String query) => state = state.copyWith(query: query);
  void setDateRange(String dateRange) =>
      state = state.copyWith(dateRange: dateRange);
  void clear() => state = const HistoryFilters();
}

DateTime _startOfTodayLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _startOfWeekLocal() {
  final today = _startOfTodayLocal();
  // Week starts on Monday
  final weekday = today.weekday; // 1..7
  return today.subtract(Duration(days: weekday - 1));
}

DateTime _startOfMonthLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

final filteredEntriesProvider = Provider<List<WorkoutEntry>>((ref) {
  final entries = ref.watch(entriesProvider);
  final filters = ref.watch(historyFiltersProvider);

  DateTime? start;
  switch (filters.dateRange) {
    case 'today':
      start = _startOfTodayLocal();
      break;
    case 'week':
      start = _startOfWeekLocal();
      break;
    case 'month':
      start = _startOfMonthLocal();
      break;
    default:
      start = null;
  }

  return entries.where((e) {
    if (filters.programId != null &&
        filters.programId!.isNotEmpty &&
        e.routineId != filters.programId) return false;
    if (filters.exerciseId != null &&
        filters.exerciseId!.isNotEmpty &&
        e.exerciseId != filters.exerciseId) return false;
    if (filters.type != null &&
        filters.type!.isNotEmpty &&
        e.type != filters.type) return false;
    if (filters.query.isNotEmpty) {
      final q = filters.query.toLowerCase();
      if (!e.exerciseName.toLowerCase().contains(q)) return false;
    }
    if (start != null) {
      final localTs = e.timestamp.toLocal();
      if (localTs.isBefore(start)) return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

class HistoryGroup {
  final DateTime date; // local date at midnight
  final List<WorkoutEntry> entries;
  HistoryGroup(this.date, this.entries);
}

final groupedEntriesProvider = Provider<List<HistoryGroup>>((ref) {
  final entries = ref.watch(filteredEntriesProvider);
  final Map<DateTime, List<WorkoutEntry>> map = {};
  for (final e in entries) {
    final t = e.timestamp.toLocal();
    final dateKey = DateTime(t.year, t.month, t.day);
    map.putIfAbsent(dateKey, () => []).add(e);
  }
  final groups = map.entries
      .map((kv) => HistoryGroup(
          kv.key, kv.value..sort((a, b) => b.timestamp.compareTo(a.timestamp))))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return groups;
});

class HistorySummary {
  final int totalReps;
  final double totalVolumeKg; // sum of (externalWeightKg * reps)
  const HistorySummary(this.totalReps, this.totalVolumeKg);
}

final historySummaryProvider = Provider<HistorySummary>((ref) {
  final entries = ref.watch(filteredEntriesProvider);
  int reps = 0;
  double volumeKg = 0;
  for (final e in entries) {
    reps += e.reps;
    if (e.externalWeight != null) {
      volumeKg += e.externalWeight! * e.reps;
    }
  }
  return HistorySummary(reps, volumeKg);
});

// ── Dashboard providers ──────────────────────────────────────────────────────

/// All entries for today (local date)
final todayEntriesProvider = Provider<List<WorkoutEntry>>((ref) {
  final entries = ref.watch(entriesProvider);
  final today = _startOfTodayLocal();
  final tomorrow = today.add(const Duration(days: 1));
  return entries
      .where((e) {
        final t = e.timestamp.toLocal();
        return !t.isBefore(today) && t.isBefore(tomorrow);
      })
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

/// This-week stats: totalReps + totalVolumeKg
class WeekSummary {
  final int totalReps;
  final double totalVolumeKg;
  final int workoutDays; // distinct days with at least 1 entry
  const WeekSummary(this.totalReps, this.totalVolumeKg, this.workoutDays);
}

final weekSummaryProvider = Provider<WeekSummary>((ref) {
  final entries = ref.watch(entriesProvider);
  final weekStart = _startOfWeekLocal();
  final weekEntries =
      entries.where((e) => !e.timestamp.toLocal().isBefore(weekStart)).toList();
  int reps = 0;
  double vol = 0;
  final days = <DateTime>{};
  for (final e in weekEntries) {
    reps += e.reps;
    if (e.externalWeight != null) vol += e.externalWeight! * e.reps;
    final t = e.timestamp.toLocal();
    days.add(DateTime(t.year, t.month, t.day));
  }
  return WeekSummary(reps, vol, days.length);
});

/// Personal records: best (weight × reps) per exercise, stored as best weight
class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final double bestWeightKg;
  final int repsAtBest;
  final DateTime achievedAt;
  const PersonalRecord(
      this.exerciseId, this.exerciseName, this.bestWeightKg, this.repsAtBest,
      this.achievedAt);
}

final personalRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  final entries = ref.watch(entriesProvider);
  final Map<String, PersonalRecord> best = {};
  for (final e in entries) {
    if (e.externalWeight == null || e.externalWeight! <= 0) continue;
    final vol = e.externalWeight! * e.reps;
    final existing = best[e.exerciseId];
    if (existing == null ||
        vol > existing.bestWeightKg * existing.repsAtBest) {
      best[e.exerciseId] = PersonalRecord(
          e.exerciseId, e.exerciseName, e.externalWeight!, e.reps, e.timestamp);
    }
  }
  final list = best.values.toList()
    ..sort((a, b) =>
        (b.bestWeightKg * b.repsAtBest).compareTo(a.bestWeightKg * a.repsAtBest));
  return list;
});

/// Most recent workout group (last calendar day that had entries)
final lastWorkoutGroupProvider = Provider<HistoryGroup?>((ref) {
  final groups = ref.watch(groupedEntriesProvider);
  return groups.isNotEmpty ? groups.first : null;
});
