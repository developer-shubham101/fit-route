import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/program_state.dart';
import '../../models/program.dart';
import 'program_editor_screen.dart';
import 'program_detail_screen.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(filteredProgramsProvider);
    final allPrograms = ref.watch(programsProvider);
    final filters = ref.watch(programFiltersProvider);
    final activeProgramId = ref.watch(activeProgramIdProvider);

    final types = <String>{for (final p in allPrograms) if (p.type.isNotEmpty) p.type}.toList()..sort();
    final goals = <String>{for (final p in allPrograms) if (p.goal.isNotEmpty) p.goal}.toList()..sort();
    final levels = <String>{for (final p in allPrograms) if (p.level.isNotEmpty) p.level}.toList()..sort();
    final equipments = <String>{for (final p in allPrograms) ...p.equipmentNeeded}.toList()..sort();
    final locations = <String>{for (final p in allPrograms) ...p.location}.toList()..sort();

    Future<void> deleteProgram(Program p) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete program?'),
          content: Text('Delete "${p.name}"?'),
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
        if (activeProgramId == p.id) {
          await ref.read(activeProgramIdProvider.notifier).setActive(null);
        }
        await ref.read(programsProvider.notifier).deleteById(p.id);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Programs')),
      body: Column(
        children: [
          // ── Search ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search programs',
                  isDense: true),
              onChanged: (v) =>
                  ref.read(programFiltersProvider.notifier).setQuery(v),
            ),
          ),
          // ── Filters ─────────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _FilterDrop('Type', filters.type, types,
                    (v) => ref.read(programFiltersProvider.notifier).setType(v)),
                const SizedBox(width: 8),
                _FilterDrop('Goal', filters.goal, goals,
                    (v) => ref.read(programFiltersProvider.notifier).setGoal(v)),
                const SizedBox(width: 8),
                _FilterDrop('Level', filters.level, levels,
                    (v) => ref.read(programFiltersProvider.notifier).setLevel(v)),
                const SizedBox(width: 8),
                _FilterDrop('Equipment', filters.equipment, equipments,
                    (v) => ref.read(programFiltersProvider.notifier).setEquipment(v)),
                const SizedBox(width: 8),
                _FilterDrop('Location', filters.location, locations,
                    (v) => ref.read(programFiltersProvider.notifier).setLocation(v)),
                if (!filters.isEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(programFiltersProvider.notifier).clear(),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: programs.isEmpty
                ? const Center(
                    child: Text('No programs yet. Tap + to create one.'))
                : ListView.separated(
                    itemCount: programs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final p = programs[idx];
                      final isActive = p.id == activeProgramId;
                      return ListTile(
                        leading: GestureDetector(
                          onTap: () => ref
                              .read(activeProgramIdProvider.notifier)
                              .setActive(isActive ? null : p.id),
                          child: Icon(
                            isActive
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                        title: Text(p.name,
                            style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        subtitle: _ProgramSubtitle(p),
                        isThreeLine: true,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProgramDetailScreen(program: p))),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'select') {
                              ref
                                  .read(activeProgramIdProvider.notifier)
                                  .setActive(isActive ? null : p.id);
                            } else if (v == 'edit') {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProgramEditorScreen(initial: p)));
                            } else if (v == 'delete') {
                              await deleteProgram(p);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'select',
                                child: Text(
                                    isActive ? 'Deselect' : 'Set as Active')),
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProgramEditorScreen())),
        tooltip: 'New Program',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProgramSubtitle extends StatelessWidget {
  final Program p;
  const _ProgramSubtitle(this.p);

  @override
  Widget build(BuildContext context) {
    final line1Parts = <String>[
      p.type,
      if (p.goal.isNotEmpty) p.goal,
      if (p.level.isNotEmpty) p.level,
    ];
    final line2Parts = <String>[
      '${p.days.length} day${p.days.length == 1 ? '' : 's'}',
      if (p.durationMinutes > 0) '${p.durationMinutes} min',
      if (p.equipmentNeeded.isNotEmpty) p.equipmentNeeded.join(', '),
      if (p.location.isNotEmpty) p.location.join(', '),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line1Parts.join(' · '),
            style: const TextStyle(fontSize: 12)),
        Text(line2Parts.join(' · '),
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _FilterDrop extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final void Function(String?) onChanged;
  const _FilterDrop(this.label, this.value, this.options, this.onChanged);

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return DropdownButton<String?>(
      value: value,
      hint: Text(label, style: const TextStyle(fontSize: 13)),
      isDense: true,
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('All $label')),
        for (final o in options)
          DropdownMenuItem<String?>(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
    );
  }
}
