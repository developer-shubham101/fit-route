import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/exercise.dart';
import '../../state/explore/explore_state.dart';
import '../../utils/media.dart';
import 'exercise_edit_page.dart';

/// Push this screen when you need the user to pick an Exercise from the library.
/// Returns the selected [Exercise] via [Navigator.pop].
class ExercisePickerScreen extends ConsumerWidget {
  const ExercisePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExerciseLibraryProvider);
    final allExercises = ref.watch(exerciseLibraryProvider);
    final filters = ref.watch(exploreFiltersProvider);

    final categories = <String>{
      for (final e in allExercises)
        if (e.category.isNotEmpty) e.category
    }.toList()..sort();
    final equipments = <String>{
      for (final e in allExercises)
        for (final eq in e.equipment)
          if (eq.isNotEmpty) eq
    }.toList()..sort();
    final difficulties = <String>{
      for (final e in allExercises)
        if (e.difficulty.isNotEmpty) e.difficulty
    }.toList()..sort();

    Future<void> addExercise() async {
      final changed = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ExerciseEditPage()));
      if (changed == true) {
        ref.read(exerciseLibraryProvider.notifier).load();
      }
    }

    Widget thumb(Exercise ex) {
      final media = ex.mediaUrls;
      final firstImage = kIsWeb
          ? media.firstWhere((m) => MediaUtil.isImageUrl(m), orElse: () => '')
          : (media.isNotEmpty ? media.first : '');
      if (firstImage.isNotEmpty && MediaUtil.isImageUrl(firstImage)) {
        return SizedBox(
          width: 48,
          height: 48,
          child: MediaUtil.cachedImage(firstImage,
              fit: BoxFit.cover, radius: BorderRadius.circular(6)),
        );
      }
      return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: MediaUtil.placeholderBox(width: 48, height: 48));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Exercise')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search exercises',
                  isDense: true),
              onChanged: (v) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String?>(
                    value: filters.category,
                    hint: const Text('Body Part'),
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      for (final c in categories)
                        DropdownMenuItem<String?>(value: c, child: Text(c)),
                    ],
                    onChanged: (v) =>
                        ref.read(exploreFiltersProvider.notifier).setCategory(v),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: filters.equipment,
                    hint: const Text('Equipment'),
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      for (final eq in equipments)
                        DropdownMenuItem<String?>(value: eq, child: Text(eq)),
                    ],
                    onChanged: (v) =>
                        ref.read(exploreFiltersProvider.notifier).setEquipment(v),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: filters.difficulty,
                    hint: const Text('Difficulty'),
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      for (final d in difficulties)
                        DropdownMenuItem<String?>(value: d, child: Text(d)),
                    ],
                    onChanged: (v) => ref
                        .read(exploreFiltersProvider.notifier)
                        .setDifficulty(v),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Home'),
                    selected: filters.homeOnly == true,
                    onSelected: (v) => ref
                        .read(exploreFiltersProvider.notifier)
                        .setHomeOnly(v ? true : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Bodyweight'),
                    selected: filters.bodyweightOnly == true,
                    onSelected: (v) => ref
                        .read(exploreFiltersProvider.notifier)
                        .setBodyweightOnly(v ? true : null),
                  ),
                  if (filters.category != null ||
                      filters.equipment != null ||
                      filters.difficulty != null ||
                      filters.homeOnly != null ||
                      filters.bodyweightOnly != null) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () =>
                          ref.read(exploreFiltersProvider.notifier).clear(),
                      child: const Text('Clear'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? const Center(child: Text('No exercises found.'))
                : ListView.separated(
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final ex = exercises[idx];
                      return ListTile(
                        leading: thumb(ex),
                        title: Text(ex.name),
                        subtitle: Text(
                          [
                            if (ex.category.isNotEmpty) ex.category,
                            if (ex.difficulty.isNotEmpty) ex.difficulty,
                            ex.defaultType,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => Navigator.pop(context, ex),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addExercise,
        tooltip: 'Add custom exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}
