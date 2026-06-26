import 'package:flutter/material.dart';

Color difficultyColor(String d) {
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

IconData categoryIcon(String cat) {
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

class ExerciseTag extends StatelessWidget {
  final String label;
  final Color color;
  const ExerciseTag(this.label, {required this.color, super.key});

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

class ExerciseCategoryHeader extends StatelessWidget {
  final String cat;
  final int count;
  final IconData icon;
  const ExerciseCategoryHeader(
      {required this.cat, required this.count, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(cat,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Container(height: 1, width: 40, color: theme.dividerColor),
        ],
      ),
    );
  }
}
