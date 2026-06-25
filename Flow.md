I think we've reached the point where the app has a clear identity. It's **not** a calorie tracker, **not** a bodybuilding coach, and **not** just an exercise library.

> **FitRoute is a Personal Workout Logbook that can optionally guide users through workout templates.**

That means **everything revolves around recording workouts**, and templates are just one way to start a workout.

---

# Overall Architecture

```text
                Onboarding
                     │
                     ▼
              Exercise Library
                     │
                     ▼
            Workout Templates
        (Built-in + User Created)
                     │
                     ▼
              Home Dashboard
                     │
     ┌───────────────┼────────────────┐
     ▼               ▼                ▼
Start Today's     Quick Workout   Browse Exercises
Template             (Empty)           (Single)
     │               │                │
     └───────────────┼────────────────┘
                     ▼
             Workout Session
                     ▼
              Workout History
                     ▼
            Personal Records
                     ▼
             Progress Graphs
                     ▼
        AI Coach (Future Version)
```

---

# First Launch

```text
Open App

↓

Welcome

↓

Basic Profile

• Age
• Height
• Weight
• Gender
• Units

↓

Optional

Choose Fitness Goal

• Gain Muscle

• Lose Fat

• Strength

• Endurance

• General Fitness

↓

Skip

↓

Home
```

Notice

The goal is **optional**.

---

# Home Screen

The Home screen has one responsibility.

> Help the user start today's workout.

```text
──────────────────────────

Good Morning

──────────────────────────

Today's Suggestion

Push Day

START

──────────────────────────

OR

Quick Workout

START EMPTY WORKOUT

──────────────────────────

OR

Browse Exercises

──────────────────────────

Recent Workout

Chest Day

Yesterday

──────────────────────────

Weekly Summary

4 workouts

──────────────────────────
```

No clutter.

---

# Starting a Workout

Three entry points.

## Option 1

Current Template

```text
Home

↓

Today's Suggestion

↓

START
```

---

## Option 2

Quick Workout

```text
Home

↓

Start Empty Workout

↓

Select Exercises

↓

Workout
```

---

## Option 3

Single Exercise

```text
Home

↓

Browse Exercises

↓

Bench Press

↓

START
```

---

# Exercise Library

Contains

```text
Built-in

+

Custom Exercises
```

User can

```text
Search

Filter

Browse

Create

Edit

Delete
```

This screen is only for planning.

Never during workouts.

---

# Workout Templates

This replaces both

✔ Programs

✔ Routines

A Workout Template contains

```text
Name

Description

Goal

Difficulty

Days per Week

Exercises

Sets

Reps

Weight

Rest

Notes

Tags
```

Example

```text
Push Pull Legs

Intermediate

4 Days

Gym

Strength

45 Minutes
```

---

# Template Discovery

Instead of showing hundreds of templates,

show categories first.

```text
Goals

↓

Gain Muscle

Lose Fat

Strength

Endurance

General Fitness

Home

Custom
```

Then

```text
Gain Muscle

↓

Beginner

Intermediate

Advanced
```

Then

```text
Beginner

↓

Recommended

Popular

Newest
```

Every template remains selectable.

---

# Active Template

Only one template can be active.

```text
Current

Push Pull Legs

Week 3

Day 2
```

User can

```text
Continue

Restart

Change Template
```

Changing doesn't delete history.

---

# Workout Session

This becomes the heart of the app.

```text
Workout Started

↓

Exercise 1

↓

Set 1

↓

Save

↓

Rest

↓

Set 2

↓

Rest

↓

Exercise Complete

↓

Next Exercise

↓

Finish Workout

↓

Summary
```

No searching.

No editing.

No dialogs.

---

# Workout Summary

Only session information.

```text
Workout Complete

Time

Sets

Volume

Exercises

Notes

Save
```

Nothing about goals.

---

# History

History is a logbook.

```text
June 20

Push Day

18 Sets

58 Minutes

────────────────

June 18

Leg Day

────────────────

June 16

Quick Workout
```

Users open History to remember

"What did I do that day?"

---

# Personal Records

This is different from History.

It answers

> What's my best performance?

```text
Bench Press

Best Weight

100kg

────────────

Squat

Best Weight

140kg

────────────

Deadlift

180kg

────────────

Push Ups

50 reps

────────────

Longest Plank

6 minutes
```

---

# Progress

This is the long-term view.

Not goals.

Not achievements.

Only comparisons.

Example

```text
Bench Press

First Workout

20kg

↓

Today

100kg
```

Another

```text
Push Ups

Started

5

↓

Today

50
```

Graphs can switch between

* Weight
* Reps
* Sets
* Volume
* Rest Time

---

# Template Recommendations

The app never forces users.

It simply observes.

Example

```text
You have used

Push Pull Legs

for

14 weeks.

Try

Upper Lower Split
```

or

```text
You've completed

Beginner Strength

You might enjoy

5x5 Strength
```

User decides.

---

# Users Without Templates

Some people never follow a program.

That's perfectly supported.

Their flow is

```text
Home

↓

Start Empty Workout

↓

Choose Exercises

↓

Workout

↓

History

↓

Progress
```

They still get

* Personal Records
* Progress
* History
* Graphs

Exactly like template users.

---

# Future AI

AI doesn't replace the app.

It reads the logbook.

```text
Workout History

+

Exercise Progress

+

Personal Records

↓

AI

↓

Analysis

↓

Suggestions

↓

Questions

↓

Future Templates
```

Examples

> Your Bench Press increased from 60kg to 85kg over the last four months.

> Your rest time has decreased by 40 seconds while maintaining the same volume.

> Your squat hasn't improved in six weeks. Consider reducing volume or increasing recovery.

---

# Final User Flow

```text
                    Open App
                        │
                        ▼
                  Home Dashboard
                        │
        ┌───────────────┼────────────────┐
        ▼               ▼                ▼
 Today's Template   Quick Workout   Browse Exercise
        │               │                │
        └───────────────┼────────────────┘
                        ▼
                 Workout Session
                        │
                        ▼
                 Workout Summary
                        │
                        ▼
                 Workout History
                        │
                        ▼
               Personal Records
                        │
                        ▼
                 Progress Graphs
                        │
                        ▼
             Template Suggestions
                        │
                        ▼
                AI Coach (Future)
```

## One last suggestion that I think will define the app

I would stop thinking of **Workout Templates** as the primary feature.

Instead, make **Workout Sessions** the primary feature.

Everything else exists to help the user start a workout session:

* The **Exercise Library** helps build workouts.
* **Workout Templates** provide reusable plans.
* The **Home Dashboard** gets users into today's session quickly.
* **History** remembers every session.
* **Personal Records** summarize the best performances from all sessions.
* **Progress** visualizes improvements across sessions.
* **AI** analyzes sessions in the future.

That keeps the app centered on the activity users care about most: recording and improving their workouts.
