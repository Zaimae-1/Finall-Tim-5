import 'package:flutter/material.dart';

class MotionReveal extends StatelessWidget {
  const MotionReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.lift = 8,
    this.startScale = .97,
  });

  final Widget child;
  final Duration duration;
  final double lift;
  final double startScale;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, lift * (1 - value)),
        child: Transform.scale(
          scale: startScale + (1 - startScale) * value,
          child: Opacity(opacity: value, child: child),
        ),
      ),
      child: child,
    );
  }
}

class MotionProgress extends StatelessWidget {
  const MotionProgress({
    super.key,
    required this.value,
    required this.label,
    this.height = 8,
  });

  final double value;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => LinearProgressIndicator(
        value: progress,
        minHeight: height,
        borderRadius: BorderRadius.circular(10),
        stopIndicatorRadius: 0,
        semanticsLabel: label,
        semanticsValue: '${(value * 100).round()}%',
      ),
    );
  }
}
