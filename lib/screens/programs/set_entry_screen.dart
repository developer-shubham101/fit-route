import 'dart:async';
import 'package:flutter/material.dart';
import '../../../utils/units.dart';
import 'widgets/rest_countdown.dart';

const _weightSteps = [
  0.0, 2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 22.5, 25.0,
  27.5, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 70.0, 80.0, 90.0, 100.0,
  110.0, 120.0, 140.0, 160.0, 180.0, 200.0,
];

double prevWeight(double kg) {
  for (int i = _weightSteps.length - 1; i >= 0; i--) {
    if (_weightSteps[i] < kg - 0.01) return _weightSteps[i];
  }
  return 0.0;
}

double nextWeight(double kg) {
  for (final w in _weightSteps) {
    if (w > kg + 0.01) return w;
  }
  return kg + 2.5;
}

class SetResult {
  final int reps;
  final double? weightKg;
  final int durationSeconds;
  const SetResult(this.reps, this.weightKg, this.durationSeconds);
}

class SetEntryScreen extends StatefulWidget {
  final String exerciseName;
  final int setNumber;
  final int targetReps;
  final double? targetWeightKg;
  final int restSeconds;
  final String units;

  const SetEntryScreen({
    required this.exerciseName,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeightKg,
    required this.restSeconds,
    required this.units,
    super.key,
  });

  @override
  State<SetEntryScreen> createState() => _SetEntryScreenState();
}

class _SetEntryScreenState extends State<SetEntryScreen>
    with SingleTickerProviderStateMixin {
  Timer? _setTimer;
  Timer? _restTimer;
  int _elapsed = 0;
  int _restRemaining = 0;

  bool _started = false;
  bool _finished = false;
  bool _resting = false;

  late int _reps;
  late double _weightKg;
  late TextEditingController _weightCtrl;
  late AnimationController _restAnim;

  String get _unitLabel => UnitsUtil.unitLabel(widget.units);
  double get _weightDisplay => UnitsUtil.fromKg(_weightKg, widget.units);
  double get _maxWeightDisplay => UnitsUtil.fromKg(200.0, widget.units);

  @override
  void initState() {
    super.initState();
    _reps = widget.targetReps;
    _weightKg = widget.targetWeightKg ?? 0.0;
    _weightCtrl = TextEditingController(
        text: _weightKg > 0 ? _weightDisplay.toStringAsFixed(1) : '0.0');
    _restAnim = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _setTimer?.cancel();
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _restAnim.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _startSet() {
    setState(() => _started = true);
    _setTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() => _elapsed++) : null);
  }

  void _endSet() {
    _setTimer?.cancel();
    setState(() => _finished = true);
    if (widget.restSeconds > 0) _startRest();
  }

  void _startRest() {
    _restRemaining = widget.restSeconds;
    _restAnim.duration = Duration(seconds: widget.restSeconds);
    _restAnim.forward(from: 0);
    setState(() => _resting = true);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        if (mounted) setState(() => _resting = false);
      } else {
        if (mounted) setState(() => _restRemaining--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _restAnim.stop();
    setState(() => _resting = false);
  }

  void _setWeightFromDisplay(double displayVal) {
    final kg = UnitsUtil.toKg(displayVal, widget.units);
    setState(() => _weightKg = kg);
    _weightCtrl.text = displayVal.toStringAsFixed(1);
  }

  void _submit() {
    final wKg = _weightKg > 0 ? _weightKg : null;
    Navigator.pop(context, SetResult(_reps, wKg, _elapsed));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final targetWDisplay = widget.targetWeightKg != null
        ? UnitsUtil.fromKg(widget.targetWeightKg!, widget.units)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} — Set ${widget.setNumber}'),
      ),
      body: Column(
        children: [
          // ── Target info bar ──
          Container(
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TargetChip(
                  label: 'Target Reps',
                  value: '${widget.targetReps}',
                  icon: Icons.repeat,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 24),
                _TargetChip(
                  label: 'Target Weight',
                  value: targetWDisplay != null
                      ? '${targetWDisplay.toStringAsFixed(1)} $_unitLabel'
                      : 'Bodyweight',
                  icon: Icons.fitness_center,
                  color: colorScheme.secondary,
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _finished
                  ? _LogForm(
                      key: const ValueKey('log'),
                      reps: _reps,
                      weightKg: _weightKg,
                      weightCtrl: _weightCtrl,
                      weightDisplay: _weightDisplay,
                      maxWeightDisplay: _maxWeightDisplay,
                      unitLabel: _unitLabel,
                      elapsed: _elapsed,
                      fmt: _fmt,
                      resting: _resting,
                      restRemaining: _restRemaining,
                      restSeconds: widget.restSeconds,
                      restAnim: _restAnim,
                      onRepsChanged: (v) => setState(() => _reps = v),
                      onWeightChanged: _setWeightFromDisplay,
                      onSkipRest: _skipRest,
                      onRestartRest: _startRest,
                      onSubmit: _submit,
                      colorScheme: colorScheme,
                    )
                  : _TimerView(
                      key: const ValueKey('timer'),
                      elapsed: _elapsed,
                      started: _started,
                      fmt: _fmt,
                      onStart: _startSet,
                      onEnd: _endSet,
                      colorScheme: colorScheme,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Target chip ───────────────────────────────────────────────────────────────
class _TargetChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _TargetChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ── Timer view (before end) ───────────────────────────────────────────────────
class _TimerView extends StatelessWidget {
  final int elapsed;
  final bool started;
  final String Function(int) fmt;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final ColorScheme colorScheme;

  const _TimerView({
    super.key,
    required this.elapsed,
    required this.started,
    required this.fmt,
    required this.onStart,
    required this.onEnd,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            fmt(elapsed),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: started ? colorScheme.primary : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            started ? 'In progress… tap End Set when done' : 'Tap Start to begin',
            style: TextStyle(
                fontSize: 14,
                color: started ? colorScheme.onSurface : Colors.grey),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: started ? onEnd : onStart,
              icon: Icon(started ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 26),
              label: Text(started ? 'End Set' : 'Start Set',
                  style: const TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    started ? Colors.redAccent : colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Log form (after end) ──────────────────────────────────────────────────────
class _LogForm extends StatelessWidget {
  final int reps;
  final double weightKg;
  final TextEditingController weightCtrl;
  final double weightDisplay;
  final double maxWeightDisplay;
  final String unitLabel;
  final int elapsed;
  final String Function(int) fmt;
  final bool resting;
  final int restRemaining;
  final int restSeconds;
  final AnimationController restAnim;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onSkipRest;
  final VoidCallback onRestartRest;
  final VoidCallback onSubmit;
  final ColorScheme colorScheme;

  const _LogForm({
    super.key,
    required this.reps,
    required this.weightKg,
    required this.weightCtrl,
    required this.weightDisplay,
    required this.maxWeightDisplay,
    required this.unitLabel,
    required this.elapsed,
    required this.fmt,
    required this.resting,
    required this.restRemaining,
    required this.restSeconds,
    required this.restAnim,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onSkipRest,
    required this.onRestartRest,
    required this.onSubmit,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final wLabel = weightKg > 0
        ? '${weightDisplay.toStringAsFixed(1)} $unitLabel'
        : 'Bodyweight';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── elapsed badge ──
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Set time: ${fmt(elapsed)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── rest countdown ──
          if (restSeconds > 0)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: resting
                    ? RestCountdown(
                        key: const ValueKey('rest'),
                        remaining: restRemaining,
                        total: restSeconds,
                        onSkip: onSkipRest,
                        animation: restAnim,
                      )
                    : OutlinedButton.icon(
                        key: const ValueKey('restart-rest'),
                        onPressed: onRestartRest,
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('Restart Rest'),
                      ),
              ),
            ),

          if (restSeconds > 0) const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 16),

          // ── Reps picker ──
          Text('Reps',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(30, (i) {
              final n = i + 1;
              final selected = reps == n;
              return GestureDetector(
                onTap: () => onRepsChanged(n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ── Weight slider ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weight',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface)),
              SizedBox(
                width: 110,
                height: 40,
                child: TextField(
                  controller: weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    suffixText: unitLabel,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      onWeightChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: weightDisplay.clamp(0.0, maxWeightDisplay),
              min: 0,
              max: maxWeightDisplay,
              divisions: (maxWeightDisplay / 2.5).round(),
              label: weightKg == 0
                  ? 'Bodyweight'
                  : '${weightDisplay.toStringAsFixed(1)} $unitLabel',
              onChanged: (v) {
                // snap to nearest 2.5 increment in display units
                final snapped = (v / 2.5).round() * 2.5;
                onWeightChanged(snapped);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bodyweight',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('${maxWeightDisplay.toStringAsFixed(0)} $unitLabel',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 28),

          // ── Submit ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Log — $reps reps  ${weightKg > 0 ? '@ $wLabel' : '(bodyweight)'}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
