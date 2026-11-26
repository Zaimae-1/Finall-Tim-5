import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/motion.dart';
import '../../shared/shark_mascot.dart';
import 'course.dart';

const _ink = Color(0xFF103552);
const _deep = Color(0xFF075DAB);
const _stopExtent = 220.0;

/// A treasure map: the first lesson starts at the bottom and the route rises.
class LearningPath extends StatefulWidget {
  const LearningPath({
    super.key,
    required this.lessons,
    required this.completed,
    required this.animate,
    required this.onOpen,
    this.recentlyCompleted,
  });

  final List<Lesson> lessons;
  final Set<String> completed;
  final bool animate;
  final String? recentlyCompleted;
  final ValueChanged<Lesson> onOpen;

  @override
  State<LearningPath> createState() => _LearningPathState();
}

class _LearningPathState extends State<LearningPath> {
  final _scroll = ScrollController();

  int get _activeLevel {
    final index = widget.lessons.indexWhere(
      (lesson) => !widget.completed.contains(lesson.id),
    );
    return index < 0 ? widget.lessons.length : index + 1;
  }

  @override
  void didUpdateWidget(covariant LearningPath oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.lessons.indexWhere(
      (lesson) => !oldWidget.completed.contains(lesson.id),
    );
    if (previous + 1 != _activeLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToLevel(_activeLevel);
      });
    }
  }

  void _goToLevel(int level) {
    if (!_scroll.hasClients) return;
    final target = ((level - 1) * _stopExtent).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context) || !widget.animate) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) || !widget.animate;
    final activeLevel = _activeLevel;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAAE9EF), Color(0xFF54B9D7), Color(0xFF0978AC)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jalur belajar',
                        style: TextStyle(
                          color: Color(0xFF144A69),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Peta petualangan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                        ),
                      ),
                      Text(
                        '${widget.completed.length} / ${widget.lessons.length} level selesai',
                        style: const TextStyle(
                          color: Color(0xFFECFAFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ke level aktif $activeLevel',
                  onPressed: () => _goToLevel(activeLevel),
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Pilih pulau atau level',
                  icon: const Icon(Icons.sailing_rounded, color: Colors.white),
                  onSelected: _goToLevel,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 1,
                      child: Text('Level 1 · Mulai'),
                    ),
                    for (
                      var level = 5;
                      level <= widget.lessons.length;
                      level += 5
                    )
                      PopupMenuItem(value: level, child: Text('Pulau $level')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 96,
                top: 24,
              ),
              itemExtent: _stopExtent,
              itemCount: widget.lessons.length,
              itemBuilder: (context, index) {
                final lesson = widget.lessons[index];
                return CustomPaint(
                  painter: _SeaMapPainter(index + 1),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _MapStop(
                      level: index + 1,
                      lesson: lesson,
                      done: widget.completed.contains(lesson.id),
                      active: index + 1 == activeLevel,
                      allDone: widget.completed.length == widget.lessons.length,
                      unlocked:
                          index == 0 ||
                          widget.completed.contains(
                            widget.lessons[index - 1].id,
                          ),
                      animate: !reduceMotion,
                      justUnlocked:
                          index > 0 &&
                          widget.lessons[index - 1].id ==
                              widget.recentlyCompleted,
                      onOpen: () => widget.onOpen(lesson),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStop extends StatelessWidget {
  const _MapStop({
    required this.level,
    required this.lesson,
    required this.done,
    required this.active,
    required this.allDone,
    required this.unlocked,
    required this.animate,
    required this.justUnlocked,
    required this.onOpen,
  });

  final int level;
  final Lesson lesson;
  final bool done;
  final bool active;
  final bool allDone;
  final bool unlocked;
  final bool animate;
  final bool justUnlocked;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final island = isTreasureLevel(level);
    return LayoutBuilder(
      builder: (context, constraints) {
        final shift = (level.isOdd ? -.11 : .11) * constraints.maxWidth;
        final cardWidth = math.min(
          constraints.maxWidth - shift.abs() * 2 - 20,
          286.0,
        );
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(shift, active ? 42 : 20),
              child: Center(
                child: SizedBox(
                  width: cardWidth,
                  child: Column(
                    children: [
                      Semantics(
                        label: island
                            ? 'Pulau harta karun level $level'
                            : 'Kapal level $level',
                        child: _AnimatedMapIcon(
                          island: island,
                          animate: animate,
                          muted: !unlocked,
                          opened: done,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Material(
                        color: unlocked
                            ? Colors.white.withValues(alpha: .95)
                            : const Color(0xFFE3F0F3),
                        borderRadius: BorderRadius.circular(18),
                        elevation: unlocked ? 4 : 0,
                        child: ListTile(
                          dense: true,
                          onTap: unlocked ? onOpen : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 17,
                            backgroundColor: island
                                ? const Color(0xFFFFDC76)
                                : const Color(0xFFD7F1FA),
                            child: Text(
                              '$level',
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          title: Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            island && !done
                                ? '+250 XP • ${lesson.description}'
                                : done
                                ? 'Selesai ✓'
                                : unlocked
                                ? lesson.description
                                : 'Selesaikan level sebelumnya',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF47647A),
                            ),
                          ),
                          trailing: Icon(
                            done
                                ? Icons.check_circle_rounded
                                : unlocked
                                ? Icons.play_circle_fill_rounded
                                : Icons.lock_rounded,
                            size: 23,
                            color: done
                                ? const Color(0xFF168567)
                                : unlocked
                                ? _deep
                                : const Color(0xFF7996A4),
                          ),
                        ),
                      ),
                      if (justUnlocked)
                        const Text(
                          'TERBUKA!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (active)
              Positioned(
                top: 0,
                left: level.isOdd ? null : 8,
                right: level.isOdd ? 8 : null,
                child: MotionReveal(
                  key: ValueKey('guide-$level'),
                  child: Column(
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x300D5477),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          allDone
                              ? 'Hebat! Semua level selesai.'
                              : island
                              ? 'Buka peti Treasure ini!'
                              : 'Ayo selesaikan level $level!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SharkMascot(
                        size: 68,
                        animate: animate,
                        mood: allDone ? SharkMood.celebrate : SharkMood.greet,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnimatedMapIcon extends StatefulWidget {
  const _AnimatedMapIcon({
    required this.island,
    required this.animate,
    required this.muted,
    required this.opened,
  });
  final bool island;
  final bool animate;
  final bool muted;
  final bool opened;

  @override
  State<_AnimatedMapIcon> createState() => _AnimatedMapIconState();
}

class _AnimatedMapIconState extends State<_AnimatedMapIcon>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedMapIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = .5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 94,
    height: 85,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = widget.animate
            ? math.sin(_controller.value * math.pi) * 2 - 1
            : 0.0;
        return Opacity(
          opacity: widget.muted ? .65 : 1,
          child: widget.island
              ? Stack(
                  children: [
                    CustomPaint(
                      size: const Size(94, 85),
                      painter: _IslandPainter(opened: widget.opened),
                    ),
                    Positioned(
                      left: 34,
                      top: 5,
                      child: Transform.rotate(
                        angle: phase * .075,
                        alignment: Alignment.bottomCenter,
                        child: const CustomPaint(
                          size: Size(48, 65),
                          painter: _PalmPainter(),
                        ),
                      ),
                    ),
                  ],
                )
              : Transform.translate(
                  offset: Offset(0, phase * 3),
                  child: Transform.rotate(
                    angle: phase * .045,
                    child: const CustomPaint(
                      size: Size(94, 85),
                      painter: _BoatPainter(),
                    ),
                  ),
                ),
        );
      },
    ),
  );
}

class _BoatPainter extends CustomPainter {
  const _BoatPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    p.color = const Color(0xBFFFFFFF);
    canvas.drawArc(const Rect.fromLTWH(5, 65, 84, 14), 0, math.pi, false, p);
    p.color = const Color(0xFF133D5E);
    canvas.drawPath(
      Path()
        ..moveTo(12, 52)
        ..lineTo(84, 52)
        ..lineTo(73, 68)
        ..quadraticBezierTo(48, 77, 22, 68)
        ..close(),
      p,
    );
    p.color = const Color(0xFF0E76AE);
    canvas.drawPath(
      Path()
        ..moveTo(18, 52)
        ..lineTo(78, 52)
        ..lineTo(72, 59)
        ..lineTo(22, 59)
        ..close(),
      p,
    );
    p.color = const Color(0xFF654C36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 8, 3, 46),
        const Radius.circular(2),
      ),
      p,
    );
    p.color = Colors.white;
    canvas.drawPath(
      Path()
        ..moveTo(43, 12)
        ..lineTo(14, 45)
        ..lineTo(43, 45)
        ..close(),
      p,
    );
    p.color = const Color(0xFFFFD36A);
    canvas.drawPath(
      Path()
        ..moveTo(50, 11)
        ..lineTo(74, 45)
        ..lineTo(50, 45)
        ..close(),
      p,
    );
    p.color = const Color(0xFFB3EFFF);
    canvas.drawCircle(const Offset(14, 72), 2.5, p);
    canvas.drawCircle(const Offset(80, 75), 2, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IslandPainter extends CustomPainter {
  const _IslandPainter({required this.opened});
  final bool opened;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    p.color = const Color(0xAAE8FAFF);
    canvas.drawOval(const Rect.fromLTWH(1, 62, 92, 19), p);
    p.color = const Color(0xFFF6CE78);
    canvas.drawOval(const Rect.fromLTWH(7, 49, 81, 25), p);
    p.color = const Color(0xFF58A86B);
    canvas.drawOval(const Rect.fromLTWH(18, 46, 62, 14), p);
    p.color = const Color(0xFF71482F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 39, 27, 22),
        const Radius.circular(3),
      ),
      p,
    );
    p.color = const Color(0xFFFFD978);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        opened
            ? const Rect.fromLTWH(15, 28, 27, 8)
            : const Rect.fromLTWH(19, 35, 25, 9),
        const Radius.circular(2),
      ),
      p,
    );
    p.color = const Color(0xFF51331F);
    canvas.drawRect(const Rect.fromLTWH(29, 40, 5, 20), p);
    p.color = const Color(0xFFFFF2B7);
    canvas.drawCircle(const Offset(31.5, 49), 2.5, p);
  }

  @override
  bool shouldRepaint(covariant _IslandPainter oldDelegate) =>
      oldDelegate.opened != opened;
}

class _PalmPainter extends CustomPainter {
  const _PalmPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final trunk = Paint()
      ..color = const Color(0xFF82543B)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(18, 61), const Offset(25, 22), trunk);
    final leaf = Paint()
      ..color = const Color(0xFF137B64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final tip in [
      const Offset(3, 22),
      const Offset(10, 9),
      const Offset(30, 5),
      const Offset(45, 18),
      const Offset(43, 34),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(25, 22)
          ..quadraticBezierTo((25 + tip.dx) / 2, tip.dy - 8, tip.dx, tip.dy),
        leaf,
      );
    }
    final coconut = Paint()..color = const Color(0xFF7B5139);
    canvas.drawCircle(const Offset(22, 26), 3, coconut);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeaMapPainter extends CustomPainter {
  const _SeaMapPainter(this.level);
  final int level;
  @override
  void paint(Canvas canvas, Size size) {
    final wave = Paint()
      ..color = const Color(0x34FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var row = 0; row < size.height / 85; row++) {
      final y = row * 85.0 + 35;
      final path = Path()..moveTo(-15, y);
      for (var x = -15.0; x < size.width + 55; x += 80) {
        path.quadraticBezierTo(x + 20, y - 12, x + 40, y);
        path.quadraticBezierTo(x + 60, y + 12, x + 80, y);
      }
      canvas.drawPath(path, wave);
    }
    final route = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (level < 100) {
      final bottom = size.height + 20;
      final top = -20.0;
      final x1 = size.width * (level.isOdd ? .39 : .61);
      final x2 = size.width * (level.isOdd ? .61 : .39);
      final path = Path()
        ..moveTo(x1, bottom)
        ..cubicTo(x1 - 32, bottom - 56, x2 + 32, top + 56, x2, top);
      final metrics = path.computeMetrics().first;
      for (var distance = 0.0; distance < metrics.length; distance += 16) {
        final point = metrics.getTangentForOffset(distance)!.position;
        canvas.drawCircle(point, 2.3, route..style = PaintingStyle.fill);
      }
      route.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _SeaMapPainter oldDelegate) =>
      oldDelegate.level != level;
}
