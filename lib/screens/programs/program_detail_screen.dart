import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../state/program_state.dart';
import '../../state/app_state.dart';
import '../../utils/units.dart';
import 'program_editor_screen.dart';
import 'program_session_screen.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final Program program;
  const ProgramDetailScreen({required this.program, super.key});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  String _units = 'metric';

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final u = await ref.read(prefsServiceProvider).getDefaultUnits();
    if (mounted) setState(() => _units = u);
  }

  // get the latest version of this program from state
  Program _latest(WidgetRef ref) {
    final list = ref.watch(programsProvider);
    try {
      return list.firstWhere((p) => p.id == widget.program.id);
    } catch (_) {
      return widget.program;
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = _latest(ref);
    final unitLabel = UnitsUtil.unitLabel(_units);

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProgramEditorScreen(initial: program))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete program?'),
                  content: Text('Delete "${program.name}"?'),
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
                await ref
                    .read(programsProvider.notifier)
                    .deleteById(program.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(program.description,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          // ── metadata chips ──────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (program.type.isNotEmpty) Chip(label: Text(program.type)),
              if (program.goal.isNotEmpty)
                Chip(label: Text('🎯 ${program.goal}')),
              if (program.level.isNotEmpty)
                Chip(label: Text('📶 ${program.level}')),
              if (program.durationMinutes > 0)
                Chip(label: Text('⏱ ${program.durationMinutes} min')),
              for (final eq in program.equipmentNeeded)
                Chip(label: Text('🏋 $eq')),
              for (final loc in program.location)
                Chip(label: Text('📍 $loc')),
              for (final tag in program.tags) Chip(label: Text(tag)),
            ],
          ),
          const SizedBox(height: 12),
          if (program.days.isEmpty)
            const Center(child: Text('No days yet. Edit to add days.'))
          else
            for (int di = 0; di < program.days.length; di++) ...[
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(program.days[di].name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProgramSessionScreen(
                                    program: program, dayIndex: di),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (program.days[di].exercises.isEmpty)
                        const Text('No exercises',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey))
                      else
                        for (final ex in program.days[di].exercises)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              const Icon(Icons.fitness_center, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                    '${ex.exerciseName}  —  ${ex.targetSets} × ${ex.targetReps}'
                                    '${ex.targetWeightKg != null ? ' @ ${UnitsUtil.fromKg(ex.targetWeightKg!, _units).toStringAsFixed(0)} $unitLabel' : ''}',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ]),
                          ),
                    ],
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
