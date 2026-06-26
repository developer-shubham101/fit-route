# FitRoute - Implemented App Reference

This document is the current reference for the implemented FitRoute Flutter application. It describes the app as built and should be used as the source of truth for ongoing work.

## 1. Product summary

FitRoute is a personal workout logbook with optional workout template guidance. The core experience is recording and reviewing workout sessions, while templates, exercise browsing, and progress views support that primary flow.

## 2. Current implementation status

The app is implemented as a local-first fitness tracking application with the following completed areas:

- Onboarding and profile setup
- Home dashboard focused on starting workouts
- Exercise library browsing and filtering
- Workout template/program browsing, selection, and session tracking
- Workout session logging with bodyweight and external-weight support
- Workout history with filtering and entry editing/deleting
- Trends dashboard with multiple analytic views
- Settings for theme, units, import/export, reset, and cache cleanup

## 3. Main user flow

1. The app starts at the onboarding/profile screen unless onboarding is already complete.
2. After onboarding, the user lands on the home dashboard.
3. The home dashboard is designed to help the user begin a workout session quickly.
4. A workout session can be started from a selected template/program, from a quick empty workout, or from a single exercise entry point.
5. During a session, the user logs sets, reps, weight when applicable, rest timing, and notes.
6. Completed sessions are saved as workout entries and appear in history, trends, and personal records.

## 4. Implemented screens and responsibilities

- WelcomeScreen: profile form with BMI calculation, skip option, and local save
- HomeScreen: shell for the main app sections with the dashboard as the primary entry point for starting workouts
- DashboardScreen: greeting, weekly summary, today’s workout context, active template/program prompt, and recent workout overview
- ExploreExercisesScreen: searchable exercise library with filters and exercise detail navigation
- ProgramsScreen: listing, filtering, selecting, editing, and deleting workout templates/programs
- ProgramSessionScreen: template/program-day workflow with set progress, timers, and session completion
- HistoryScreen: grouped workout history, filters, edit/delete actions, and summary
- WorkoutDetailScreen: detailed breakdown of a saved workout day
- TrendsScreen: overview, exercise, body part, and program-based progress charts
- SettingsScreen: theme selection, unit selection, JSON/CSV export, JSON import, data reset, and cache cleanup
- ActiveExerciseScreen: in-session exercise logging UI for multiple sets and notes

## 5. Application architecture

The application uses a Flutter + Riverpod architecture with clear separation between:

- Models: user profile, exercise, routine, workout entry, and program/template models
- Services: Hive-backed storage services and SharedPreferences helpers
- State: Riverpod providers for onboarding, profile, workout entries, history filters, templates/programs, active sessions, trends, and explore filters
- Screens: UI layer for user-facing flows

## 6. State management and data flow

The app uses Riverpod providers for core application state:

- onboardingCompleteProvider: tracks whether onboarding has been completed
- profileProvider: stores and exposes the current user profile
- entriesProvider: stores all workout entries
- historyFiltersProvider and groupedEntriesProvider: power history filtering and grouping
- programsProvider and activeProgramIdProvider: manage templates/programs and active selection
- activeSessionProvider: tracks the current in-progress workout session
- exploreFiltersProvider and exerciseLibraryProvider: power the exercise browser
- unitsProvider: exposes the current unit preference

## 7. Data model and storage

### 7.1 Hive models

The app uses Hive for structured local persistence with the following model classes:

- UserProfile
  - id, age, gender, weight, weightUnit, height, heightUnit, bmi, lastUpdated
- Exercise
  - exercise metadata including name, category, equipment, difficulty, instructions, and bodyweight/external flags
- Routine
  - routine metadata and associated exercises
- WorkoutEntry
  - id, exerciseId, exerciseName, routineId, type, externalWeight, reps, timestamp, durationSeconds
- Program, ProgramDay, ProgramExercise
  - program definitions, day structure, and target sets/reps/weights

### 7.2 Storage boxes

The app stores data in Hive boxes named:

- user_profile
- exercises
- routines
- workout_entries
- programs

### 7.3 SharedPreferences usage

SharedPreferences is used for simple app-level flags and preferences:

- onboarding completion
- default units
- seeded sample data state
- active program selection
- active session state

## 8. Persistence behavior

- Hive is initialized during app startup in main.dart.
- All Hive adapters are registered before the app runs.
- Sample workout entries and programs are seeded on first launch through SeedService.
- Workout timestamps are stored in UTC and displayed in local time where needed.
- Unit conversion is handled by the unit utilities in the app.

## 9. Core features actually implemented

### 9.1 Onboarding and profile

The onboarding flow collects personal data, computes BMI, allows the user to skip, and stores the profile locally.

### 9.2 Exercise logging

The workout logging flow supports:

- bodyweight exercises
- external-weight exercises
- multiple sets per exercise
- rest timer support
- notes for exercise and workout session
- saving entries into local history

### 9.3 Templates and programs

Workout templates/programs can be created, edited, deleted, filtered, and selected as active. Template/program sessions track progress per day and per exercise target.

### 9.4 History and trends

Workout history is grouped by day and supports search and filtering by routine, exercise, type, and date range. Trends include overview charts for reps, volume, and sets.

### 9.5 Settings and backup

The app includes local backup/export capabilities:

- JSON export of workout entries
- CSV export of workout entries
- JSON import for restoring data
- reset of stored profile and workout data
- media cache clearing

## 10. Assets and seeded content

The app includes local JSON assets for exercises and routines:

- assets/json/fitroute_exercises_detailed.json
- assets/json/fitroute_routines.json

The exercise library is populated from the detailed exercise JSON on first use if the local Hive box is empty.

## 11. Dependencies and tooling

The app is built with the following major packages:

- flutter
- flutter_riverpod
- hive
- hive_flutter
- shared_preferences
- path_provider
- intl
- cached_network_image
- url_launcher

The project also uses build_runner and hive_generator for code generation.

## 12. Implementation notes for contributors

- The app is fully local-only in the current implementation.
- The primary storage and state approach is Hive plus Riverpod.
- UI and business logic are kept in separate layers through screens, services, and state providers.
- Workout entries are the main source of truth for history and analytics.
- Program progress is derived from workout entries rather than a separate persisted session log.
