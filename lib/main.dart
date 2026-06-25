import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_profile.dart';
import 'models/routine.dart';
import 'models/exercise.dart';
import 'models/workout_entry.dart';
import 'models/program.dart';
import 'screens/root_router.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(RoutineAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(WorkoutEntryAdapter());
  Hive.registerAdapter(ProgramExerciseAdapter());
  Hive.registerAdapter(ProgramDayAdapter());
  Hive.registerAdapter(ProgramAdapter());
  runApp(const ProviderScope(child: FitRouteApp()));
}

// ...existing code...
class FitRouteApp extends ConsumerWidget {
  const FitRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider);
    return MaterialApp(
      title: 'FitRoute',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const RootRouter(),
    );
  }
}
