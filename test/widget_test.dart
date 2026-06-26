import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:fit_route/main.dart';
import 'package:fit_route/models/user_profile.dart';
import 'package:fit_route/models/routine.dart';
import 'package:fit_route/models/exercise.dart';
import 'package:fit_route/models/workout_entry.dart';
import 'package:fit_route/models/program.dart';

void main() {
  setUpAll(() async {
    // Setup temporary directory for Hive in test
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    try {
      Hive.registerAdapter(UserProfileAdapter());
      Hive.registerAdapter(RoutineAdapter());
      Hive.registerAdapter(ExerciseAdapter());
      Hive.registerAdapter(WorkoutEntryAdapter());
      Hive.registerAdapter(ProgramExerciseAdapter());
      Hive.registerAdapter(ProgramDayAdapter());
      Hive.registerAdapter(ProgramAdapter());
    } catch (_) {
      // Adapters might already be registered in some run configurations
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App launches and displays Welcome onboarding screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': false,
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FitRouteApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that onboarding screen shows up
    expect(find.text('Welcome to FitRoute'), findsOneWidget);
    expect(find.text('Let’s set up your profile'), findsOneWidget);
  });
}
