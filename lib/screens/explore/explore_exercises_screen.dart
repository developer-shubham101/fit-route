import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import '../../state/explore/explore_state.dart';
import '../../models/exercise.dart';
import 'exercise_detail_page.dart';
import 'exercise_edit_page.dart';
import 'exercise_card.dart';
import 'exercise_filter_bar.dart';
import 'exercise_helpers.dart';

class ExploreExercisesScreen extends ConsumerWidget {
  const ExploreExercisesScreen({super.key});

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ExerciseEditPage()));
    if (changed == true) ref.read(exerciseLibraryProvider.notifier).load();
  }

  Future<void> _editExercise(
      BuildContext context, WidgetRef ref, Exercise ex) async {
    final changed = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ExerciseEditPage(initial: ex)));
    if (changed == true) ref.read(exerciseLibraryProvider.notifier).load();
  }

  Future<void> _deleteExercise(
      BuildContext context, WidgetRef ref, Exercise ex) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredExerciseLibraryProvider);

    // Group by category
    final Map<String, List<Exercise>> grouped = {};
    for (final ex in filtered) {
      final cat = ex.category.isNotEmpty ? ex.category : 'Other';
      grouped.putIfAbsent(cat, () => []).add(ex);
    }
    final sortedCats = grouped.keys.toList()..sort();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar + filter bar ─────────────────────────────────────────
          SliverAppBar(
            title: const Text('Explore Exercises'),
            floating: true,
            snap: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(116),
              child: ExploreFilterBar(),
            ),
          ),

          // ── Result count ─────────────────────────────────────────────────
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

          // ── Grouped + sticky headers ─────────────────────────────────────
          for (final cat in sortedCats)
            SliverStickyHeader(
              header: ExerciseCategoryHeader(
                cat: cat,
                count: grouped[cat]!.length,
                icon: categoryIcon(cat),
              ),
              sliver: SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final ex = grouped[cat]![i];
                      return ExerciseCard(
                        ex: ex,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailPage(exercise: ex)),
                        ),
                        onEdit: () => _editExercise(context, ref, ex),
                        onDelete: () => _deleteExercise(context, ref, ex),
                      );
                    },
                    childCount: grouped[cat]!.length,
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExercise(context, ref),
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}
