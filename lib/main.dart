import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_profile.dart';
import 'models/exercise.dart';
import 'models/workout_entry.dart';
import 'models/program.dart';
import 'screens/root_router.dart';
import 'state/app_state.dart';
import 'services/exercise_service.dart';
import 'services/seed_service.dart';
import 'services/workout_entry_service.dart';
import 'services/program_service.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(WorkoutEntryAdapter());
  Hive.registerAdapter(ProgramExerciseAdapter());
  Hive.registerAdapter(ProgramDayAdapter());
  Hive.registerAdapter(ProgramAdapter());
  // Seed sample data on first run
  await SeedService(
    ExerciseService(),
    WorkoutEntryService(),
    ProgramService(),
    PrefsService(),
  ).seedIfNeeded();
  runApp(const ProviderScope(child: FitRouteApp()));
}

// ...existing code...
class FitRouteApp extends ConsumerWidget {
  const FitRouteApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = isLight
        ? const ColorScheme.light(
            primary: Color(0xFFD32F2F),
            onPrimary: Colors.white,
            secondary: Color(0xFF1565C0),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            error: Color(0xFFB71C1C),
            onError: Colors.white,
          )
        : const ColorScheme.dark(
            primary: Color(0xFFEF5350),
            onPrimary: Colors.black,
            secondary: Color(0xFF42A5F5),
            onSecondary: Colors.black,
            surface: Color(0xFF121212),
            onSurface: Colors.white,
            error: Color(0xFFEF9A9A),
            onError: Colors.black,
          );

    const buttonTextStyle = TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
    const buttonAlignment = Alignment.center;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          alignment: buttonAlignment,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          alignment: buttonAlignment,
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          alignment: buttonAlignment,
          textStyle: buttonTextStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          alignment: buttonAlignment,
          textStyle: buttonTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider);
    return MaterialApp(
      title: 'FitRoute',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: const RootRouter(),
    );
  }
}
