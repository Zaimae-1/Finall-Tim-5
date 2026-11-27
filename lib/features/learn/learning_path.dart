import 'dart:async';
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
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 96,
                top: 64,
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
          Positioned(
            top: 10,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x99103552),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    icon: const Icon(
                      Icons.sailing_rounded,
                      color: Colors.white,
                    ),
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
                        PopupMenuItem(
                          value: level,
                          child: Text('Pulau $level'),
                        ),
                    ],
                  ),
                ],
              ),
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
                            : '${shipName(shipTier(level))} level $level',
                        child: _AnimatedMapIcon(
                          island: island,
                          tier: shipTier(level),
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
                  child: _SharkGuide(
                    level: level,
                    island: island,
                    allDone: allDone,
                    animate: animate,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

const sharkTips = [
  'Latihan 5 menit setiap hari lebih ampuh daripada belajar sekali seminggu.',
  'Salah itu wajar. Dari jawaban yang salah, otakmu belajar paling banyak!',
  'Ucapkan kalimat bahasa Inggris keras-keras, walau cuma sendirian.',
  'Hafalkan kata baru dalam kalimat, bukan satu per satu.',
  'Jaga streak apimu. Satu latihan kecil sudah cukup untuk hari ini!',
  'Dengarkan lagu berbahasa Inggris, lalu tebak arti liriknya.',
  'Beri label bahasa Inggris pada benda di kamarmu: door, window, bag.',
  'Ulangi kata yang sulit besok pagi. Pengulangan membuat ingatan awet.',
  'Jangan takut salah grammar. Yang penting berani mencoba berbicara.',
  'Tonton video favoritmu dengan subtitle bahasa Inggris.',
  'Tulis satu kalimat bahasa Inggris tentang harimu sebelum tidur.',
  'Level Treasure memberi 250 XP. Semangat menuju pulau berikutnya!',
  'Pakai XP Booster sebelum latihan agar bonus XP-mu maksimal.',
  'Belajar sambil bermain: tantang temanmu menyusun kalimat bareng.',
  'Kosakata baru paling cepat menempel kalau kamu langsung memakainya.',
  'Istirahat sejenak itu penting. Otak menyimpan pelajaran saat kamu tenang.',
  'Bayangkan dirimu ngobrol dengan turis. Kamu pasti bisa!',
  'Satu level hari ini, satu langkah lebih dekat ke fasih berbahasa Inggris.',
];

class _SharkGuide extends StatefulWidget {
  const _SharkGuide({
    required this.level,
    required this.island,
    required this.allDone,
    required this.animate,
  });

  final int level;
  final bool island;
  final bool allDone;
  final bool animate;

  @override
  State<_SharkGuide> createState() => _SharkGuideState();
}

class _SharkGuideState extends State<_SharkGuide> {
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _message {
    if (widget.allDone) return 'Hebat! Semua level selesai.';
    // Even steps nudge toward the active level; odd steps rotate the tips.
    if (_step.isEven) {
      return widget.island
          ? 'Buka peti Treasure ini!'
          : 'Ayo selesaikan level ${widget.level}!';
    }
    final offset = widget.level % sharkTips.length;
    return sharkTips[(offset + _step ~/ 2) % sharkTips.length];
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context) || !widget.animate;
    final message = _message;
    return Column(
      children: [
        AnimatedSwitcher(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: .9, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(message),
            constraints: const BoxConstraints(maxWidth: 138),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x300D5477),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ),
        SharkMascot(
          size: 68,
          animate: widget.animate,
          mood: widget.allDone ? SharkMood.celebrate : SharkMood.greet,
        ),
      ],
    );
  }
}

class _AnimatedMapIcon extends StatefulWidget {
  const _AnimatedMapIcon({
    required this.island,
    required this.tier,
    required this.animate,
    required this.muted,
    required this.opened,
  });
  final bool island;
  final int tier;
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
                    child: CustomPaint(
                      size: const Size(94, 85),
                      painter: _BoatPainter(widget.tier),
                    ),
                  ),
                ),
        );
      },
    ),
  );
}

/// Ships grow with every Treasure checkpoint: levels 1-4 are tier 0,
/// 6-9 tier 1, 11-14 tier 2, and so on up to tier 19 at levels 96-99.
int shipTier(int level) => ((level - 1) ~/ 5).clamp(0, 19);

const _shipNames = [
  'Perahu Kayu',
  'Perahu Kecil',
  'Kapal Kecil (Sloop)',
  'Kutter Layar',
  'Skuner',
  'Brigantine',
  'Karavel',
  'Kapal Dagang',
  'Galai Emas',
  'Barque',
  'Kapal Layar Agung',
  'Fregat',
  'Kapal Penjelajah',
  'Galleon',
  'Kapal Kapten',
  'Kapal Perang',
  'Kapal Emas',
  'Kapal Kerajaan',
  'Kapal Legenda',
  'Kapal Raja Laut',
];

String shipName(int tier) => _shipNames[tier.clamp(0, _shipNames.length - 1)];

class _BoatPainter extends CustomPainter {
  const _BoatPainter(this.tier);
  final int tier;

  static const _hulls = [
    Color(0xFF7A5232),
    Color(0xFF8C5C34),
    Color(0xFF133D5E),
    Color(0xFF1B4F7A),
    Color(0xFF0F5C58),
    Color(0xFF8E2433),
    Color(0xFF5B2A86),
    Color(0xFF16413B),
    Color(0xFF1E2A4F),
    Color(0xFF7D1D2E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    const cx = 47.0;
    final hw = (54 + tier * 1.8) / 2;
    const deck = 53.0;
    final hull = _hulls[(tier ~/ 2).clamp(0, _hulls.length - 1)];
    const gold = Color(0xFFFFD36A);

    if (tier >= 14) {
      p.shader = RadialGradient(
        colors: [gold.withValues(alpha: .38), gold.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: const Offset(cx, 42), radius: 46));
      canvas.drawCircle(const Offset(cx, 42), 46, p);
      p.shader = null;
    }

    p.color = const Color(0xBFFFFFFF);
    canvas.drawArc(
      Rect.fromLTWH(cx - hw - 6, 65, hw * 2 + 12, 14),
      0,
      math.pi,
      false,
      p,
    );

    final masts = tier == 0 ? 0 : math.min(1 + (tier - 1) ~/ 5, 4);
    final mastHeight = math.min(30.0 + tier * .75, 46.0);
    final sailWidth = math.min(26.0, (hw * 1.5) / math.max(masts, 1) - 2);
    for (var i = 0; i < masts; i++) {
      final x = masts == 1 ? cx : cx - hw * .55 + i * (hw * 1.1) / (masts - 1);
      final top = deck - mastHeight + (i.isOdd ? 5 : 0);
      p.color = const Color(0xFF654C36);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 1.5, top, 3, deck - top + 2),
          const Radius.circular(2),
        ),
        p,
      );
      p.color = tier >= 8 && i.isOdd ? gold : Colors.white;
      canvas.drawPath(
        Path()
          ..moveTo(x - 2, top + 4)
          ..lineTo(x - sailWidth, deck - 7)
          ..lineTo(x - 2, deck - 7)
          ..close(),
        p,
      );
      p.color = tier >= 3 ? gold : const Color(0xFFFFE8A6);
      canvas.drawPath(
        Path()
          ..moveTo(x + 2, top + 3)
          ..lineTo(x + sailWidth * .85, deck - 7)
          ..lineTo(x + 2, deck - 7)
          ..close(),
        p,
      );
      if (tier >= 2) {
        p.color = tier >= 10
            ? const Color(0xFFFF5D73)
            : const Color(0xFFE94B5E);
        canvas.drawPath(
          Path()
            ..moveTo(x + 1.5, top)
            ..lineTo(x + 11, top + 3)
            ..lineTo(x + 1.5, top + 6)
            ..close(),
          p,
        );
      }
    }

    if (tier == 0) {
      p.color = const Color(0xFF4B3524);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 2.5;
      p.strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(36, 44), const Offset(60, 62), p);
      p.style = PaintingStyle.fill;
    }

    p.color = hull;
    canvas.drawPath(
      Path()
        ..moveTo(cx - hw, deck)
        ..lineTo(cx + hw, deck)
        ..lineTo(cx + hw - 11, 69)
        ..quadraticBezierTo(cx, 78, cx - hw + 11, 69)
        ..close(),
      p,
    );
    p.color = tier >= 8 ? gold : const Color(0xFF0E76AE);
    canvas.drawPath(
      Path()
        ..moveTo(cx - hw + 5, deck)
        ..lineTo(cx + hw - 5, deck)
        ..lineTo(cx + hw - 8, deck + 5)
        ..lineTo(cx - hw + 8, deck + 5)
        ..close(),
      p,
    );

    if (tier >= 4) {
      p.color = const Color(0xFF3A2A1E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + hw * .3, deck - 9, hw * .55, 10),
          const Radius.circular(2),
        ),
        p,
      );
      p.color = const Color(0xFFB3EFFF);
      canvas.drawCircle(Offset(cx + hw * .58, deck - 4), 2, p);
    }
    if (tier >= 6) {
      p.color = gold;
      for (var i = 0; i < math.min(2 + (tier - 6) ~/ 4, 4); i++) {
        canvas.drawCircle(Offset(cx - hw * .5 + i * hw * .38, 62), 2, p);
      }
    }
    if (tier >= 17) {
      p.color = gold;
      canvas.drawCircle(const Offset(cx, 4.5), 3.5, p);
    }
    p.color = const Color(0xFFB3EFFF);
    canvas.drawCircle(Offset(cx - hw - 4, 72), 2.5, p);
    canvas.drawCircle(Offset(cx + hw + 2, 75), 2, p);
  }

  @override
  bool shouldRepaint(covariant _BoatPainter oldDelegate) =>
      oldDelegate.tier != tier;
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
