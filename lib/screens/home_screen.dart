import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/routines_state.dart';
import 'routine_detail_screen.dart';
import 'new_routine_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'trends_screen.dart';
import 'programs/programs_screen.dart';
import 'explore/explore_exercises_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _HomeTab(),
          ExploreExercisesScreen(),
          HistoryScreen(),
          TrendsScreen(),
          ProgramsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Trends'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Programs'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ── Home tab: Dashboard + Routines tabs ───────────────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitRoute'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.list), text: 'Routines'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardScreen(),
          _RoutinesTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 1) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewRoutineScreen()),
            ),
            tooltip: 'Add Routine',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

// ── Routines tab ──────────────────────────────────────────────────────────────
class _RoutinesTab extends ConsumerStatefulWidget {
  const _RoutinesTab();

  @override
  ConsumerState<_RoutinesTab> createState() => _RoutinesTabState();
}

class _RoutinesTabState extends ConsumerState<_RoutinesTab> {
  String selectedGoal = 'All';
  String selectedLevel = 'All';
  String selectedEquipment = 'All';

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routinesProvider);

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

    final filtered = routines.where((r) {
      if (selectedGoal != 'All' && r.goal != selectedGoal) return false;
      if (selectedLevel != 'All' && r.level != selectedLevel) return false;
      if (selectedEquipment != 'All' &&
          !r.equipmentNeeded.contains(selectedEquipment)) return false;
      return true;
    }).toList();

    Future<void> renameDialog(String routineId, String current) async {
      final ctrl = TextEditingController(text: current);
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Routine'),
          content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Routine name')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
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

    Future<void> confirmDelete(int index, String name) async {
      final ok = await showDialog<bool>(
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
      if (ok == true) {
        await ref.read(routinesProvider.notifier).deleteRoutineAt(index);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  if (v != null) setState(() => selectedGoal = v);
                },
              ),
              DropdownButton<String>(
                value: selectedLevel,
                items: levels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedLevel = v);
                },
              ),
              DropdownButton<String>(
                value: selectedEquipment,
                items: equipmentSet
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedEquipment = v);
                },
              ),
              TextButton(
                onPressed: () => setState(() {
                  selectedGoal = 'All';
                  selectedLevel = 'All';
                  selectedEquipment = 'All';
                }),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              RoutineDetailScreen(routineId: routine.id)),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          renameDialog(routine.id, routine.name);
                        } else if (value == 'delete') {
                          confirmDelete(idx, routine.name);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
