import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../state/routines_state.dart';

class NewRoutineScreen extends ConsumerStatefulWidget {
  const NewRoutineScreen({super.key});

  @override
  ConsumerState<NewRoutineScreen> createState() => _NewRoutineScreenState();
}

class _NewRoutineScreenState extends ConsumerState<NewRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _levelController = TextEditingController();
  final _durationController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _indoorOutdoorController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _levelController.dispose();
    _durationController.dispose();
    _equipmentController.dispose();
    _indoorOutdoorController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String input) {
    return input
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();
    final level = _levelController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final equipment = _splitCsv(_equipmentController.text);
    final indoorOutdoor = _splitCsv(_indoorOutdoorController.text);
    final tags = _splitCsv(_tagsController.text);

    final routine = Routine(
      id: id,
      name: name,
      exercises: <Exercise>[],
      goal: goal,
      level: level,
      durationMinutes: duration,
      equipmentNeeded: equipment,
      indoorOutdoor: indoorOutdoor,
      tags: tags,
    );

    await ref.read(routinesProvider.notifier).addRoutine(routine);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Routine created')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Routine')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _goalController,
                decoration:
                    const InputDecoration(labelText: 'Goal (e.g. Strength)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _levelController,
                decoration:
                    const InputDecoration(labelText: 'Level (e.g. Beginner)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(
                    labelText: 'Equipment (comma separated)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _indoorOutdoorController,
                decoration: const InputDecoration(
                    labelText: 'Indoor/Outdoor (comma separated)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration:
                    const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
