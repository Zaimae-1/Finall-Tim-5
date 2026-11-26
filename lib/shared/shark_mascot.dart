import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'shark_rig.dart';

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
  static const _asset = ResizeImage(
    AssetImage('assets/images/shark_mascot.png'),
    width: 720,
  );

  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );
  late final _reaction = AnimationController(vsync: this);
  late final _ticks = Listenable.merge([_idle, _reaction]);
  late final _imageListener = ImageStreamListener(_onImage);
  ImageStream? _stream;
  SharkRig? _rig;
  bool _motionEnabled = false;

  void _onImage(ImageInfo image, bool synchronous) {
    _rig?.dispose();
    _rig = SharkRig(image);
    if (!synchronous) setState(() {});
  }

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
    final stream = _asset.resolve(createLocalImageConfiguration(context));
    if (_stream?.key != stream.key) {
      _stream?.removeListener(_imageListener);
      _stream = stream;
      stream.addListener(_imageListener);
    }
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
    _stream?.removeListener(_imageListener);
    _rig?.dispose();
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
        final rig = _rig;

        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            if (_motionEnabled &&
                widget.mood == SharkMood.celebrate &&
                t > 0 &&
                t < 1)
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
                      rig != null && _motionEnabled
                          ? CustomPaint(
                              painter: _SharkPose(
                                rig: rig,
                                tail: math.sin(phase * 2),
                                fin: math.sin(phase * 2 + .8) * .34 + extraFin,
                                blink: blink * .96,
                              ),
                            )
                          : const Image(image: _asset, fit: BoxFit.contain),
                      if (skinId >= 0 && skinId < sharkSkinNames.length)
                        CustomPaint(painter: _SharkCostume(skinId)),
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

class _SharkPose extends CustomPainter {
  const _SharkPose({
    required this.rig,
    required this.tail,
    required this.fin,
    required this.blink,
  });

  final SharkRig rig;
  final double tail;
  final double fin;
  final double blink;

  @override
  void paint(Canvas canvas, Size size) =>
      rig.paint(canvas, size, tail: tail, fin: fin, blink: blink);

  @override
  bool shouldRepaint(_SharkPose oldDelegate) =>
      oldDelegate.rig != rig ||
      oldDelegate.tail != tail ||
      oldDelegate.fin != fin ||
      oldDelegate.blink != blink;
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

class _SharkCostume extends CustomPainter {
  const _SharkCostume(this.id);
  final int id;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint()..isAntiAlias = true;
    switch (id) {
      case 0: // Captain's tricorn.
        p.color = const Color(0xFF153752);
        canvas.drawPath(
          Path()
            ..moveTo(52, 30)
            ..quadraticBezierTo(67, 34, 91, 24)
            ..lineTo(84, 18)
            ..lineTo(63, 19)
            ..lineTo(53, 24)
            ..close(),
          p,
        );
        p.color = const Color(0xFFFFD36A);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(65, 23, 13, 3),
            const Radius.circular(2),
          ),
          p,
        );
      case 1: // Diver goggles.
        p.color = const Color(0xFF0A5679);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(61, 29, 28, 15),
            const Radius.circular(7),
          ),
          p,
        );
        p.color = const Color(0xFFB9F3FF);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(64, 31, 22, 11),
            const Radius.circular(5),
          ),
          p,
        );
        p.color = const Color(0x88FFFFFF);
        canvas.drawOval(const Rect.fromLTWH(68, 32, 7, 3), p);
      case 2: // Ocean crown.
        p.color = const Color(0xFFFFCB55);
        canvas.drawPath(
          Path()
            ..moveTo(62, 32)
            ..lineTo(58, 18)
            ..lineTo(66, 23)
            ..lineTo(72, 12)
            ..lineTo(79, 23)
            ..lineTo(88, 17)
            ..lineTo(86, 32)
            ..close(),
          p,
        );
        p.color = const Color(0xFF167AC1);
        canvas.drawCircle(const Offset(73, 27), 2.5, p);
      case 3: // Explorer's headband and compass.
        p.color = const Color(0xFF1A846E);
        canvas.drawPath(
          Path()
            ..moveTo(59, 27)
            ..quadraticBezierTo(74, 20, 88, 27)
            ..lineTo(87, 32)
            ..quadraticBezierTo(73, 26, 60, 32)
            ..close(),
          p,
        );
        p.color = const Color(0xFFFFE5A0);
        canvas.drawCircle(const Offset(72, 27), 3.5, p);
        p.color = const Color(0xFF173F55);
        canvas.drawCircle(const Offset(72, 27), 1.5, p);
      case 4: // Sailor cap.
        p.color = Colors.white;
        canvas.drawPath(
          Path()
            ..moveTo(61, 28)
            ..lineTo(64, 17)
            ..quadraticBezierTo(75, 14, 86, 19)
            ..lineTo(89, 29)
            ..close(),
          p,
        );
        p.color = const Color(0xFF164F7D);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(59, 27, 31, 6),
            const Radius.circular(3),
          ),
          p,
        );
        p.color = const Color(0xFFF0BA4A);
        canvas.drawCircle(const Offset(74, 25), 2, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SharkCostume oldDelegate) =>
      oldDelegate.id != id;
}
