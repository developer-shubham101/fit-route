import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../state/explore/explore_state.dart';
import '../../utils/media.dart';

class ExerciseEditPage extends ConsumerStatefulWidget {
  final Exercise? initial;
  const ExerciseEditPage({super.key, this.initial});

  @override
  ConsumerState<ExerciseEditPage> createState() => _ExerciseEditPageState();
}

class _ExerciseEditPageState extends ConsumerState<ExerciseEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  String _type = 'Bodyweight';
  bool _requiresExternal = false;
  bool _home = true;
  bool _gym = true;
  late TextEditingController _equipment;
  late TextEditingController _media;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _desc = TextEditingController(text: i?.description ?? '');
    _type = i?.defaultType ?? 'Bodyweight';
    _requiresExternal = i?.requiresExternal ?? false;
    _home = i?.suitableAtHome ?? true;
    _gym = i?.suitableAtGym ?? true;
    _equipment = TextEditingController(text: (i?.equipment ?? []).join(', '));
    _media = TextEditingController(text: (i?.mediaUrls ?? []).join('\n'));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _equipment.dispose();
    _media.dispose();
    super.dispose();
  }

  List<String> _splitList(String input) {
    return input
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final equipments = _splitList(_equipment.text);
    final media = _splitList(_media.text);

    final invalid = media.where((m) => !MediaUtil.isValidUrl(m)).toList();
    if (invalid.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid URLs'),
          content: Text(
              'Some media URLs look invalid:\n${invalid.join('\n')}\nContinue anyway?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final ex = Exercise(
      id: widget.initial?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      defaultType: _type,
      description: _desc.text.trim(),
      requiresExternal: _requiresExternal,
      equipment: equipments,
      suitableAtHome: _home,
      suitableAtGym: _gym,
      mediaUrls: media,
    );
    if (widget.initial == null) {
      await ref.read(exerciseLibraryProvider.notifier).add(ex);
    } else {
      await ref
          .read(exerciseLibraryProvider.notifier)
          .updateById(widget.initial!.id, ex);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.initial == null ? 'Add Exercise' : 'Edit Exercise')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(
                    value: 'Bodyweight', child: Text('Bodyweight')),
                DropdownMenuItem(
                    value: 'External', child: Text('External weight')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'Bodyweight'),
              decoration: const InputDecoration(labelText: 'Default type'),
            ),
            SwitchListTile(
              value: _requiresExternal,
              onChanged: (v) => setState(() => _requiresExternal = v),
              title: const Text('Requires external equipment'),
            ),
            SwitchListTile(
              value: _home,
              onChanged: (v) => setState(() => _home = v),
              title: const Text('Suitable at home'),
            ),
            SwitchListTile(
              value: _gym,
              onChanged: (v) => setState(() => _gym = v),
              title: const Text('Suitable at gym'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _equipment,
              decoration: const InputDecoration(
                  labelText: 'Equipment (comma or newline separated)'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _media,
              decoration: const InputDecoration(
                  labelText:
                      'Media URLs (image/gif/video, comma or newline separated)'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
