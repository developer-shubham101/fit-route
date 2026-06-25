import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../state/explore/explore_state.dart';
import 'exercise_detail_page.dart';
import 'exercise_edit_page.dart';
import '../../models/exercise.dart';
import '../../utils/media.dart';

class ExploreExercisesScreen extends ConsumerWidget {
  const ExploreExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExerciseLibraryProvider);

    Future<void> _addExercise() async {
      final changed = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ExerciseEditPage()));
      if (changed == true) {
        ref.read(exerciseLibraryProvider.notifier).load();
      }
    }

    Future<void> _editExercise(Exercise ex) async {
      final changed = await Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExerciseEditPage(initial: ex)));
      if (changed == true) {
        ref.read(exerciseLibraryProvider.notifier).load();
      }
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

    Widget leadingThumb(Exercise ex) {
      final media = ex.mediaUrls;
      // Web: only show image thumbnails; ignore videos
      if (kIsWeb) {
        final firstImage = media.firstWhere(
          (m) => MediaUtil.isImageUrl(m),
          orElse: () => '',
        );
        if (firstImage.isNotEmpty) {
          return SizedBox(
            width: 56,
            height: 56,
            child: MediaUtil.cachedImage(firstImage,
                fit: BoxFit.cover, radius: BorderRadius.circular(6)),
          );
        }
        return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: MediaUtil.placeholderBox(width: 56, height: 56));
      }

      // Non-web: support image or video thumbnail
      if (media.isEmpty) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: MediaUtil.placeholderBox(width: 56, height: 56));
      }
      final first = media.first;
      if (MediaUtil.isImageUrl(first)) {
        return SizedBox(
            width: 56,
            height: 56,
            child: MediaUtil.cachedImage(first,
                fit: BoxFit.cover, radius: BorderRadius.circular(6)));
      }
      if (MediaUtil.isVideoUrl(first)) {
        return FutureBuilder<ImageProvider?>(
          future: MediaUtil.generateVideoThumbnail(first),
          builder: (context, snapshot) {
            final img = snapshot.data;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    image: img != null
                        ? DecorationImage(image: img, fit: BoxFit.cover)
                        : null,
                  ),
                  child: img == null
                      ? MediaUtil.placeholderBox(
                          width: 56,
                          height: 56,
                          radius: BorderRadius.circular(6))
                      : null,
                ),
                const Icon(Icons.play_circle_fill, color: Colors.white70),
              ],
            );
          },
        );
      }
      return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: MediaUtil.placeholderBox(width: 56, height: 56));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Exercises')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Search exercises'),
              onChanged: (v) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final ex = exercises[idx];
                return ListTile(
                  leading: leadingThumb(ex),
                  title: Text(ex.name),
                  subtitle: Text(ex.defaultType),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ExerciseDetailPage(exercise: ex)));
                  },
                  onLongPress: () => _editExercise(ex),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editExercise(ex);
                      if (value == 'delete') _deleteExercise(ex);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
        tooltip: 'Add Exercise',
      ),
    );
  }
}
