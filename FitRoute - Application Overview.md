# FitRoute - Application Overview

## Primary Vision

Build a completely offline fitness application that allows users to record workouts, follow workout programs, monitor progress, and later integrate AI for personalized fitness insights.

---

# Core Goals

## 1. User Onboarding

* Collect basic user information.
* Store age, height, weight, gender, etc.
* Calculate BMI.
* Store user profile locally.

---

## 2. Exercise Explorer

* Browse all exercises.
* Search exercises.
* Filter exercises by:

  * Body part
  * Equipment
  * Difficulty
  * Beginner / Intermediate / Advanced
  * Other filters
* Exercise details include:

  * Instructions
  * Equipment
  * Difficulty
  * Body part
  * Media (image/GIF/video)
  * Other useful information

---

## 3. Free Workout Tracking

Users can start a workout without following any predefined plan.

Features:

* Start workout session.
* Track workout start/end time.
* Track workout duration.
* Track workout date.
* Add exercises during workout.
* Record:

  * Sets
  * Repetitions
  * Weight
  * Bodyweight exercises
* Record rest duration between every set.
* Store complete workout history.

---

## 4. Workout Programs

Support predefined workout plans.

Programs may be created by:

* Application
* Fitness experts
* Users

Programs may represent:

* Full body
* Push Pull Legs
* Chest Day
* Back Day
* Any custom split

Each exercise contains:

* Target sets
* Target reps
* Target weight
* Target rest duration

While following a program:

* User performs the planned workout.
* App stores actual performance.
* Planned values and actual values are stored separately.
* User progresses through the program day by day.

---

## 5. Progress Tracking

Users can monitor improvements over time.

Time filters:

* Daily
* Weekly
* Monthly
* Yearly
* Custom range

Progress can be viewed by:

* Exercise
* Weight
* Repetitions
* Sets
* Rest duration

Charts should remain simple.

If following a predefined program:

* Compare Target vs Actual.
* Show whether user met the planned progression.

---

## 6. Offline First

* No backend.
* No admin panel.
* No server.
* Everything stored locally.
* Import data.
* Export data.
* Support formats like JSON/XML (or similar).

---

## 7. Future AI Integration

Future versions will integrate AI.

Users may:

* Share workout history with AI.
* Share workout programs.
* Ask questions about progress.
* Receive analysis and recommendations based on stored workout history.

---

# Current Implementation Review

## ✅ Implemented

### User

* Onboarding
* Profile storage
* BMI calculation

### Exercise Library

* Browse exercises
* Search exercises
* Exercise details
* Add/Edit/Delete exercises
* Media support
* Exercise categorization

### Workout

* Create routines
* Add exercises to routines
* Start workout
* Record repetitions
* Record external weight
* Track workout duration
* Store workout history

### History

* Workout history
* Edit history
* Delete history
* Filters
* Search
* Summary

### Progress

* Weekly graphs
* Monthly graphs
* Volume tracking
* Repetition tracking

### Settings

* Theme
* Units
* Export
* Reset
* Offline storage

---

## 🚧 Partially Implemented

### Workout Tracking

* Workout session exists.
* Exercise tracking exists.
* Weight tracking exists.
* Duration tracking exists.

Missing compared to goal:

* Multiple sets per exercise
* Rest timer between sets
* Workout-level tracking
* Complete exercise session flow

### Progress

Basic charts exist.

Missing compared to goal:

* Exercise-specific progression
* Daily/Yearly comparison
* Target vs Actual comparison
* Program progress visualization
* Rest-duration analytics

---

## ❌ Not Implemented

### Workout Programs

* Program creation
* Program editor
* Expert-created programs
* User-created programs
* Program sharing
* Program execution
* Target vs Actual tracking
* Program day progression

### Offline Data

* Import
* JSON import/export
* XML support

### AI

* AI integration
* AI progress analysis
* AI recommendations
* AI conversation using workout history
