import 'dart:io';
import 'dart:convert';
import 'package:fit_route/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../state/app_state.dart';
import '../state/workout_state.dart';
import '../models/workout_entry.dart';
import '../utils/media.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _units = 'metric';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(prefsServiceProvider);
    final u = await prefs.getDefaultUnits();
    setState(() {
      _units = u;
      _loading = false;
    });
  }

  Future<void> _exportJson() async {
    final entries = await ref.read(workoutEntryServiceProvider).getEntries();

    Map<String, dynamic> entryToMap(WorkoutEntry e) => {
          'id': e.id,
          'exerciseId': e.exerciseId,
          'exerciseName': e.exerciseName,
          'routineId': e.routineId,
          'type': e.type,
          'externalWeight': e.externalWeight,
          'reps': e.reps,
          'timestamp': e.timestamp.toUtc().toIso8601String(),
          'durationSeconds': e.durationSeconds,
        };

    final data = jsonEncode({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'workoutEntries': entries.map(entryToMap).toList(),
    });

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/fitroute_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(data);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
  }

  Future<void> _importJson() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    if (!mounted) return;
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No JSON backup files found')));
      return;
    }

    final selected = await showDialog<File>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select backup file'),
        children: [
          for (final f in files.take(10))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, f),
              child: Text(f.path.split(Platform.pathSeparator).last,
                  overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
    if (selected == null) return;

    try {
      final raw = await selected.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import backup?'),
          content: const Text(
              'This will overwrite existing workout entries.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import')),
          ],
        ),
      );
      if (confirmed != true) return;

      // Import workout entries
      final entryService = ref.read(workoutEntryServiceProvider);
      await entryService.clearAll();
      final rawEntries = (data['workoutEntries'] as List? ?? []);
      for (final e in rawEntries) {
        await entryService.addEntry(WorkoutEntry(
          id: e['id'] ?? '',
          exerciseId: e['exerciseId'] ?? '',
          exerciseName: e['exerciseName'] ?? '',
          routineId: e['routineId'] ?? '',
          type: e['type'] ?? 'Bodyweight',
          externalWeight: (e['externalWeight'] as num?)?.toDouble(),
          reps: (e['reps'] as num?)?.toInt() ?? 0,
          timestamp: DateTime.parse(e['timestamp']),
          durationSeconds: (e['durationSeconds'] as num?)?.toInt() ?? 0,
        ));
      }

      ref.read(entriesProvider.notifier).load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import successful')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
            'This will clear profile and workout entries.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(userProfileServiceProvider).clearProfile();
    await ref.read(workoutEntryServiceProvider).clearAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('All data reset')));
  }

  Future<void> _exportCsv() async {
    final entries = await ref.read(workoutEntryServiceProvider).getEntries();
    final csv = _toCsv(entries);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/fitroute_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
  }

  String _toCsv(List<WorkoutEntry> entries) {
    final buf = StringBuffer();
    buf.writeln(
        'id,routineId,exerciseId,exerciseName,type,externalWeight,reps,timestampUTC,durationSeconds');
    for (final e in entries) {
      buf.writeln(
          '${e.id},${e.routineId},${e.exerciseId},"${e.exerciseName}",${e.type},${e.externalWeight ?? ''},${e.reps},${e.timestamp.toUtc().toIso8601String()},${e.durationSeconds}');
    }
    return buf.toString();
  }

  Future<void> _clearMediaCache() async {
    await MediaUtil.clearCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Media cache cleared')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Edit Profile'),
            subtitle: const Text('Update your personal details'),
            trailing: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Choose app theme'),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(appThemeProvider),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(appThemeProvider.notifier).state = mode;
                }
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Units'),
            subtitle: Text(_units == 'metric' ? 'kg/cm' : 'lb/ft'),
            trailing: DropdownButton<String>(
              value: _units,
              items: const [
                DropdownMenuItem(value: 'metric', child: Text('kg/cm')),
                DropdownMenuItem(value: 'imperial', child: Text('lb/ft')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _units = v);
                await ref.read(prefsServiceProvider).setDefaultUnits(v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Export data (JSON)'),
            subtitle: const Text('Saves workout history as JSON backup'),
            trailing: ElevatedButton.icon(
              onPressed: _exportJson,
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Import data (JSON)'),
            subtitle: const Text('Restore from a JSON backup file'),
            trailing: ElevatedButton.icon(
              onPressed: _importJson,
              icon: const Icon(Icons.upload),
              label: const Text('Import'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Export data (CSV)'),
            subtitle: const Text('Saves a CSV file to app documents directory'),
            trailing: ElevatedButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Clear media cache'),
            subtitle: const Text('Remove cached thumbnails and images'),
            trailing: ElevatedButton.icon(
              onPressed: _clearMediaCache,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Clear'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Reset all data'),
            subtitle:
                const Text('Clears profile and workout entries'),
            trailing: ElevatedButton.icon(
              onPressed: _resetData,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }
}
