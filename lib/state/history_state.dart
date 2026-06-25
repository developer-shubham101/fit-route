import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_entry.dart';
import 'workout_state.dart';

class HistoryFilters {
  final String? routineId;
  final String? exerciseId;
  final String? type; // 'Bodyweight' | 'External' | null
  final String query;
  final String dateRange; // 'all' | 'today' | 'week' | 'month'

  const HistoryFilters({
    this.routineId,
    this.exerciseId,
    this.type,
    this.query = '',
    this.dateRange = 'all',
  });

  HistoryFilters copyWith(
      {String? routineId,
      String? exerciseId,
      String? type,
      String? query,
      String? dateRange}) {
    return HistoryFilters(
      routineId: routineId ?? this.routineId,
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

  void setRoutine(String? routineId) =>
      state = state.copyWith(routineId: routineId);
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
    if (filters.routineId != null &&
        filters.routineId!.isNotEmpty &&
        e.routineId != filters.routineId) return false;
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
