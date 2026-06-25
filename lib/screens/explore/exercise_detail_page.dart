import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:video_player/video_player.dart';
import '../../models/exercise.dart';
import '../routine_detail_screen.dart';
import '../../state/routines_state.dart';
import '../../models/routine.dart';
import '../../utils/media.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseDetailPage extends ConsumerStatefulWidget {
  final Exercise exercise;
  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends ConsumerState<ExerciseDetailPage> {
  final PageController _pageController = PageController();
  // final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _videoInitError = {};

  @override
  void dispose() {
    // for (final vc in _videoControllers.values) {
    //   vc.dispose();
    // }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMediaItem(String url, int index) {
    final isVideo = MediaUtil.isVideoUrl(url);
    if (!isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MediaUtil.cachedImage(url, fit: BoxFit.cover),
      );
    }

    return SizedBox();
    // For non-web platforms, keep video playback. For web, videos are filtered out already.
    /*if (_videoInitError.contains(index)) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: MediaUtil.placeholderBox(height: 180));
    }

    if (!_videoControllers.containsKey(index)) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoControllers[index] = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller.setLooping(true);
        controller.play();
        setState(() {});
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _videoInitError.add(index);
        });
      });
    }

    final controller = _videoControllers[index]!;

    if (_videoInitError.contains(index) || controller.value.hasError) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: MediaUtil.placeholderBox(height: 180));
    }

    if (!controller.value.isInitialized) {
      return FutureBuilder<ImageProvider?>(
        future: MediaUtil.generateVideoThumbnail(url),
        builder: (context, snapshot) {
          final img = snapshot.data;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              image: img != null
                  ? DecorationImage(image: img, fit: BoxFit.cover)
                  : null,
            ),
            child: const Icon(Icons.play_circle_fill,
                size: 64, color: Colors.white70),
          );
        },
      );
    }

    final aspect = controller.value.aspectRatio == 0
        ? 16 / 9
        : controller.value.aspectRatio;
    return AspectRatio(aspectRatio: aspect, child: VideoPlayer(controller));*/
  }

  Future<void> _addToRoutine(BuildContext context) async {
    final routines = ref.read(routinesProvider);
    String? selectedRoutineId;
    final nameController = TextEditingController();

    if (routines.isEmpty) {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Create routine'),
          content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Routine name')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, nameController.text.trim()),
                child: const Text('Create')),
          ],
        ),
      );
      if (name == null || name.isEmpty) return;
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      await ref.read(routinesProvider.notifier).addRoutine(
            Routine(id: newId, name: name, exercises: const []),
          );
      selectedRoutineId = newId;
    } else {
      selectedRoutineId = await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Add to routine'),
          children: [
            for (final r in routines)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, r.id),
                child: Text(r.name),
              ),
          ],
        ),
      );
      if (selectedRoutineId == null) return;
    }

    final routine =
        ref.read(routinesProvider).firstWhere((r) => r.id == selectedRoutineId);
    final already = routine.exercises.any((e) => e.id == widget.exercise.id);
    if (already) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise already in routine')));
      return;
    }
    await ref
        .read(routinesProvider.notifier)
        .addExerciseToRoutine(selectedRoutineId, widget.exercise);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added to ${routine.name}')));
  }

  void _startExercise(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExerciseSetupSheet(
          exercise: widget.exercise, routineId: '__explore__'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final originalMedia = widget.exercise.mediaUrls;
    final media = kIsWeb
        ? originalMedia.where((m) => MediaUtil.isImageUrl(m)).toList()
        : originalMedia;
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (media.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: media.length,
                itemBuilder: (context, index) =>
                    _buildMediaItem(media[index], index),
              ),
            )
          else
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MediaUtil.placeholderBox(height: 180)),
          const SizedBox(height: 16),
          Text(widget.exercise.description.isNotEmpty
              ? widget.exercise.description
              : 'No description provided.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(label: Text('Type: ${widget.exercise.defaultType}')),
              Chip(label: Text('Category: ${widget.exercise.category}')),
              Chip(label: Text('Difficulty: ${widget.exercise.difficulty}')),
              if (widget.exercise.requiresExternal)
                const Chip(label: Text('External required')),
              if (widget.exercise.suitableAtHome)
                const Chip(label: Text('Home-friendly')),
              if (widget.exercise.suitableAtGym)
                const Chip(label: Text('Gym-friendly')),
              for (final eq in widget.exercise.equipment) Chip(label: Text(eq)),
              for (final tag in widget.exercise.tags) Chip(label: Text(tag)),
              if (widget.exercise.isFavorite)
                const Chip(label: Text('Favorite')),
              if (widget.exercise.isBodyweight)
                const Chip(label: Text('Bodyweight')),
              if (widget.exercise.requiresPartner)
                const Chip(label: Text('Partner required')),
              if (widget.exercise.indoorOutdoor.isNotEmpty)
                Chip(label: Text(widget.exercise.indoorOutdoor)),
              if (widget.exercise.warmupOrMain.isNotEmpty)
                Chip(label: Text(widget.exercise.warmupOrMain)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.exercise.instructions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions:',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(widget.exercise.instructions),
                const SizedBox(height: 8),
              ],
            ),
          if (widget.exercise.commonMistakes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Common Mistakes:',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(widget.exercise.commonMistakes),
                const SizedBox(height: 8),
              ],
            ),
          if (widget.exercise.benefits.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Benefits:',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(widget.exercise.benefits),
                const SizedBox(height: 8),
              ],
            ),
          if (widget.exercise.safetyTips.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety Tips:',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(widget.exercise.safetyTips),
                const SizedBox(height: 8),
              ],
            ),
          if (widget.exercise.primaryMuscles.isNotEmpty)
            Text(
                'Primary Muscles: ${widget.exercise.primaryMuscles.join(", ")}',
                style: Theme.of(context).textTheme.bodyMedium),
          if (widget.exercise.secondaryMuscles.isNotEmpty)
            Text(
                'Secondary Muscles: ${widget.exercise.secondaryMuscles.join(", ")}',
                style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          if (widget.exercise.setsRecommended > 0 ||
              widget.exercise.repsRecommended > 0)
            Text(
                'Recommended: ${widget.exercise.setsRecommended} sets x ${widget.exercise.repsRecommended} reps'),
          if (widget.exercise.timeRecommended != null)
            Text('Recommended Time: ${widget.exercise.timeRecommended} sec'),
          if (widget.exercise.caloriesBurnEstimate > 0)
            Text(
                'Calories Burn Estimate: ${widget.exercise.caloriesBurnEstimate}'),
          if (widget.exercise.progressionLevel.isNotEmpty)
            Text('Progression: ${widget.exercise.progressionLevel}'),
          if (widget.exercise.regressionLevel.isNotEmpty)
            Text('Regression: ${widget.exercise.regressionLevel}'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                  onPressed: () => _addToRoutine(context),
                  child: const Text('Add to routine')),
              const SizedBox(width: 12),
              ElevatedButton(
                  onPressed: () => _startExercise(context),
                  child: const Text('Start')),
            ],
          ),
        ],
      ),
    );
  }
}
