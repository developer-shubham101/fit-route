import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/routines_state.dart';
// ...existing code...
import 'routine_detail_screen.dart';
import 'history_screen.dart';
import '../state/workout_state.dart';
import 'settings_screen.dart';
import 'trends_screen.dart';
import 'explore/explore_exercises_screen.dart';
import 'new_routine_screen.dart';
import 'programs/programs_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedGoal = 'All';
  String selectedLevel = 'All';
  String selectedEquipment = 'All';

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    // Preload entries
    ref.read(entriesProvider.notifier).load();

    final routines = ref.watch(routinesProvider);

    // Build filter option lists from available routines
    final goals = <String>{'All'}
      ..addAll(routines.map((r) => r.goal).where((g) => g.isNotEmpty));
    final levels = <String>{'All'}
      ..addAll(routines.map((r) => r.level).where((l) => l.isNotEmpty));
    final equipmentSet = <String>{'All'};
    for (final r in routines) {
      for (final e in r.equipmentNeeded) {
        if (e.trim().isNotEmpty) equipmentSet.add(e);
      }
    }
    final equipments = equipmentSet.toList();

    // Apply filters
    final filtered = routines.where((r) {
      if (selectedGoal != 'All' && r.goal != selectedGoal) return false;
      if (selectedLevel != 'All' && r.level != selectedLevel) return false;
      if (selectedEquipment != 'All' &&
          !r.equipmentNeeded.contains(selectedEquipment)) return false;
      return true;
    }).toList();

    // ...existing code...

    Future<void> renameRoutineDialog(
        String routineId, String currentName) async {
      final nameController = TextEditingController(text: currentName);
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename Routine'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Routine name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('Save')),
          ],
        ),
      );
      if (result != null && result.trim().isNotEmpty) {
        await ref
            .read(routinesProvider.notifier)
            .renameRoutine(routineId, result.trim());
      }
    }

    Future<void> confirmDeleteRoutine(int index, String name) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete routine?'),
          content: Text('Delete "$name" and all its exercises?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(routinesProvider.notifier).deleteRoutineAt(index);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('FitRoute Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Routines',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ExploreExercisesScreen()));
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explore'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filters: Goal, Level, Equipment
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                DropdownButton<String>(
                  value: selectedGoal,
                  items: goals
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedGoal = v);
                  },
                ),
                DropdownButton<String>(
                  value: selectedLevel,
                  items: levels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedLevel = v);
                  },
                ),
                DropdownButton<String>(
                  value: selectedEquipment,
                  items: equipments
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedEquipment = v);
                  },
                ),
                TextButton(
                  onPressed: () => setState(() {
                    selectedGoal = 'All';
                    selectedLevel = 'All';
                    selectedEquipment = 'All';
                  }),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (routines.isEmpty)
              const Text('No routines yet. Tap + to add your first routine.')
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final routine = filtered[idx];
                    return ListTile(
                      title: Text(routine.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${routine.exercises.length} exercises'),
                          Text(
                              'Goal: ${routine.goal.isNotEmpty ? routine.goal : '—'}  •  Level: ${routine.level.isNotEmpty ? routine.level : '—'}'),
                          Text(
                              'Equipment: ${routine.equipmentNeeded.isNotEmpty ? routine.equipmentNeeded.join(', ') : 'None'}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RoutineDetailScreen(
                                    routineId: routine.id)));
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') {
                            renameRoutineDialog(routine.id, routine.name);
                          } else if (value == 'delete') {
                            confirmDeleteRoutine(idx, routine.name);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProgramsScreen()));
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Programs'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()));
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrendsScreen()));
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Trends'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()));
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NewRoutineScreen()));
        },
        tooltip: 'Add Routine',
        child: const Icon(Icons.add),
      ),
    );
  }
}
