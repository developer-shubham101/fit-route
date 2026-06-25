# FitRoute — Deferred / TODO Backlog

- [ ] Cloud sync and account system
  - [ ] Repository abstraction with API implementations (Firebase or REST)
  - [ ] Auth (email/OAuth), secure local token storage
  - [ ] Background sync and conflict resolution

- [ ] Media & caching
  - [ ] Settings option to clear media cache
  - [ ] Prefetch thumbnails for Explore grid/list
  - [ ] Local bundled media/fallbacks for known exercises
  - [x] Use placeholder asset for missing media (workout_placeholder.png)

- [ ] Data export/import & backup
  - [ ] CSV import (parity with export)
  - [ ] Encrypted local backup/restore
  - [ ] Cloud backup (Drive/iCloud)

- [ ] Trends & charts (upgrade)
  - [ ] Replace simple bars with `fl_chart` or similar
  - [ ] Filters (routine / exercise / type) on Trends
  - [ ] Week-over-week and month-over-month comparisons

- [ ] Exercise flow polish
  - [ ] Inline unit toggle in setup sheet
  - [ ] Rest timer and set presets (+1/+5 quick actions)
  - [ ] Haptics, sounds, better toasts

- [ ] History enhancements
  - [x] Swipe delete with undo
  - [ ] Entry detail screen (inline edit)
  - [ ] Advanced filters (date range picker)

- [ ] Explore exercises (enhancements)
  - [ ] Categories/tags and filters by equipment/body part
  - [ ] Admin UI to bulk edit library entries
  - [ ] Offline-first media strategy

- [ ] Routines management
  - [ ] Routine templates from cloud catalog
  - [ ] Duplicate routine; export/import routine
  - [ ] Drag-and-drop reorder between routines

- [ ] Settings
  - [ ] Clear media cache option
  - [ ] Theme (dark/light/system), typography scale
  - [ ] Unit conversion behavior settings (store vs display)

- [ ] Onboarding polish
  - [ ] Progressive prompts to complete profile later
  - [ ] Better empty states and sample walkthrough

- [ ] Accessibility & i18n
  - [ ] Screen reader labels, larger touch targets, contrast audit
  - [ ] Localization scaffolding and first translation

- [ ] Notifications & reminders
  - [ ] Workout reminders, streaks, and motivation nudges

- [ ] Quality & testing
  - [ ] Unit tests (storage CRUD, BMI, converters)
  - [ ] Widget tests (onboarding, history edit/delete)
  - [ ] Integration tests (start → finish → save)
  - [ ] Error handling and telemetry pipeline

- [ ] Platform polish
  - [ ] Custom app icon/splash and branding
  - [ ] Deep links and share intents
  - [ ] Desktop/web responsive layouts

- [ ] Security & privacy
  - [ ] Data reset confirmations and secure wipes
  - [ ] Privacy policy and analytics controls
