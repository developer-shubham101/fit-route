import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/explore/explore_state.dart';
import 'exercise_detail_page.dart';
import 'exercise_edit_page.dart';
import '../../models/exercise.dart';
import '../../utils/media.dart';

// ── difficulty colour ─────────────────────────────────────────────────────────
Color _difficultyColor(String d) {
  switch (d.toLowerCase()) {
    case 'beginner':
      return Colors.green;
    case 'intermediate':
      return Colors.orange;
    case 'advanced':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

IconData _categoryIcon(String cat) {
  switch (cat.toLowerCase()) {
    case 'chest':
      return Icons.self_improvement;
    case 'back':
      return Icons.accessibility_new;
    case 'legs':
      return Icons.directions_run;
    case 'shoulders':
      return Icons.fitness_center;
    case 'arms':
      return Icons.sports_gymnastics;
    case 'core':
    case 'abs':
      return Icons.star;
    case 'cardio':
      return Icons.favorite;
    case 'full body':
      return Icons.person;
    default:
      return Icons.fitness_center;
  }
}

class ExploreExercisesScreen extends ConsumerStatefulWidget {
  const ExploreExercisesScreen({super.key});

  @override
  ConsumerState<ExploreExercisesScreen> createState() =>
      _ExploreExercisesScreenState();
}

class _ExploreExercisesScreenState
    extends ConsumerState<ExploreExercisesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final changed = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ExerciseEditPage()));
    if (changed == true) ref.read(exerciseLibraryProvider.notifier).load();
  }

  Future<void> _editExercise(Exercise ex) async {
    final changed = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ExerciseEditPage(initial: ex)));
    if (changed == true) ref.read(exerciseLibraryProvider.notifier).load();
  }

  Future<void> _deleteExercise(Exercise ex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text('Delete "${ex.name}" from library?'),
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
      await ref.read(exerciseLibraryProvider.notifier).deleteById(ex.id);
    }
  }

  Widget _thumb(Exercise ex) {
    final media = ex.imageUrl.isNotEmpty
        ? ex.imageUrl
        : ex.gifUrl.isNotEmpty
            ? ex.gifUrl
            : (ex.mediaUrls.isNotEmpty ? ex.mediaUrls.first : '');

    if (media.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_categoryIcon(ex.category),
            size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: MediaUtil.cachedImage(media,
          fit: BoxFit.cover,
          radius: BorderRadius.circular(10),
          width: 72,
          height: 72),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseLibraryProvider);
    final filtered = ref.watch(filteredExerciseLibraryProvider);
    final filters = ref.watch(exploreFiltersProvider);

    // Build filter options
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

    // Group filtered exercises by category
    final Map<String, List<Exercise>> grouped = {};
    for (final ex in filtered) {
      final cat = ex.category.isNotEmpty ? ex.category : 'Other';
      grouped.putIfAbsent(cat, () => []).add(ex);
    }
    final sortedCats = grouped.keys.toList()..sort();

    final hasFilters = filters.category != null ||
        filters.equipment != null ||
        filters.difficulty != null ||
        filters.homeOnly != null ||
        filters.bodyweightOnly != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            title: const Text('Explore Exercises'),
            floating: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(116),
              child: Column(
                children: [
                  // search
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
                                      .read(exerciseSearchQueryProvider
                                          .notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => ref
                          .read(exerciseSearchQueryProvider.notifier)
                          .state = v,
                    ),
                  ),
                  // filter chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _FilterDrop(
                          hint: 'Body Part',
                          value: filters.category,
                          options: categories,
                          onChanged: (v) => ref
                              .read(exploreFiltersProvider.notifier)
                              .setCategory(v),
                        ),
                        const SizedBox(width: 8),
                        _FilterDrop(
                          hint: 'Equipment',
                          value: filters.equipment,
                          options: equipments,
                          onChanged: (v) => ref
                              .read(exploreFiltersProvider.notifier)
                              .setEquipment(v),
                        ),
                        const SizedBox(width: 8),
                        _FilterDrop(
                          hint: 'Difficulty',
                          value: filters.difficulty,
                          options: difficulties,
                          onChanged: (v) => ref
                              .read(exploreFiltersProvider.notifier)
                              .setDifficulty(v),
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
                            onPressed: () {
                              ref
                                  .read(exploreFiltersProvider.notifier)
                                  .clear();
                            },
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
              ),
            ),
          ),

          // ── Count ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${filtered.length} exercise${filtered.length == 1 ? '' : 's'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
          ),

          // ── Empty state ──────────────────────────────────────────────────
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No exercises found.')),
            ),

          // ── Grouped sections ─────────────────────────────────────────────
          for (final cat in sortedCats) ...[
            // sticky category header
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeader(
                cat: cat,
                count: grouped[cat]!.length,
                icon: _categoryIcon(cat),
              ),
            ),
            // exercise cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final ex = grouped[cat]![i];
                    return _ExerciseCard(
                      ex: ex,
                      thumb: _thumb(ex),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ExerciseDetailPage(exercise: ex)),
                      ),
                      onEdit: () => _editExercise(ex),
                      onDelete: () => _deleteExercise(ex),
                    );
                  },
                  childCount: grouped[cat]!.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Sticky header delegate ────────────────────────────────────────────────────
class _StickyHeader extends SliverPersistentHeaderDelegate {
  final String cat;
  final int count;
  final IconData icon;

  const _StickyHeader(
      {required this.cat, required this.count, required this.icon});

  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 40;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            cat,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          Container(height: 1, width: 40, color: theme.dividerColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeader old) =>
      old.cat != cat || old.count != count;
}

// ── Exercise card ─────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final Exercise ex;
  final Widget thumb;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.ex,
    required this.thumb,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffColor = _difficultyColor(ex.difficulty);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // thumbnail
              thumb,
              const SizedBox(width: 12),
              // info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name + menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(ex.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        PopupMenuButton<String>(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // primary muscles
                    if (ex.primaryMuscles.isNotEmpty)
                      Text(
                        ex.primaryMuscles.take(3).join(' · '),
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    const SizedBox(height: 6),
                    // tags row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (ex.difficulty.isNotEmpty)
                          _Tag(ex.difficulty, color: diffColor),
                        if (ex.defaultType.isNotEmpty)
                          _Tag(ex.defaultType,
                              color: theme.colorScheme.secondary),
                        if (ex.suitableAtHome)
                          _Tag('Home', color: Colors.teal),
                        if (ex.equipment.isNotEmpty)
                          _Tag(ex.equipment.first,
                              color: Colors.blueGrey),
                        if (ex.setsRecommended > 0 &&
                            ex.repsRecommended > 0)
                          _Tag(
                              '${ex.setsRecommended}×${ex.repsRecommended}',
                              color: Colors.deepPurple),
                      ],
                    ),
                    // calorie estimate
                    if (ex.caloriesBurnEstimate > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 13, color: Colors.deepOrange),
                          const SizedBox(width: 3),
                          Text('~${ex.caloriesBurnEstimate} kcal',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small tag chip ────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Filter dropdown ───────────────────────────────────────────────────────────
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
