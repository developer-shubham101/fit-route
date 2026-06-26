# FitRoute — App Flow

> **FitRoute is a personal workout logbook that guides users through workout programs.**
> Everything revolves around recording sets. Programs provide optional structure. The exercise library supports discovery and setup.

---

## Overall Architecture

```
                    Open App
                        │
              ┌─────────┴──────────┐
              ▼                    ▼
        Onboarding            Home Dashboard  ◄─── (if returning user)
        (first run)                 │
              │           ┌─────────┼────────────────┐
              └──────────►│         │                 │
                          ▼         ▼                 ▼
                     Programs   Explore           History
                          │     Exercises             │
                          ▼                           ▼
                    Session Screen              Trends / PRs
                          │
                          ▼
                    Set Entry Screen
                          │
                          ▼
                    Today's Progress
```

---

## First Launch (Onboarding)

```
Open App
    │
    ▼
WelcomeScreen
    │
    ├── Enter profile (age, height, weight, gender, units)
    │       │
    │       ▼
    │   BMI calculated and saved locally
    │
    └── Skip (optional)
    │
    ▼
Home Dashboard
```

- Profile is stored locally via `UserProfileService` → Hive `user_profile` box.
- Onboarding completion is tracked via `onboarding_complete` in SharedPreferences.
- On subsequent launches, `RootRouter` checks `onboardingCompleteProvider` and goes directly to `HomeScreen`.

---

## Home Dashboard

The dashboard is the primary entry point. It is wrapped in a `Scaffold` with an `AppBar` showing a time-based greeting and today's date.

```
┌─────────────────────────────────────┐
│  Good Morning! 💪          Jun 26   │  ← AppBar
├─────────────────────────────────────┤
│  ┌─ Continue Session Banner ──────┐ │  ← shown only when session in progress
│  │  Push Pull Legs · Push Day     │ │
│  │                  [Continue]    │ │
│  └────────────────────────────────┘ │
│                                     │
│  Active Program                     │
│  ┌────────────────────────────────┐ │
│  │  Push Pull Legs         Change │ │
│  │  🎯 Muscle Gain  📶 Intermediate│
│  │  [▶ Start Push Day]            │ │
│  │  [Push Day] [Pull Day] [Legs]  │ │  ← day selector (if multi-day)
│  └────────────────────────────────┘ │
│                                     │
│  This Week                          │
│  [4 days] [120 reps] [2400 kg]      │
│                                     │
│  Today's Workout                    │
│  ┌────────────────────────────────┐ │
│  │  3 sets logged                 │ │
│  │  Push-Ups • 3 sets, 30 reps    │ │
│  └────────────────────────────────┘ │
│                                     │
│  Recent Workout                     │
│  Personal Records                   │
└─────────────────────────────────────┘
```

**Continue Banner** — shown when `activeSessionProvider` is non-null. Tapping "Continue" pushes back into `ProgramSessionScreen` with the saved program + day index.

**Active Program Card** — shown when `activeProgramIdProvider` has a value. Shows metadata chips, a full-width "Start [Day Name]" button, and a horizontal day picker for multi-day programs. "Change" calls `HomeScreenState.setNavIndex(2)` to go to Programs tab.

---

## Bottom Navigation

```
[Home] [Explore] [Programs] [History] [Trends] [Settings]
  0       1          2          3         4         5
```

`HomeScreenState.setNavIndex(n)` is used for programmatic tab switching (public state class).

---

## Programs Tab

### Programs List Screen

```
┌─────────────────────────────────────┐
│  Workout Programs                   │
├─────────────────────────────────────┤
│  🔍 Search programs…                │
│  [Type▼] [Goal▼] [Level▼] [Equip▼] [Location▼] [Clear] │
├─────────────────────────────────────┤
│  ○  Push Pull Legs                  │  ← radio = not active
│     Push Pull Legs · Muscle Gain    │
│     3 days · 40 min · None          │
├─────────────────────────────────────┤
│  ✓  Full Body Beginner              │  ← filled = active program
│     Full Body · General Fitness     │
│     2 days · 25 min · Home          │
└─────────────────────────────────────┘
                                    [+]
```

- Only **one program** can be active at a time.
- Tapping the radio icon toggles active state (persisted to `active_program_id` in SharedPreferences).
- Popup menu per item: Set as Active / Deselect, Edit, Delete.
- Deleting the active program clears `activeProgramIdProvider`.

### Program Detail Screen

```
┌─────────────────────────────────────┐
│  ← Push Pull Legs         ✏️  🗑️   │
├─────────────────────────────────────┤
│  3-day bodyweight split…            │
│  [Push Pull Legs] [🎯 Muscle Gain]  │
│  [📶 Intermediate] [⏱ 40 min]      │
├─────────────────────────────────────┤
│  Push Day                  [Start]  │
│  • Push-Ups  4 × 12                 │
│  • Incline Push-Ups  3 × 10         │
├─────────────────────────────────────┤
│  Pull Day                  [Start]  │
│  • Mountain Climbers  4 × 20        │
├─────────────────────────────────────┤
│  Leg Day                   [Start]  │
│  • Squats  4 × 15                   │
│  • Lunges  3 × 12                   │
└─────────────────────────────────────┘
```

Each day has a dedicated "Start" button that launches `ProgramSessionScreen` for that day index.

### Program Editor Screen

- Fields: Name, Type (dropdown), Description, Goal (dropdown), Level (dropdown), Duration, Equipment, Location, Tags
- Days section: add/remove/rename days
- Per-day exercises: add via `ExercisePickerScreen`, configure via sets/reps/weight/rest dialog
- Save button in AppBar

---

## Workout Session Flow

### Step 1 — Session List (ProgramSessionScreen)

```
┌─────────────────────────────────────┐
│  ← Push Pull Legs · Push Day  00:05 │  ← elapsed timer in AppBar
├─────────────────────────────────────┤
│  Push-Ups                        ✓  │
│  Target: 4 sets × 12 reps           │
│  Completed today:                   │
│  [Set 1: 12 reps] [Set 2: 10 reps]  │
│  [▶ Start Set 3]                    │
├─────────────────────────────────────┤
│  Incline Push-Ups                   │
│  Target: 3 sets × 10 reps           │
│  [▶ Start Set 1]                    │
├─────────────────────────────────────┤
│  Diamond Push-Ups                   │
│  [▶ Start Set 1]                    │
├─────────────────────────────────────┤
│         [✓ Finish Session]          │
└─────────────────────────────────────┘
```

- Session is persisted on init via `activeSessionProvider` (program ID + day index stored in SharedPreferences).
- Today's completed sets are derived from `WorkoutEntry` records matching program ID + today's date.
- Completed sets shown as green chips per exercise card.
- "Finish Session" clears `activeSessionProvider` and pops.

### Step 2 — Set Entry Screen (full-screen push)

```
┌─────────────────────────────────────┐
│  ← Push-Ups — Set 3                 │
├─────────────────────────────────────┤
│                                     │
│              00:45                  │  ← set timer (large)
│           In progress…              │
│                                     │
│         [■ End Set]                 │  ← red when active
│                                     │
│   Reps              Weight (kg)     │
│   [−] [ 12 ] [+]    [−][0 kg][+]   │  ← steppers, tap value to edit
│                                     │
│   ┌─ Rest Timer (after End Set) ─┐  │
│   │  Rest: 00:45    [Skip rest]  │  │
│   └──────────────────────────────┘  │
│                                     │
│   [Submit — 12 reps (bodyweight)]   │  ← disabled until tapped
└─────────────────────────────────────┘
```

- Tap **Start Set** → timer starts.
- Tap **End Set** → timer stops, rest countdown auto-starts.
- **Reps stepper**: − / value / + (tap value to type manually).
- **Weight**: slider with preset steps (0, 2.5, 5 … 100 kg) + stepper buttons + tap-to-type.
- **Submit** → saves `WorkoutEntry` and pops back to session list.

---

## Explore Exercises Tab

```
┌─────────────────────────────────────┐
│  Explore Exercises          [float+]│
│  🔍 Search exercises…               │
│  [Body Part▼][Equipment▼][Diff▼]    │
│  [🏠 Home] [💪 Bodyweight] [Clear]  │
├─────────────────────────────────────┤
│  42 exercises                       │
├─── Arms ②──────────────────────────┤  ← sticky header (flutter_sticky_header)
│  ┌──────────────────────────────┐   │
│  │ [img] Diamond Push-Ups       │   │
│  │       Core · Chest           │   │  ← primary muscles
│  │       [Intermediate][BW][Home]│  │  ← tag pills
│  │       🔥 10 kcal  3×9        │   │
│  └──────────────────────────────┘   │
├─── Back ④──────────────────────────┤
│  ...                                │
└─────────────────────────────────────┘
```

- Grouped alphabetically by `category` with sticky headers (`SliverStickyHeader`).
- Each header shows: category icon, name, exercise count badge.
- Each card shows: thumbnail (image/gif/icon fallback), primary muscles, tag pills (difficulty, type, home, equipment, sets×reps), calorie estimate.
- Long-press or popup menu to Edit / Delete.
- Tap to open `ExerciseDetailPage`.

---

## History Tab

```
┌─────────────────────────────────────┐
│  History                            │
│  🔍  [Exercise▼][Type▼][Date▼]      │
├─────────────────────────────────────┤
│  Today                              │
│  ├─ Push-Ups  3 sets · 34 reps      │
│  └─ Diamond Push-Ups  2 sets        │
├─────────────────────────────────────┤
│  Yesterday                          │
│  ├─ Squats  4 sets · 55 reps        │
│  └─ Lunges  3 sets · 36 reps        │
└─────────────────────────────────────┘
```

- Entries grouped by local calendar date via `groupedEntriesProvider`.
- Filters: exercise, type (Bodyweight/External), date range (today/week/month/all).
- Swipe or menu to edit/delete individual entries.

---

## Trends Tab

```
┌─────────────────────────────────────┐
│  Trends                             │
│  [Overview][By Exercise][By Program]│
├─────────────────────────────────────┤
│  Volume over time (chart)           │
│  Reps over time (chart)             │
│  Sets per day (chart)               │
└─────────────────────────────────────┘
```

Derived entirely from `WorkoutEntry` records via `trends_state.dart`.

---

## Settings Tab

```
Edit Profile       → WelcomeScreen
Theme              → System / Light / Dark
Units              → kg/cm  or  lb/ft
Export JSON        → workout entries backup
Import JSON        → restore from backup
Export CSV         → workout entries CSV
Clear media cache
Reset all data     → clears profile + entries
```

---

## Data Flow Summary

```
SeedService (startup)
    │
    ├── fitroute_exercises_detailed.json → exercises Hive box
    └── fitroute_seed_data.json          → programs + workout_entries Hive boxes

User action
    │
    ▼
ProgramSessionScreen
    │  on set submit
    ▼
WorkoutEntry saved → workout_entries Hive box
    │
    ├── todayEntriesProvider   → Dashboard "Today's Workout"
    ├── weekSummaryProvider    → Dashboard "This Week"
    ├── groupedEntriesProvider → History tab
    ├── personalRecordsProvider→ Dashboard PRs
    └── trends_state providers → Trends tab
```

---

## Active Session Persistence

```
User taps Start Day
    │
    ▼
ProgramSessionScreen.initState()
    → activeSessionProvider.start(programId, dayIndex)
    → writes session_program_id + session_day_index to SharedPreferences

User backgrounds app or navigates away
    → session survives (stored in prefs)

User returns to Dashboard
    → Continue banner appears (reads activeSessionProvider)
    → taps Continue → ProgramSessionScreen reopens

User taps Finish Session
    → activeSessionProvider.clear()
    → removes session keys from SharedPreferences
    → banner disappears
```

---

## Future Features (not yet implemented)

- AI coach reading workout history
- Template recommendations based on usage patterns
- Cloud sync
- Push notifications for rest reminders
- Quick empty workout (no program required)
- Social / sharing features
