import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/exercise.dart';
import '../../utils/media.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMediaItem(String url) {
    if (MediaUtil.isVideoUrl(url)) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: MediaUtil.cachedImage(url, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final theme = Theme.of(context);

    // Collect media — image/gif first, videos excluded on web
    final allMedia = [
      if (ex.imageUrl.isNotEmpty) ex.imageUrl,
      if (ex.gifUrl.isNotEmpty) ex.gifUrl,
      ...ex.mediaUrls,
    ].where((m) => kIsWeb ? MediaUtil.isImageUrl(m) : true).toList();

    return Scaffold(
      appBar: AppBar(title: Text(ex.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Media ─────────────────────────────────────────────────────────
          if (allMedia.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: allMedia.length,
                itemBuilder: (_, i) => _buildMediaItem(allMedia[i]),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MediaUtil.placeholderBox(height: 180),
            ),
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────────
          if (ex.description.isNotEmpty) ...[
            Text(ex.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],

          // ── Meta chips ────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (ex.category.isNotEmpty) Chip(label: Text(ex.category)),
              if (ex.difficulty.isNotEmpty) Chip(label: Text(ex.difficulty)),
              if (ex.defaultType.isNotEmpty) Chip(label: Text(ex.defaultType)),
              if (ex.suitableAtHome) const Chip(label: Text('🏠 Home')),
              if (ex.suitableAtGym) const Chip(label: Text('🏋 Gym')),
              if (ex.isBodyweight) const Chip(label: Text('💪 Bodyweight')),
              if (ex.requiresPartner) const Chip(label: Text('👥 Partner')),
              if (ex.warmupOrMain.isNotEmpty) Chip(label: Text(ex.warmupOrMain)),
              if (ex.indoorOutdoor.isNotEmpty) Chip(label: Text(ex.indoorOutdoor)),
              for (final eq in ex.equipment) Chip(label: Text(eq)),
              for (final tag in ex.tags) Chip(label: Text('#$tag')),
            ],
          ),
          const SizedBox(height: 16),

          // ── Muscles ───────────────────────────────────────────────────────
          if (ex.primaryMuscles.isNotEmpty) ...[
            _InfoRow('Primary muscles', ex.primaryMuscles.join(', ')),
            const SizedBox(height: 4),
          ],
          if (ex.secondaryMuscles.isNotEmpty) ...[
            _InfoRow('Secondary muscles', ex.secondaryMuscles.join(', ')),
            const SizedBox(height: 4),
          ],

          // ── Stats ─────────────────────────────────────────────────────────
          if (ex.setsRecommended > 0 || ex.repsRecommended > 0) ...[
            const SizedBox(height: 8),
            _InfoRow('Recommended',
                '${ex.setsRecommended} sets × ${ex.repsRecommended} reps'),
          ],
          if (ex.timeRecommended != null && ex.timeRecommended!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow('Time', ex.timeRecommended!),
          ],
          if (ex.caloriesBurnEstimate > 0) ...[
            const SizedBox(height: 4),
            _InfoRow('Calories', '~${ex.caloriesBurnEstimate} kcal'),
          ],

          // ── Instructions ──────────────────────────────────────────────────
          if (ex.instructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section('Instructions', ex.instructions, theme),
          ],
          if (ex.commonMistakes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section('Common Mistakes', ex.commonMistakes, theme),
          ],
          if (ex.benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section('Benefits', ex.benefits, theme),
          ],
          if (ex.safetyTips.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section('Safety Tips', ex.safetyTips, theme),
          ],

          // ── Progression / Regression ──────────────────────────────────────
          if (ex.progressionLevel.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow('Progression', ex.progressionLevel),
          ],
          if (ex.regressionLevel.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow('Regression', ex.regressionLevel),
          ],

          // ── External links ────────────────────────────────────────────────
          if (ex.videoUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openUrl(ex.videoUrl),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch video'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Colors.grey))),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final ThemeData theme;
  const _Section(this.title, this.body, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
