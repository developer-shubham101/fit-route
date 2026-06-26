import 'package:flutter/material.dart';

class RestCountdown extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onSkip;
  final AnimationController animation;

  const RestCountdown({
    super.key,
    required this.remaining,
    required this.total,
    required this.onSkip,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? remaining / total : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(Colors.redAccent, colorScheme.primary, progress)!,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  '${remaining}s',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Text('rest', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onSkip,
          icon: const Icon(Icons.skip_next, size: 16),
          label: const Text('Skip Rest'),
        ),
      ],
    );
  }
}
