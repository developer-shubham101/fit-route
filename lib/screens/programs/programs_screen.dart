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
        await ref.read(programsProvider.notifier).deleteById(p.id);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Programs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search programs'),
              onChanged: (v) =>
                  ref.read(programSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: programs.isEmpty
                ? const Center(
                    child: Text('No programs yet. Tap + to create one.'))
                : ListView.separated(
                    itemCount: programs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final p = programs[idx];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                            '${p.type}  •  ${p.days.length} day${p.days.length == 1 ? '' : 's'}'),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProgramDetailScreen(program: p))),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProgramEditorScreen(
                                            initial: p,
                                          )));
                            } else if (v == 'delete') {
                              await deleteProgram(p);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
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
            MaterialPageRoute(
                builder: (_) => const ProgramEditorScreen())),
        child: const Icon(Icons.add),
        tooltip: 'New Program',
      ),
    );
  }
}
