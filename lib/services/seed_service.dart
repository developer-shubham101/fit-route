import '../models/workout_entry.dart';
import '../models/program.dart';
import '../services/workout_entry_service.dart';
import '../services/program_service.dart';
import '../services/prefs_service.dart';

class SeedService {
  final WorkoutEntryService _entries;
  final ProgramService _programs;
  final PrefsService _prefs;

  SeedService(this._entries, this._programs, this._prefs);

  Future<void> seedIfNeeded() async {
    final done = await _prefs.getSeededSampleData();
    if (done) return;
    await _seedEntries();
    await _seedPrograms();
    await _prefs.setSeededSampleData(true);
  }

  Future<void> _seedEntries() async {
    final now = DateTime.now().toUtc();

    // helper to create an entry offset by days/hours from now
    WorkoutEntry entry(
      String exId,
      String exName,
      String routineId,
      String type,
      int reps,
      double? weight,
      int daysAgo,
      int hoursOffset,
    ) {
      final ts = DateTime(now.year, now.month, now.day - daysAgo,
              10 + hoursOffset, 0, 0)
          .toUtc();
      return WorkoutEntry(
        id: '${ts.millisecondsSinceEpoch}_${exId}_$reps',
        exerciseId: exId,
        exerciseName: exName,
        routineId: routineId,
        type: type,
        externalWeight: weight,
        reps: reps,
        timestamp: ts,
        durationSeconds: 45 + reps * 3,
      );
    }

    // --- today ---
    await _entries.addEntry(
        entry('ex_bench', 'Bench Press', 'routine_push', 'External', 10, 60.0, 0, 0));
    await _entries.addEntry(
        entry('ex_bench', 'Bench Press', 'routine_push', 'External', 8, 65.0, 0, 0));
    await _entries.addEntry(
        entry('ex_bench', 'Bench Press', 'routine_push', 'External', 6, 70.0, 0, 0));
    await _entries.addEntry(
        entry('ex_pushup', 'Push-Up', 'routine_push', 'Bodyweight', 20, null, 0, 1));
    await _entries.addEntry(
        entry('ex_pushup', 'Push-Up', 'routine_push', 'Bodyweight', 18, null, 0, 1));

    // --- yesterday ---
    await _entries.addEntry(
        entry('ex_squat', 'Squat', 'routine_legs', 'External', 10, 80.0, 1, 0));
    await _entries.addEntry(
        entry('ex_squat', 'Squat', 'routine_legs', 'External', 8, 85.0, 1, 0));
    await _entries.addEntry(
        entry('ex_squat', 'Squat', 'routine_legs', 'External', 6, 90.0, 1, 0));
    await _entries.addEntry(
        entry('ex_lunge', 'Lunge', 'routine_legs', 'Bodyweight', 12, null, 1, 1));

    // --- 2 days ago ---
    await _entries.addEntry(
        entry('ex_pullup', 'Pull-Up', 'routine_pull', 'Bodyweight', 10, null, 2, 0));
    await _entries.addEntry(
        entry('ex_pullup', 'Pull-Up', 'routine_pull', 'Bodyweight', 8, null, 2, 0));
    await _entries.addEntry(
        entry('ex_row', 'Barbell Row', 'routine_pull', 'External', 10, 60.0, 2, 1));
    await _entries.addEntry(
        entry('ex_row', 'Barbell Row', 'routine_pull', 'External', 8, 65.0, 2, 1));

    // --- 3 days ago ---
    await _entries.addEntry(
        entry('ex_ohp', 'Overhead Press', 'routine_push', 'External', 8, 40.0, 3, 0));
    await _entries.addEntry(
        entry('ex_ohp', 'Overhead Press', 'routine_push', 'External', 6, 45.0, 3, 0));
    await _entries.addEntry(
        entry('ex_dip', 'Dip', 'routine_push', 'Bodyweight', 12, null, 3, 1));

    // --- 5 days ago ---
    await _entries.addEntry(
        entry('ex_deadlift', 'Deadlift', 'routine_legs', 'External', 5, 100.0, 5, 0));
    await _entries.addEntry(
        entry('ex_deadlift', 'Deadlift', 'routine_legs', 'External', 5, 110.0, 5, 0));
    await _entries.addEntry(
        entry('ex_deadlift', 'Deadlift', 'routine_legs', 'External', 3, 120.0, 5, 0));

    // --- 7 days ago (last week) ---
    await _entries.addEntry(
        entry('ex_bench', 'Bench Press', 'routine_push', 'External', 10, 55.0, 7, 0));
    await _entries.addEntry(
        entry('ex_bench', 'Bench Press', 'routine_push', 'External', 8, 60.0, 7, 0));
    await _entries.addEntry(
        entry('ex_squat', 'Squat', 'routine_legs', 'External', 10, 75.0, 8, 0));
    await _entries.addEntry(
        entry('ex_squat', 'Squat', 'routine_legs', 'External', 8, 80.0, 8, 0));

    // --- 14 days ago ---
    await _entries.addEntry(
        entry('ex_bench', 'Bench Press', 'routine_push', 'External', 10, 50.0, 14, 0));
    await _entries.addEntry(
        entry('ex_deadlift', 'Deadlift', 'routine_legs', 'External', 5, 90.0, 14, 0));
    await _entries.addEntry(
        entry('ex_pullup', 'Pull-Up', 'routine_pull', 'Bodyweight', 7, null, 14, 1));
  }

  Future<void> _seedPrograms() async {
    // Push Pull Legs program
    await _programs.add(Program(
      id: 'prog_ppl',
      name: 'Push Pull Legs',
      type: 'Push Pull Legs',
      description: '3-day split targeting all major muscle groups.',
      days: [
        ProgramDay(name: 'Push Day', exercises: [
          ProgramExercise(
              exerciseId: 'ex_bench',
              exerciseName: 'Bench Press',
              targetSets: 4,
              targetReps: 8,
              targetWeightKg: 60.0,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_ohp',
              exerciseName: 'Overhead Press',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 40.0,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_dip',
              exerciseName: 'Dip',
              targetSets: 3,
              targetReps: 12,
              targetRestSeconds: 60),
          ProgramExercise(
              exerciseId: 'ex_pushup',
              exerciseName: 'Push-Up',
              targetSets: 3,
              targetReps: 20,
              targetRestSeconds: 60),
        ]),
        ProgramDay(name: 'Pull Day', exercises: [
          ProgramExercise(
              exerciseId: 'ex_pullup',
              exerciseName: 'Pull-Up',
              targetSets: 4,
              targetReps: 8,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_row',
              exerciseName: 'Barbell Row',
              targetSets: 4,
              targetReps: 8,
              targetWeightKg: 60.0,
              targetRestSeconds: 90),
        ]),
        ProgramDay(name: 'Leg Day', exercises: [
          ProgramExercise(
              exerciseId: 'ex_squat',
              exerciseName: 'Squat',
              targetSets: 4,
              targetReps: 8,
              targetWeightKg: 80.0,
              targetRestSeconds: 120),
          ProgramExercise(
              exerciseId: 'ex_deadlift',
              exerciseName: 'Deadlift',
              targetSets: 3,
              targetReps: 5,
              targetWeightKg: 100.0,
              targetRestSeconds: 120),
          ProgramExercise(
              exerciseId: 'ex_lunge',
              exerciseName: 'Lunge',
              targetSets: 3,
              targetReps: 12,
              targetRestSeconds: 60),
        ]),
      ],
    ));

    // Full Body Beginner
    await _programs.add(Program(
      id: 'prog_fullbody',
      name: 'Full Body Beginner',
      type: 'Full Body',
      description: 'Simple 3-day full body routine for beginners.',
      days: [
        ProgramDay(name: 'Day A', exercises: [
          ProgramExercise(
              exerciseId: 'ex_squat',
              exerciseName: 'Squat',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 40.0,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_bench',
              exerciseName: 'Bench Press',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 40.0,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_row',
              exerciseName: 'Barbell Row',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 40.0,
              targetRestSeconds: 90),
        ]),
        ProgramDay(name: 'Day B', exercises: [
          ProgramExercise(
              exerciseId: 'ex_squat',
              exerciseName: 'Squat',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 42.5,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_ohp',
              exerciseName: 'Overhead Press',
              targetSets: 3,
              targetReps: 10,
              targetWeightKg: 30.0,
              targetRestSeconds: 90),
          ProgramExercise(
              exerciseId: 'ex_deadlift',
              exerciseName: 'Deadlift',
              targetSets: 1,
              targetReps: 5,
              targetWeightKg: 60.0,
              targetRestSeconds: 120),
        ]),
      ],
    ));
  }
}
