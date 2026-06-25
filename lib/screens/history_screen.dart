import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/workout_state.dart';
import '../state/app_state.dart';
import '../state/history_state.dart';
import '../state/routines_state.dart';
import '../utils/units.dart';
import '../models/workout_entry.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final groups = ref.watch(groupedEntriesProvider);
    final filters = ref.watch(historyFiltersProvider);
    final routines = ref.watch(routinesProvider);
    final summary = ref.watch(historySummaryProvider);
    final selectedRoutine = filters.routineId == null
        ? null
        : routines.where((r) => r.id == filters.routineId).cast().isNotEmpty
            ? routines.firstWhere((r) => r.id == filters.routineId)
            : null;
    final exercises = selectedRoutine?.exercises ?? const [];

    Future<void> _editEntryDialog(String id) async {
      final idx = await ref.read(entriesProvider.notifier).findIndexById(id);
      if (idx == null) return;
      final current = ref.read(entriesProvider)[idx];
      final repsController =
          TextEditingController(text: current.reps.toString());
      final units = await ref.read(prefsServiceProvider).getDefaultUnits();
      final weightController = TextEditingController(
        text: current.externalWeight != null
            ? UnitsUtil.fromKg(current.externalWeight!, units)
                .toStringAsFixed(0)
            : '',
      );
      final updated = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Weight (${UnitsUtil.unitLabel(units)})'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                      'reps': int.tryParse(repsController.text),
                      'weight': double.tryParse(weightController.text),
                    }),
                child: const Text('Save')),
          ],
        ),
      );
      if (updated == null) return;
      final newReps = updated['reps'] as int?;
      double? newWeightDisplay = updated['weight'] as double?;
      if (newReps == null || newReps <= 0) return;
      double? newWeightKg;
      if (newWeightDisplay != null && newWeightDisplay > 0) {
        newWeightKg = UnitsUtil.toKg(newWeightDisplay, units);
      }
      final newEntry = WorkoutEntry(
        id: current.id,
        exerciseId: current.exerciseId,
        exerciseName: current.exerciseName,
        routineId: current.routineId,
        type: current.type,
        externalWeight: newWeightKg,
        reps: newReps,
        timestamp: current.timestamp,
        durationSeconds: current.durationSeconds,
      );
      await ref.read(entriesProvider.notifier).updateEntryById(id, newEntry);
    }

    Future<void> _deleteEntry(String id) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete entry?'),
          content: const Text('This cannot be undone.'),
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
        await ref.read(entriesProvider.notifier).deleteEntryById(id);
      }
    }

    Widget dateRangeChips() {
      final options = const [
        {'label': 'All', 'value': 'all'},
        {'label': 'Today', 'value': 'today'},
        {'label': 'Week', 'value': 'week'},
        {'label': 'Month', 'value': 'month'},
      ];
      return Wrap(
        spacing: 8,
        children: options.map((opt) {
          final selected = filters.dateRange == opt['value'];
          return ChoiceChip(
            label: Text(opt['label'] as String),
            selected: selected,
            onSelected: (_) => ref
                .read(historyFiltersProvider.notifier)
                .setDateRange(opt['value'] as String),
          );
        }).toList(),
      );
    }

    Widget filterBar() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search exercise...',
                        isDense: true),
                    onChanged: (v) =>
                        ref.read(historyFiltersProvider.notifier).setQuery(v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: filters.type,
                  hint: const Text('Type'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(
                        value: 'Bodyweight', child: Text('Bodyweight')),
                    DropdownMenuItem(
                        value: 'External', child: Text('External')),
                  ],
                  onChanged: (v) =>
                      ref.read(historyFiltersProvider.notifier).setType(v),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(historyFiltersProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: filters.routineId,
                    decoration: const InputDecoration(
                        isDense: true, labelText: 'Routine'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      ...routines.map((r) => DropdownMenuItem<String?>(
                          value: r.id, child: Text(r.name)))
                    ],
                    onChanged: (v) {
                      ref.read(historyFiltersProvider.notifier).setRoutine(v);
                      // Reset exercise when routine changes
                      ref
                          .read(historyFiltersProvider.notifier)
                          .setExercise(null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: filters.exerciseId,
                    decoration: const InputDecoration(
                        isDense: true, labelText: 'Exercise'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      ...exercises.map((e) => DropdownMenuItem<String?>(
                          value: e.id, child: Text(e.name)))
                    ],
                    onChanged: (v) => ref
                        .read(historyFiltersProvider.notifier)
                        .setExercise(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: dateRangeChips()),
          ],
        ),
      );
    }

    Widget summaryBar(String units) {
      final volumeText = UnitsUtil.formatWeight(summary.totalVolumeKg, units);
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total reps: ${summary.totalReps}'),
            Text('Total volume: $volumeText'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: unitsAsync.when(
        data: (units) {
          return Column(
            children: [
              filterBar(),
              summaryBar(units),
              const Divider(height: 1),
              Expanded(
                child: groups.isEmpty
                    ? const Center(child: Text('No entries match'))
                    : ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, groupIdx) {
                          final group = groups[groupIdx];
                          final dateLabel =
                              '${group.date.year}-${group.date.month.toString().padLeft(2, '0')}-${group.date.day.toString().padLeft(2, '0')}';
                          return ExpansionTile(
                            title: Text(dateLabel),
                            initiallyExpanded: groupIdx == 0,
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              tooltip: 'View detail',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => WorkoutDetailScreen(
                                        group: group)),
                              ),
                            ),
                            children: group.entries.map((e) {
                              final weightText = e.externalWeight != null
                                  ? UnitsUtil.formatWeight(
                                      e.externalWeight, units)
                                  : '';
                              final title = e.externalWeight != null
                                  ? '${e.exerciseName} • ${e.reps} reps @ $weightText'
                                  : '${e.exerciseName} • ${e.reps} reps';
                              return Dismissible(
                                key: ValueKey(e.id),
                                background: Container(
                                  color: Colors.redAccent,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.redAccent,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete entry?'),
                                          content: const Text(
                                              'This cannot be undone.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel')),
                                            ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Delete')),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) async {
                                  final deleted = e;
                                  await ref
                                      .read(entriesProvider.notifier)
                                      .deleteEntryById(e.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Entry deleted'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                            await ref
                                                .read(entriesProvider.notifier)
                                                .addEntry(deleted);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: ListTile(
                                  title: Text(title),
                                  subtitle:
                                      Text(e.timestamp.toLocal().toString()),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _editEntryDialog(e.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteEntry(e.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load units')),
      ),
    );
  }
}
