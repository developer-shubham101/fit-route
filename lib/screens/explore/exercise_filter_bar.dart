import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/explore/explore_state.dart';

class ExploreFilterBar extends ConsumerStatefulWidget {
  const ExploreFilterBar({super.key});

  @override
  ConsumerState<ExploreFilterBar> createState() => _ExploreFilterBarState();
}

class _ExploreFilterBarState extends ConsumerState<ExploreFilterBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseLibraryProvider);
    final filters = ref.watch(exploreFiltersProvider);

    final categories = <String>{
      for (final e in allExercises)
        if (e.category.isNotEmpty) e.category
    }.toList()
      ..sort();
    final equipments = <String>{
      for (final e in allExercises)
        for (final eq in e.equipment)
          if (eq.isNotEmpty) eq
    }.toList()
      ..sort();
    final difficulties = <String>{
      for (final e in allExercises)
        if (e.difficulty.isNotEmpty) e.difficulty
    }.toList()
      ..sort();

    final hasFilters = filters.category != null ||
        filters.equipment != null ||
        filters.difficulty != null ||
        filters.homeOnly != null ||
        filters.bodyweightOnly != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search exercises…',
              isDense: true,
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref
                            .read(exerciseSearchQueryProvider.notifier)
                            .state = '';
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) =>
                ref.read(exerciseSearchQueryProvider.notifier).state = v,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _FilterDrop(
                hint: 'Body Part',
                value: filters.category,
                options: categories,
                onChanged: (v) =>
                    ref.read(exploreFiltersProvider.notifier).setCategory(v),
              ),
              const SizedBox(width: 8),
              _FilterDrop(
                hint: 'Equipment',
                value: filters.equipment,
                options: equipments,
                onChanged: (v) =>
                    ref.read(exploreFiltersProvider.notifier).setEquipment(v),
              ),
              const SizedBox(width: 8),
              _FilterDrop(
                hint: 'Difficulty',
                value: filters.difficulty,
                options: difficulties,
                onChanged: (v) =>
                    ref.read(exploreFiltersProvider.notifier).setDifficulty(v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('🏠 Home'),
                selected: filters.homeOnly == true,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => ref
                    .read(exploreFiltersProvider.notifier)
                    .setHomeOnly(v ? true : null),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('💪 Bodyweight'),
                selected: filters.bodyweightOnly == true,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => ref
                    .read(exploreFiltersProvider.notifier)
                    .setBodyweightOnly(v ? true : null),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(exploreFiltersProvider.notifier).clear(),
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _FilterDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> options;
  final void Function(String?) onChanged;

  const _FilterDrop({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return DropdownButton<String?>(
      value: value,
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('All $hint')),
        for (final o in options)
          DropdownMenuItem<String?>(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
    );
  }
}
