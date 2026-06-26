# FitRoute — LLM Context Reference

> **INSTRUCTION FOR LLM:** This file contains the complete system architecture, API specifications, and implementation details for the FitRoute Flutter app. Use this as the **primary context** for all code generation, debugging, and system understanding. Always read this before making changes. Never reference removed classes listed in Section 13.

This document is the authoritative reference for the current FitRoute Flutter codebase. Use it as the source of truth for all ongoing development.

---

## 1. Product summary

FitRoute is a local-first personal workout tracker. The core experience is logging workout sets against programs, reviewing progress, and exploring an exercise library. All data is stored on-device using Hive and SharedPreferences.

---

## 2. Navigation structure

`HomeScreen` is the shell. It uses a `BottomNavigationBar` with 6 tabs:

| Index | Label    | Screen                    |
|-------|----------|---------------------------|
| 0     | Home     | DashboardScreen           |
| 1     | Explore  | ExploreExercisesScreen    |
| 2     | Programs | ProgramsScreen            |
| 3     | History  | HistoryScreen             |
| 4     | Trends   | TrendsScreen              |
| 5     | Settings | SettingsScreen            |

`HomeScreenState` is public (not private) so `DashboardScreen` can call `setNavIndex(2)` to navigate to Programs.

---

## 3. File structure

```
lib/
├── main.dart
├── models/
│   ├── exercise.dart / exercise.g.dart
│   ├── program.dart / program.g.dart
│   ├── user_profile.dart / user_profile.g.dart
│   └── workout_entry.dart / workout_entry.g.dart
├── services/
│   ├── exercise_service.dart
│   ├── last_used_service.dart
│   ├── prefs_service.dart
│   ├── program_service.dart
│   ├── seed_service.dart
│   ├── user_profile_service.dart
│   └── workout_entry_service.dart
├── state/
│   ├── app_state.dart
│   ├── explore/
│   │   └── explore_state.dart
│   ├── history_state.dart
│   ├── program_state.dart
│   ├── trends_state.dart
│   └── workout_state.dart
├── screens/
│   ├── root_router.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── history_screen.dart
│   ├── settings_screen.dart
│   ├── trends_screen.dart
│   ├── welcome_screen.dart
│   ├── dashboard/
│   │   ├── active_program_card.dart
│   │   ├── recent_workout_card.dart
│   │   ├── section_header.dart
│   │   ├── stat_card.dart
│   │   └── today_workout_card.dart
│   ├── explore/
│   │   ├── exercise_card.dart
│   │   ├── exercise_detail_page.dart
│   │   ├── exercise_edit_page.dart
│   │   ├── exercise_filter_bar.dart
│   │   ├── exercise_helpers.dart
│   │   ├── exercise_picker_screen.dart
│   │   └── explore_exercises_screen.dart
│   └── programs/
│       ├── program_detail_screen.dart
│       ├── program_editor_screen.dart
│       ├── program_session_screen.dart
│       ├── programs_screen.dart
│       ├── set_entry_screen.dart
│       └── widgets/
│           ├── circle_btn.dart
│           └── rest_countdown.dart
└── utils/
    ├── media.dart
    └── units.dart
assets/
├── images/
│   ├── logo.png
│   ├── splash.png
│   └── workout_placeholder.png
└── json/
    ├── fitroute_exercises_detailed.json
    └── fitroute_seed_data.json
```

---

## 4. Data models (Hive)

| Model            | typeId | Key fields                                                                                  |
|------------------|--------|---------------------------------------------------------------------------------------------|
| UserProfile      | 0      | id, age, gender, weightKg, heightCm, bmi                                                    |
| Exercise         | 2      | id, name, defaultType, category, difficulty, equipment, primaryMuscles, setsRecommended, repsRecommended, imageUrl, gifUrl, isBodyweight, suitableAtHome |
| WorkoutEntry     | 3      | id, exerciseId, exerciseName, routineId (holds programId), type, externalWeight, reps, timestamp (UTC), durationSeconds |
| ProgramExercise  | 4      | exerciseId, exerciseName, targetSets, targetReps, targetWeightKg, targetRestSeconds, notes  |
| ProgramDay       | 5      | name, exercises (List\<ProgramExercise\>)                                                   |
| Program          | 6      | id, name, type, description, days, goal, level, durationMinutes, equipmentNeeded, location, tags |

> **Note:** The `Routine` model has been removed. `WorkoutEntry.routineId` now stores a program ID.

### Hive boxes

- `user_profile`
- `exercises`
- `workout_entries`
- `programs`

---

## 5. SharedPreferences keys (PrefsService)

| Key                    | Type    | Purpose                                    |
|------------------------|---------|--------------------------------------------|
| `onboarding_complete`  | bool    | Whether onboarding has been finished       |
| `default_units`        | String  | `'metric'` or `'imperial'`                 |
| `seeded_default_routines` | bool | Legacy key, unused                         |
| `seeded_sample_data`   | bool    | Whether SeedService has run                |
| `active_program_id`    | String? | ID of the user-selected active program     |
| `session_program_id`   | String? | Program ID of the in-progress session      |
| `session_day_index`    | int?    | Day index of the in-progress session       |

---

## 6. Riverpod providers

### app_state.dart
- `prefsServiceProvider` — `PrefsService`
- `lastUsedServiceProvider` — `LastUsedService`
- `userProfileServiceProvider` — `UserProfileService`
- `unitsProvider` — `FutureProvider<String>`, reads default units
- `onboardingCompleteProvider` — `StateNotifierProvider<OnboardingNotifier, bool>`
- `profileProvider` — `StateNotifierProvider<UserProfileNotifier, UserProfile?>`
- `appThemeProvider` — `StateProvider<ThemeMode>`

### workout_state.dart
- `workoutEntryServiceProvider` — `WorkoutEntryService`
- `activeWorkoutProvider` — `StateProvider<ActiveWorkoutState?>` (legacy, may be unused)
- `entriesProvider` — `StateNotifierProvider<WorkoutEntriesNotifier, List<WorkoutEntry>>`

### history_state.dart
- `historyFiltersProvider` — `StateNotifierProvider<HistoryFiltersNotifier, HistoryFilters>`
- `filteredEntriesProvider` — filtered + sorted entries
- `groupedEntriesProvider` — entries grouped by local calendar date
- `historySummaryProvider` — total reps + volume for filtered range
- `todayEntriesProvider` — entries for today (local)
- `weekSummaryProvider` — `WeekSummary` (reps, volume, workout days)
- `personalRecordsProvider` — best volume per exercise
- `lastWorkoutGroupProvider` — most recent `HistoryGroup`

### program_state.dart
- `programServiceProvider` — `ProgramService`
- `programsProvider` — `StateNotifierProvider<ProgramsNotifier, List<Program>>`
- `programFiltersProvider` — `StateNotifierProvider<ProgramFiltersNotifier, ProgramFilters>`
- `filteredProgramsProvider` — filtered program list
- `activeProgramIdProvider` — `StateNotifierProvider<ActiveProgramNotifier, String?>` (persisted)
- `activeProgramProvider` — `Provider<Program?>` derived from active ID
- `activeSessionProvider` — `StateNotifierProvider<ActiveSessionNotifier, ActiveSession?>` (persisted)
- `programSearchProvider` — legacy `StateProvider<String>` used by trends

### explore/explore_state.dart
- `exerciseServiceProvider` — `ExerciseService`
- `exerciseLibraryProvider` — `StateNotifierProvider<ExerciseLibraryNotifier, List<Exercise>>`
- `exerciseSearchQueryProvider` — `StateProvider<String>`
- `exploreFiltersProvider` — `StateNotifierProvider<ExploreFiltersNotifier, ExploreFilters>`
- `filteredExerciseLibraryProvider` — filtered exercise list

---

## 7. Seeding (SeedService)

`SeedService` runs once at app startup in `main()`, guarded by `prefs.getSeededSampleData()`.

Order of seeding:
1. `_seedExercises()` — loads `fitroute_exercises_detailed.json` → populates `exercises` Hive box
2. `_seedFromJson()` — loads `fitroute_seed_data.json` → populates `programs` and `workout_entries` boxes

`fitroute_seed_data.json` structure:
```json
{
  "programs": [ { "id", "name", "type", "days": [ { "name", "exercises": [...] } ] } ],
  "workout_entries": [ { "exercise_id", "exercise_name", "routine_id", "type", "reps", "external_weight", "days_ago", "hour" } ]
}
```

Programs in seed data reference exercise IDs from `fitroute_exercises_detailed.json` (e.g. `"6"` = Push-Ups, `"14"` = Squats, `"18"` = Lunges).

> **ExerciseService no longer has `seedDefaultsIfEmpty()`** — all seeding is owned by `SeedService`.

---

## 8. Utility APIs

### UnitsUtil (`lib/utils/units.dart`)

```dart
UnitsUtil.unitLabel(String units)          // 'kg' or 'lb'
UnitsUtil.fromKg(double kg, String units)  // converts kg → display value
UnitsUtil.toKg(double val, String units)   // converts display value → kg
UnitsUtil.formatWeight(double kg, String units) // e.g. '80.0 kg'
```

### MediaUtil (`lib/utils/media.dart`)

```dart
MediaUtil.cachedImage(String url, {BoxFit fit, double? width, double? height, BorderRadius? radius})
MediaUtil.placeholderBox({double? width, double? height, BorderRadius? radius})
MediaUtil.isImageUrl(String url)   // true for png/jpg/gif/webp
MediaUtil.isVideoUrl(String url)   // true for mp4/webm/video
MediaUtil.clearCache()             // empties the Hive + memory image cache
```

---

## 9. Coding conventions

- All Hive adapters are registered in `main.dart` before the app starts.
- Timestamps are always stored in UTC (`DateTime.now().toUtc()`) and converted to local time only for display.
- `WorkoutEntry.routineId` stores a **program ID** (field name is legacy; do not rename as it would break Hive storage).
- Providers are never accessed directly from widgets — always via `ref.watch` / `ref.read`.
- Navigation between tabs uses `context.findAncestorStateOfType<HomeScreenState>()?.setNavIndex(n)`.
- New screens under `programs/` go in `lib/screens/programs/`, widgets in `lib/screens/programs/widgets/`.
- New dashboard sub-widgets go in `lib/screens/dashboard/`.
- Avoid adding new SharedPreferences keys without documenting them in Section 5 of this file.
- The `seeded_default_routines` prefs key is legacy — do not read or write it in new code.

---

## 10. Programs feature

### ProgramsScreen
- Lists all programs with search + filter bar (Type, Goal, Level, Equipment, Location)
- Each program shows a radio/check icon for active selection — only one program can be active at a time
- Tapping the icon or "Set as Active" toggles the active program (persisted via `activeProgramIdProvider`)
- Active program name is bold with a filled check icon

### ProgramDetailScreen
- Shows program metadata chips (goal, level, duration, equipment, location, tags)
- Lists days with exercises and per-day Start buttons
- Edit and delete actions in app bar

### ProgramEditorScreen
- Create/edit programs with full metadata fields
- Add days, add exercises via `ExercisePickerScreen`
- Per-exercise config dialog (sets, reps, weight, rest, notes)

### ProgramSessionScreen (session list view)
- Shows the day's exercises as cards
- Each card shows: exercise name, target info, today's completed sets as chips
- "Start Set N" button opens `_SetEntryScreen` as a full-screen push
- Saves `WorkoutEntry` on return from set entry
- Marks session as active in `activeSessionProvider` on init, clears on finish
- "Finish Session" at bottom clears active session and pops

### Set entry screen (within program_session_screen.dart)
- Full-screen per-set logging
- Large timer display with Start / End Set button
- Reps stepper and Weight slider + stepper
- Auto-starts rest countdown after ending set
- Submit button saves result back to session screen

---

## 11. Dashboard

`DashboardScreen` is wrapped in a `Scaffold` with an `AppBar` (greeting + date).

Sections (top to bottom):
1. **Continue banner** — shown when `activeSessionProvider` is non-null; "Continue" button navigates back into the session
2. **Active Program card** — shows selected program metadata + Start button for first day; day selector row for multi-day programs; "Change" taps to Programs tab via `HomeScreenState.setNavIndex(2)`
3. **This Week** — stat cards for workout days, total reps, volume
4. **Today's Workout** — logged sets summary or empty state with quick-start button
5. **Recent Workout** — last workout group card
6. **Personal Records** — top 5 PRs by volume

---

## 12. Explore Exercises

`ExploreExercisesScreen` uses `CustomScrollView` with `SliverStickyHeader` (from `flutter_sticky_header` package).

Architecture split into:
- `explore_exercises_screen.dart` — main screen, groups exercises by category, builds slivers
- `exercise_filter_bar.dart` — `ExploreFilterBar` ConsumerStatefulWidget (search + dropdowns + chips)
- `exercise_card.dart` — `ExerciseCard` with thumbnail, primary muscles, tag pills, calorie estimate
- `exercise_helpers.dart` — `difficultyColor()`, `categoryIcon()`, `ExerciseTag`, `ExerciseCategoryHeader`

Exercises are grouped alphabetically by `category`. Each group gets a sticky `ExerciseCategoryHeader` with icon + count badge.

---

## 13. Settings

`SettingsScreen` actions:
- Edit Profile → opens `WelcomeScreen`
- Theme → system / light / dark via `appThemeProvider`
- Units → metric (kg/cm) / imperial (lb/ft)
- Export JSON → saves workout entries as JSON backup
- Import JSON → restores workout entries from backup
- Export CSV → saves workout entries as CSV
- Clear media cache
- Reset all data → clears profile + workout entries

> Routines are no longer part of export/import/reset.

---

## 14. Key dependencies

| Package                | Purpose                          |
|------------------------|----------------------------------|
| flutter_riverpod       | State management                 |
| hive / hive_flutter    | Local structured storage         |
| shared_preferences     | Simple flags and preferences     |
| path_provider          | File system access               |
| cached_network_image   | Network image caching            |
| flutter_cache_manager  | Cache management                 |
| flutter_sticky_header  | Sticky section headers in lists  |
| intl                   | Date/number formatting           |
| url_launcher           | External link support            |

---

## 15. Removed / no longer present

The following were removed and must not be referenced:

- `Routine` model (`routine.dart`, `routine.g.dart`)
- `RoutineService` (`routine_service.dart`)
- `RoutinesNotifier` / `routinesProvider` (`routines_state.dart`)
- `NewRoutineScreen`, `RoutineDetailScreen`, `ActiveExerciseScreen`, `WorkoutDetailScreen`
- `fitroute_routines.json` asset
- `ExerciseService.seedDefaultsIfEmpty()` method
- Bottom nav "Routines" tab (was never present in current nav)
