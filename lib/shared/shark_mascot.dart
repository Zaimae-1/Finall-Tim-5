import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'shark_art.dart';

enum SharkMood { swim, greet, correct, encourage, celebrate }

const sharkSkinNames = [
  'Kapten Laut',
  'Penyelam',
  'Raja Samudra',
  'Penjelajah',
  'Pelaut Klasik',
];

class SharkSkinScope extends InheritedWidget {
  const SharkSkinScope({super.key, required this.skinId, required super.child});
  final int skinId;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SharkSkinScope>()?.skinId ??
      -1;

  @override
  bool updateShouldNotify(SharkSkinScope oldWidget) =>
      oldWidget.skinId != skinId;
}

class SharkMascot extends StatefulWidget {
  const SharkMascot({
    super.key,
    required this.size,
    this.animate = true,
    this.mood = SharkMood.swim,
  });

  final double size;
  final bool animate;
  final SharkMood mood;

  @override
  State<SharkMascot> createState() => _SharkMascotState();
}

class _SharkMascotState extends State<SharkMascot>
    with TickerProviderStateMixin {
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );
  late final _reaction = AnimationController(vsync: this);
  late final _ticks = Listenable.merge([_idle, _reaction]);
  bool _motionEnabled = false;

  void _syncMotion() {
    final enabled = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (enabled == _motionEnabled) return;
    _motionEnabled = enabled;
    if (enabled) {
      _idle.repeat();
      _playReaction();
    } else {
      _idle.reset();
      _reaction.reset();
    }
  }

  void _playReaction() {
    if (!_motionEnabled || widget.mood == SharkMood.swim) {
      _reaction.reset();
      return;
    }
    _reaction.duration = Duration(
      milliseconds: switch (widget.mood) {
        SharkMood.greet => 820,
        SharkMood.correct => 550,
        SharkMood.encourage => 650,
        SharkMood.celebrate => 1000,
        SharkMood.swim => 0,
      },
    );
    _reaction.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(SharkMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (oldWidget.mood != widget.mood) _playReaction();
  }

  @override
  void dispose() {
    _idle.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(
              widget.size,
              constraints.biggest.shortestSide,
            );
            final skinId = SharkSkinScope.of(context);
            return Center(
              widthFactor: 1,
              heightFactor: 1,
              child: SizedBox.square(
                dimension: size,
                child: _buildPose(size, skinId),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Resting mouth openness for each mood.
  double get _baseMouth => switch (widget.mood) {
    SharkMood.swim => .35,
    SharkMood.greet => .6,
    SharkMood.correct => .7,
    SharkMood.encourage => .12,
    SharkMood.celebrate => .85,
  };

  Widget _buildPose(double size, int skinId) {
    return AnimatedBuilder(
      animation: _ticks,
      builder: (context, _) {
        final phase = _idle.value * math.pi * 2;
        final swim = math.sin(phase);
        final t = _reaction.value;
        final beat = math.sin(math.pi * t);
        final (lift, tilt, extraFin, scale) = switch (widget.mood) {
          SharkMood.greet => (
            .035 * beat,
            -.08 * beat,
            .85 * beat * math.sin(t * 5 * math.pi),
            1.0,
          ),
          SharkMood.correct => (
            .13 * beat,
            .24 * beat * math.sin(t * 2 * math.pi),
            .70 * beat,
            1 + .08 * beat,
          ),
          SharkMood.encourage => (
            -.05 * beat,
            -.18 * beat,
            .32 * beat,
            1 - .035 * beat,
          ),
          SharkMood.celebrate => (
            .13 * beat,
            -2 * math.pi * Curves.easeInOutCubic.transform(t),
            .8 * beat,
            1 + .05 * beat,
          ),
          SharkMood.swim => (0.0, 0.0, 0.0, 1.0),
        };
        final blink = (1 - (_idle.value - .57).abs() / .038).clamp(0.0, 1.0);
        final moving = _motionEnabled;

        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            if (moving && widget.mood == SharkMood.celebrate && t > 0 && t < 1)
              CustomPaint(painter: _Bubbles(t)),
            Transform.translate(
              offset: Offset(swim * size * .045, -(swim * .042 + lift) * size),
              child: Transform.rotate(
                angle: swim * .08 + tilt,
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: SharkArtPainter(
                          tail: moving ? math.sin(phase * 2) : 0,
                          fin: moving
                              ? math.sin(phase * 2 + .8) * .34 + extraFin
                              : 0,
                          blink: moving ? blink * .96 : 0,
                          mouth: (_baseMouth + (moving ? .25 * beat : 0)).clamp(
                            0.0,
                            1.0,
                          ),
                          skinId: skinId,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Bubbles extends CustomPainter {
  const _Bubbles(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (var i = 0; i < 10; i++) {
      final t = ((progress - (i % 3) * .06) / .88).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final angle = i * math.pi * 2 / 10;
      final radius = size.width * (.22 + .43 * Curves.easeOut.transform(t));
      final center =
          size.center(Offset.zero) +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius - size.height * .09 * t,
          );
      final color = i.isEven
          ? const Color(0xFF29A6E6)
          : const Color(0xFFDBA02E);
      paint.color = color.withValues(alpha: .9 * (1 - t));
      canvas.drawCircle(center, 3 + i % 3 + 3 * t, paint);
    }
  }

  @override
  bool shouldRepaint(_Bubbles oldDelegate) => oldDelegate.progress != progress;
}
