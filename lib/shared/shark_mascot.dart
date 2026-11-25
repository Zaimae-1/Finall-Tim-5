import 'dart:math' as math;

import 'package:flutter/material.dart';

class SharkMascot extends StatefulWidget {
  const SharkMascot({super.key, required this.size, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<SharkMascot> createState() => _SharkMascotState();
}

class _SharkMascotState extends State<SharkMascot>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  void _syncMotion() {
    final enabled = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (enabled && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!enabled && _motion.isAnimating) {
      _motion.reset();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(SharkMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncMotion();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _motion,
        child: Image.asset(
          'assets/images/shark_mascot.png',
          height: widget.size,
          width: widget.size,
          cacheWidth: 720,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        builder: (context, child) {
          final phase = _motion.value * 2 * math.pi;
          return Transform.translate(
            offset: Offset(
              math.sin(phase) * widget.size * .055,
              -math.sin(phase) * widget.size * .048,
            ),
            child: Transform.rotate(angle: math.sin(phase) * .09, child: child),
          );
        },
      ),
    );
  }
}
