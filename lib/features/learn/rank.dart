import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Each boundary belongs to the rank that starts there. XP 0 starts at Bronze.
enum RankTier {
  bronze('Bronze', 0, Color(0xFFB97B4A)),
  silver('Silver', 30, Color(0xFFC8D6DF)),
  gold('Gold', 60, Color(0xFFF4BA48)),
  platinum('Platinum', 100, Color(0xFF62C4CE)),
  diamond('Diamond', 200, Color(0xFFD78AE3)),
  ascendant('Ascendant', 300, Color(0xFF53CB8A)),
  immortal('Immortal', 400, Color(0xFFF2728E)),
  radiant('Radiant', 1000, Color(0xFFFFE398));

  const RankTier(this.label, this.minXp, this.color);
  final String label;
  final int minXp;
  final Color color;

  RankTier? get next => index + 1 < values.length ? values[index + 1] : null;
}

RankTier rankForXp(int xp) {
  for (final tier in RankTier.values.reversed) {
    if (xp >= tier.minXp) return tier;
  }
  return RankTier.bronze;
}

double rankProgress(int xp) {
  final tier = rankForXp(xp);
  final next = tier.next;
  if (next == null) return 1;
  return ((xp - tier.minXp) / (next.minXp - tier.minXp)).clamp(0, 1).toDouble();
}

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 36});
  final RankTier rank;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Lencana ${rank.label}',
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RankBadgePainter(rank)),
    ),
  );
}

class _RankBadgePainter extends CustomPainter {
  const _RankBadgePainter(this.rank);
  final RankTier rank;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final metal = Paint()..isAntiAlias = true;
    final outline = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF17344A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round;

    final outer = switch (rank) {
      RankTier.bronze => _polygon([
        const Offset(15, 22),
        const Offset(85, 22),
        const Offset(50, 88),
      ]),
      RankTier.silver => _polygon([
        const Offset(50, 7),
        const Offset(92, 50),
        const Offset(50, 93),
        const Offset(8, 50),
      ]),
      RankTier.gold => _polygon([
        const Offset(25, 10),
        const Offset(75, 10),
        const Offset(93, 50),
        const Offset(75, 90),
        const Offset(25, 90),
        const Offset(7, 50),
      ]),
      RankTier.platinum => _polygon([
        const Offset(30, 7),
        const Offset(70, 7),
        const Offset(93, 30),
        const Offset(93, 70),
        const Offset(70, 93),
        const Offset(30, 93),
        const Offset(7, 70),
        const Offset(7, 30),
      ]),
      RankTier.diamond => _polygon([
        const Offset(50, 5),
        const Offset(87, 30),
        const Offset(95, 62),
        const Offset(50, 96),
        const Offset(5, 62),
        const Offset(13, 30),
      ]),
      RankTier.ascendant => _polygon([
        const Offset(50, 3),
        const Offset(93, 51),
        const Offset(50, 97),
        const Offset(7, 51),
      ]),
      RankTier.immortal => _star(50, 50, 47, 25, 4),
      RankTier.radiant => _polygon([
        const Offset(50, 3),
        const Offset(91, 33),
        const Offset(83, 81),
        const Offset(50, 98),
        const Offset(17, 81),
        const Offset(9, 33),
      ]),
    };
    metal.color = const Color(0xFF274559);
    canvas.drawPath(outer, metal);
    canvas.drawPath(outer, outline);

    final inset = switch (rank) {
      RankTier.bronze => _polygon([
        const Offset(28, 32),
        const Offset(72, 32),
        const Offset(50, 72),
      ]),
      RankTier.immortal => _star(50, 50, 32, 13, 4),
      RankTier.radiant => _polygon([
        const Offset(50, 19),
        const Offset(75, 39),
        const Offset(69, 71),
        const Offset(50, 84),
        const Offset(31, 71),
        const Offset(25, 39),
      ]),
      _ => _polygon([
        const Offset(50, 19),
        const Offset(77, 50),
        const Offset(50, 81),
        const Offset(23, 50),
      ]),
    };
    metal.color = rank.color;
    canvas.drawPath(inset, metal);
    final highlight = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(35, 27)
        ..lineTo(50, 17)
        ..lineTo(65, 27),
      highlight,
    );

    final core = rank == RankTier.radiant
        ? _star(50, 50, 19, 8, 4)
        : _polygon([
            const Offset(50, 31),
            const Offset(66, 50),
            const Offset(50, 69),
            const Offset(34, 50),
          ]);
    metal.color = Color.lerp(rank.color, Colors.white, .67)!;
    canvas.drawPath(core, metal);
    metal.color = Colors.white.withValues(alpha: .72);
    canvas.drawPath(
      Path()
        ..moveTo(50, 31)
        ..lineTo(66, 50)
        ..lineTo(50, 50)
        ..close(),
      metal,
    );

    if (rank.index >= RankTier.ascendant.index) {
      metal.color = rank.color.withValues(alpha: .8);
      canvas.drawPath(
        _polygon([
          const Offset(4, 43),
          const Offset(21, 50),
          const Offset(4, 57),
        ]),
        metal,
      );
      canvas.drawPath(
        _polygon([
          const Offset(96, 43),
          const Offset(79, 50),
          const Offset(96, 57),
        ]),
        metal,
      );
    }
    canvas.restore();
  }

  Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

  Path _star(double cx, double cy, double outer, double inner, int points) {
    final offsets = <Offset>[];
    for (var i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + i * math.pi / points;
      final radius = i.isEven ? outer : inner;
      offsets.add(
        Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
      );
    }
    return _polygon(offsets);
  }

  @override
  bool shouldRepaint(covariant _RankBadgePainter oldDelegate) =>
      oldDelegate.rank != rank;
}
