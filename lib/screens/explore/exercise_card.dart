import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../utils/media.dart';
import 'exercise_helpers.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise ex;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExerciseCard({
    required this.ex,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  Widget _thumb(BuildContext context) {
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
        child: Icon(categoryIcon(ex.category),
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return MediaUtil.cachedImage(media,
        fit: BoxFit.cover,
        radius: BorderRadius.circular(10),
        width: 72,
        height: 72);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffColor = difficultyColor(ex.difficulty);

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
              _thumb(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(ex.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        PopupMenuButton<String>(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    if (ex.primaryMuscles.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ex.primaryMuscles.take(3).join(' · '),
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (ex.difficulty.isNotEmpty)
                          ExerciseTag(ex.difficulty, color: diffColor),
                        if (ex.defaultType.isNotEmpty)
                          ExerciseTag(ex.defaultType,
                              color: theme.colorScheme.secondary),
                        if (ex.suitableAtHome)
                          const ExerciseTag('Home', color: Colors.teal),
                        if (ex.equipment.isNotEmpty)
                          ExerciseTag(ex.equipment.first,
                              color: Colors.blueGrey),
                        if (ex.setsRecommended > 0 && ex.repsRecommended > 0)
                          ExerciseTag(
                              '${ex.setsRecommended}×${ex.repsRecommended}',
                              color: Colors.deepPurple),
                      ],
                    ),
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
