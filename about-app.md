Nice—this is a great starting spec. I’ll act as your mobile app designer / BA / QA and turn your notes into a cleaned-up, UX-focused feature list, a clear app flow, improved UX suggestions, data model & storage recommendations, QA/acceptance criteria, and a prioritized MVP backlog. At the end I’ll ask two quick clarification questions so I can tailor code or detailed screens if you want the actual Flutter implementation.

# 1 — Product summary (one-liner)

A lightweight cross-platform fitness tracker (Flutter Android + iOS) that lets users create/select routines, start/finish individual exercises (bodyweight or external weight), log reps/weight and track progress locally (with optional later sync). Focus: simple flow, low friction start/stop, clear history & trends.

# 2 — Prioritized feature list (MVP → Nice-to-have → Future)

## MVP (must-have for launch)

1. Welcome / Profile screen with skip

   * Collect Age, Gender, Weight, Height; calculate & show BMI
   * Save locally (SharedPreferences or Hive)
2. Home / Routine list

   * Create/select routine (simple list)
   * View exercises in a routine
3. Exercise start/stop flow

   * Choose type (Bodyweight / External Weight) with conditional weight input
   * Start → Finish → Enter reps → Save `{exercise, type, weight, reps, timestamp}`
4. Local persistence for workouts & profile

   * Use Hive (recommended) or SharedPreferences (simpler, but worse for structured data)
5. History screen

   * List of saved workouts by date with drill-down to exercise entries
6. Basic UX: toasts/snackbars, modal dialogs, Confirmations
7. Basic analytics events (local): StartExercise, FinishExercise, SaveEntry

## Near-term (v1.x)

1. Graphs/trend view (weekly/monthly reps/volume)
2. Edit/delete single workout entries
3. Unit toggle (kg/lb, cm/ft) persisted
4. Routine templates + ability to add custom exercises
5. Export/import (CSV) for backup

## Future / Advanced

1. Cloud sync / account (Firebase)
2. Social sharing / community programs
3. Program builder with rest timers, sets & superset support
4. Integrations: HealthKit / Google Fit
5. Voice commands / hands-free tracking
6. Adaptive suggested programs (AI-driven)

# 3 — Improved app flow (user experience focus)

Use this as the canonical flow — it minimizes friction and keeps users in the exercise flow.

```
[Welcome / Profile] (Skip or Enter) 
    └─ saves profile locally → [Home]

[Home]
  ├─ Routines (select or create) → [Routine Detail]
  ├─ History → [History List]
  └─ Settings → (units, reset data, export, choose storage)

[Routine Detail] (list of exercises)
  └─ Tap exercise → [Exercise Setup Dialog]
           ├─ Choose Type: Bodyweight / External
           ├─ If External: enter weight (with +/- and common presets)
           └─ Start Button

[Active Exercise Screen]
  ├─ Showing exercise name, type, elapsed time, Start/Finish toggle
  └─ When Finish tapped → [Enter Reps Dialog]
          └─ Save (success toast) → Back to [Routine Detail]

[History]
  ├─ Calendar / List by date
  └─ Tap item → detail with edit/delete
```

# 4 — Key UX improvements and justifications

1. **Skip on welcome** — lowers barrier to entry. Still show a subtle prompt later to complete profile.
2. **Inline presets for external weight** — one-tap common weights speeds input (e.g., 5, 10, 15 kg).
3. **Persist last-used weight per exercise** — users rarely reuse random weights; prefill last used to reduce typing.
4. **One-tap start** — avoid extra screens. Use a small modal for type selection, then directly show an active mini-timer/indicator.
5. **Minimal friction for reps** — use large numeric stepper and quick presets (e.g., +1, +5 buttons) and optional keyboard.
6. **Clear feedback on save** — toast + subtle animation so users are confident their set saved.
7. **Undo for 5 seconds after save** — prevents accidental entries and improves trust.
8. **Unit toggle visible in the exercise dialog** — avoids conversions mid-flow.
9. **Empty-state guidance** — for new users show sample routine & how-to microcopy.
10. **Accessibility** — large touch targets, correct labels, color contrast, screen reader text.

# 5 — Data model & storage recommendation

**Recommendation**: Use **Hive** for structured, performant local storage (good for lists and query), with a small SharedPreferences usage for simple flags (onboarding complete, units).

Example schema (pseudo-JSON):

`UserProfile`

```json
{
  "id": "profile_1",
  "age": 28,
  "gender": "female",
  "weight": 72.5,
  "weight_unit": "kg",
  "height": 175,
  "height_unit": "cm",
  "bmi": 23.7,
  "last_updated": "2025-08-11T10:00:00Z"
}
```

`WorkoutEntry` (one saved record per exercise finish)

```json
{
  "id": "entry_20250811_001",
  "exercise_id": "pushup_01",
  "exercise_name": "Push Up",
  "routine_id": "morning_bodyweight",
  "type": "Bodyweight",            // or "External"
  "external_weight": null,         // or number
  "reps": 12,
  "timestamp": "2025-08-11T10:15:00Z",
  "meta": {"duration_seconds": 45}
}
```

`Routine` and `Exercise` objects stored separately for ease of editing.

# 6 — Events / analytics to track (local + optional remote)

* `onboarding_completed` (skipped: true/false)
* `start_exercise` (`exercise_id`, `type`)
* `finish_exercise` (`exercise_id`, `type`, `reps`, `external_weight`)
* `save_entry` (`entry_id`)
* `edit_entry` / `delete_entry`
* `export_data`

Keep analytics lightweight in MVP; store events locally and batch-upload if/when cloud is integrated.

# 7 — Edge cases & validations (must-have QA items)

1. If user enters unrealistic height/weight values — show validation & friendly message (e.g., "That seems off. Are you sure?").
2. If external weight is left blank when External selected — prevent Start (or prompt).
3. If app is backgrounded during active exercise — preserve state and allow resume.
4. Timezone handling — store timestamps in ISO UTC and convert to local on display.
5. Duplicate saves — disable Save button while saving; show toast on success.
6. Corrupted storage — provide a safe reset option in settings.

# 8 — QA acceptance criteria (sample for core flows)

**Onboarding**

* Given a new user, the welcome screen allows skip and saves profile when Continue pressed; BMI shown correctly using formula `weight(kg)/height(m)^2`.

**Exercise start/stop**

* Tapping exercise opens modal. Choosing External and entering weight enables Start.
* Pressing Start toggles to Finish. Press Finish opens reps dialog.
* After entering reps and saving, a new WorkoutEntry is persisted with correct timestamp and values.

**History**

* History lists entries by date. Tapping an entry opens detail showing exercise, type, weight (if any), reps and timestamp.
* User can delete an entry; deletion removes it from storage.

# 9 — Testing checklist (short)

* Unit tests: BMI calculation, storage CRUD
* Integration: Start → Finish → Save cycle
* UI tests: Onboarding skip, modal behavior, unit toggle
* Manual: Background/resume during active exercise, time accuracy, undo save

# 10 — Developer / Flutter implementation notes (packages & architecture)

* State management: `riverpod` or `provider` (I prefer Riverpod for scaling)
* Local storage: **Hive** (fast, supports complex objects) + `hive_flutter`
* Simple prefs: `shared_preferences` for small flags
* Date handling: `intl` or `timezone` packages as needed
* Optional: `flutter_local_notifications` for reminders
* Keep UI decoupled: services for storage, repository pattern, and unit tests around repositories

# 11 — Suggested screen list + components

1. Welcome / Profile (form, skip)
2. Home (routines grid/list, quick start suggested routine)
3. Routine Detail (exercise list)
4. Exercise Setup Modal (radio + conditional weight input + presets)
5. Active Exercise Mini Screen (name, elapsed, Finish button)
6. Enter Reps Dialog (numeric input + presets + save)
7. History (calendar or grouped list)
8. Settings (units, export, reset, storage method)
9. Edit Entry screen

# 12 — Example user flows (short)

* Quick start: Skip onboarding → Home → Suggested routine → Tap exercise → Start with Bodyweight → Finish → Enter 15 reps → Saved → See entry in History.
* Prefilled weight: Tap Bench Press → External selected (prefilled 40kg from last use) → Start → Finish → Enter 8 reps → Save.

# 13 — Deliverables I can provide next

* Option A: Full ready-to-run Flutter project (Dart + Hive + Riverpod) implementing MVP flows (Welcome, Routine list, Start/Finish, History). — **I will provide full code files.**
* Option B: Smaller code bundle: Welcome screen widget, Exercise Start/Finish widget & storage service (ready to drop into an existing project).
* Option C: UX wireframes (Figma-ready spec text) and annotated screens (no code).
* Option D: QA test-suite (unit + widget test templates) and Cypress-like test plan.

Which of the options above would you like me to produce now?
Bonus Qs that will help me deliver exact code or screens:

1. Do you want **cloud sync / user accounts** in scope now or strictly local-only for MVP?
2. Preferred units default: **kg/cm** or **lb/ft**? (I'll include a unit toggle either way.)

If you say “Yes — give me the upgraded code (Option A or B)”, I’ll produce a ready-to-run Flutter app (or the selected widgets) with clear file structure and instructions to run.
