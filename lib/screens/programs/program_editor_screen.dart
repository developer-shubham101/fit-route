import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/program.dart';
import '../../state/program_state.dart';
import '../../state/app_state.dart';
import '../../utils/units.dart';

class ProgramEditorScreen extends ConsumerStatefulWidget {
  final Program? initial;
  const ProgramEditorScreen({this.initial, super.key});

  @override
  ConsumerState<ProgramEditorScreen> createState() =>
      _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends ConsumerState<ProgramEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'Custom';
  late List<_DayEdit> _days;
  String _units = 'metric';

  static const _types = [
    'Full Body',
    'Push Pull Legs',
    'Chest',
    'Back',
    'Legs',
    'Shoulder',
    'Arms',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _type = p.type;
      _days = p.days.map((d) => _DayEdit.fromDay(d)).toList();
    } else {
      _days = [_DayEdit(name: 'Day 1', exercises: [])];
    }
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final u = await ref.read(prefsServiceProvider).getDefaultUnits();
    if (mounted) setState(() => _units = u);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a program name')));
      return;
    }
    final program = Program(
      id: widget.initial?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      type: _type,
      description: _descCtrl.text.trim(),
      days: _days.map((d) => d.toDay()).toList(),
    );
    if (widget.initial == null) {
      await ref.read(programsProvider.notifier).add(program);
    } else {
      await ref
          .read(programsProvider.notifier)
          .updateById(widget.initial!.id, program);
    }
    if (mounted) Navigator.pop(context, true);
  }

  void _addDay() {
    setState(
        () => _days.add(_DayEdit(name: 'Day ${_days.length + 1}', exercises: [])));
  }

  void _removeDay(int i) {
    setState(() {
      _days[i].dispose();
      _days.removeAt(i);
    });
  }

  Future<void> _addExercise(int dayIdx) async {
    final result = await showExerciseDialog(context, null, _units);
    if (result != null) setState(() => _days[dayIdx].exercises.add(result));
  }

  Future<void> _editExercise(int dayIdx, int exIdx) async {
    final result = await showExerciseDialog(
        context, _days[dayIdx].exercises[exIdx], _units);
    if (result != null) setState(() => _days[dayIdx].exercises[exIdx] = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'New Program' : 'Edit Program'),
        actions: [
          TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Program Name'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _type,
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'Custom'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Days',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day')),
            ],
          ),
          for (int di = 0; di < _days.length; di++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _days[di].nameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Day name', isDense: true),
                        ),
                      ),
                      if (_days.length > 1)
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _removeDay(di)),
                    ]),
                    const SizedBox(height: 8),
                    if (_days[di].exercises.isEmpty)
                      const Text('No exercises — tap + to add',
                          style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      for (int ei = 0;
                          ei < _days[di].exercises.length;
                          ei++)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title:
                              Text(_days[di].exercises[ei].exerciseName),
                          subtitle: Text(
                              '${_days[di].exercises[ei].targetSets} × ${_days[di].exercises[ei].targetReps}'
                              '${_days[di].exercises[ei].targetWeightKg != null ? ' @ ${UnitsUtil.formatWeight(_days[di].exercises[ei].targetWeightKg, _units)}' : ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18),
                                  onPressed: () => _editExercise(di, ei)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent),
                                  onPressed: () => setState(() =>
                                      _days[di].exercises.removeAt(ei))),
                            ],
                          ),
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _addExercise(di),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Exercise'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── inline day edit model ────────────────────────────────────────────────────
class _DayEdit {
  final TextEditingController nameCtrl;
  final List<ProgramExercise> exercises;

  _DayEdit({required String name, required this.exercises})
      : nameCtrl = TextEditingController(text: name);

  factory _DayEdit.fromDay(ProgramDay d) =>
      _DayEdit(name: d.name, exercises: List.from(d.exercises));

  ProgramDay toDay() =>
      ProgramDay(name: nameCtrl.text.trim(), exercises: List.from(exercises));

  void dispose() => nameCtrl.dispose();
}

// ── reusable exercise dialog ─────────────────────────────────────────────────
Future<ProgramExercise?> showExerciseDialog(
    BuildContext context, ProgramExercise? initial, String units) async {
  final nameCtrl = TextEditingController(text: initial?.exerciseName ?? '');
  final setsCtrl =
      TextEditingController(text: (initial?.targetSets ?? 3).toString());
  final repsCtrl =
      TextEditingController(text: (initial?.targetReps ?? 10).toString());
  final weightCtrl = TextEditingController(
    text: initial?.targetWeightKg != null
        ? UnitsUtil.fromKg(initial!.targetWeightKg!, units).toStringAsFixed(0)
        : '',
  );
  final restCtrl =
      TextEditingController(text: (initial?.targetRestSeconds ?? 60).toString());
  final notesCtrl = TextEditingController(text: initial?.notes ?? '');
  final unitLabel = UnitsUtil.unitLabel(units);

  return showDialog<ProgramExercise>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(initial == null ? 'Add Exercise' : 'Edit Exercise'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Exercise name', isDense: true)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                  controller: setsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Sets', isDense: true)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                  controller: repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Reps', isDense: true)),
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
              controller: weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Target weight ($unitLabel, optional)',
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: restCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Rest (seconds)', isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: notesCtrl,
              decoration:
                  const InputDecoration(labelText: 'Notes', isDense: true),
              maxLines: 2),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final sets = int.tryParse(setsCtrl.text) ?? 3;
            final reps = int.tryParse(repsCtrl.text) ?? 10;
            final rest = int.tryParse(restCtrl.text) ?? 60;
            final wDisplay = double.tryParse(weightCtrl.text);
            final wKg =
                wDisplay != null ? UnitsUtil.toKg(wDisplay, units) : null;
            Navigator.pop(
              ctx,
              ProgramExercise(
                exerciseId: initial?.exerciseId ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                exerciseName: name,
                targetSets: sets,
                targetReps: reps,
                targetWeightKg: wKg,
                targetRestSeconds: rest,
                notes: notesCtrl.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
