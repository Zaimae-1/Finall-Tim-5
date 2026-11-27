import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vector LingoShark mascot. Everything is drawn on a 100 x 100 grid so it
/// stays sharp at any size and each part can move on its own.
///
/// The shark faces right. Head geometry used by the costumes:
/// crown line y = 19 + .014 * (x - 66)^2, eyes at (63, 37) and (81, 33.5).
class SharkArtPainter extends CustomPainter {
  const SharkArtPainter({
    this.tail = 0,
    this.fin = 0,
    this.blink = 0,
    this.mouth = .35,
    this.skinId = -1,
  });

  /// Tail swing from -1 to 1.
  final double tail;

  /// Waving fin swing, roughly -1 to 1.
  final double fin;

  /// 0 = eyes open, 1 = closed.
  final double blink;

  /// 0 = small smile, 1 = wide open smile.
  final double mouth;

  /// Equipped costume, or -1 for none.
  final int skinId;

  static const _deep = Color(0xFF0F66C9);
  static const _mid = Color(0xFF1B88E8);
  static const _light = Color(0xFF46B4FA);
  static const _ink = Color(0xFF0B2A5B);
  static const _navy = Color(0xFF12337F);
  static const _gold = Color(0xFFFFC93C);

  static Path get _body => Path()
    ..moveTo(22, 68)
    ..cubicTo(19, 46, 35, 22, 58, 20)
    ..cubicTo(76, 18, 92, 28, 93, 48)
    ..cubicTo(94, 64, 80, 80, 60, 80)
    ..cubicTo(44, 80, 29, 78, 22, 68)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    // Leave a little margin so fins and costumes never touch the edge.
    canvas.translate(50, 50);
    canvas.scale(.94);
    canvas.translate(-50, -50);

    _wavingFin(canvas);
    _lowerFin(canvas);
    _tail(canvas);
    _dorsalFin(canvas);
    _bodyAndBelly(canvas);
    _gills(canvas);
    _face(canvas);
    _scarf(canvas);
    if (skinId >= 0 && skinId < 5) _costume(canvas, skinId);
    canvas.restore();
  }

  Paint _gradient(List<Color> colors, Rect rect, {bool vertical = false}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: vertical ? Alignment.topCenter : Alignment.topLeft,
        end: vertical ? Alignment.bottomCenter : Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
  }

  void _rotated(Canvas canvas, Offset pivot, double angle, VoidCallback draw) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    draw();
    canvas.restore();
  }

  void _wavingFin(Canvas canvas) {
    _rotated(canvas, const Offset(86, 58), -fin * .5, () {
      final path = Path()
        ..moveTo(84, 66)
        ..cubicTo(95, 70, 105, 59, 103, 38)
        ..cubicTo(97, 45, 91, 49, 82, 52)
        ..close();
      canvas.drawPath(
        path,
        _gradient([_light, _mid], const Rect.fromLTWH(82, 38, 22, 30)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(87, 62)
          ..cubicTo(94, 63, 100, 56, 99.5, 44)
          ..cubicTo(95, 50, 91, 53, 86, 55)
          ..close(),
        Paint()..color = const Color(0xFF8FDBFF),
      );
    });
  }

  void _lowerFin(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(52, 72)
        ..cubicTo(46, 80, 40, 86, 34, 89)
        ..cubicTo(44, 93, 57, 89, 63, 78)
        ..close(),
      _gradient([
        const Color(0xFF69D0FF),
        _mid,
      ], const Rect.fromLTWH(34, 72, 30, 21)),
    );
  }

  void _tail(Canvas canvas) {
    _rotated(canvas, const Offset(30, 66), tail * .2, () {
      final path = Path()
        ..moveTo(31, 61)
        ..cubicTo(22, 60, 12, 54, 5, 43)
        ..cubicTo(8, 56, 13, 63, 16, 68)
        ..cubicTo(13, 75, 10, 81, 6, 89)
        ..cubicTo(17, 85, 26, 79, 32, 72)
        ..close();
      canvas.drawPath(
        path,
        _gradient([_mid, _deep], const Rect.fromLTWH(5, 43, 27, 46)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(16, 68)
          ..cubicTo(14, 74, 11, 80, 8, 86)
          ..cubicTo(14, 83, 19, 80, 23, 75)
          ..cubicTo(19, 73, 17, 71, 16, 68)
          ..close(),
        Paint()..color = const Color(0x6678D6FF),
      );
    });
  }

  void _dorsalFin(Canvas canvas) {
    final path = Path()
      ..moveTo(31, 36)
      ..quadraticBezierTo(32, 14, 49, 5)
      ..quadraticBezierTo(50, 16, 63, 23)
      ..lineTo(52, 38)
      ..close();
    canvas.drawPath(
      path,
      _gradient([_mid, _deep], const Rect.fromLTWH(31, 5, 32, 33)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(36, 30)
        ..quadraticBezierTo(38, 17, 47, 11)
        ..quadraticBezierTo(47, 18, 54, 24)
        ..close(),
      Paint()..color = const Color(0x3DFFFFFF),
    );
  }

  void _bodyAndBelly(Canvas canvas) {
    final body = _body;
    canvas.drawPath(
      body,
      _gradient([_light, _mid, _deep], const Rect.fromLTWH(19, 18, 76, 64)),
    );
    canvas.save();
    canvas.clipPath(body);
    // Belly.
    canvas.drawPath(
      Path()
        ..moveTo(16, 76)
        ..cubicTo(36, 61, 56, 59, 72, 53)
        ..cubicTo(80, 50, 89, 49, 97, 53)
        ..lineTo(100, 100)
        ..lineTo(10, 100)
        ..close(),
      _gradient(
        [Colors.white, const Color(0xFFD4EAFB)],
        const Rect.fromLTWH(16, 49, 84, 51),
        vertical: true,
      ),
    );
    // Soft shade at the very bottom for volume.
    canvas.drawRect(
      const Rect.fromLTWH(10, 72, 90, 12),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x1F0F66C9)],
        ).createShader(const Rect.fromLTWH(10, 72, 90, 12)),
    );
    // Forehead shine.
    canvas.save();
    canvas.translate(64, 26);
    canvas.rotate(-.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 26, height: 7),
      Paint()..color = const Color(0x40FFFFFF),
    );
    canvas.restore();
    canvas.restore();
  }

  void _gills(Canvas canvas) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7
      ..color = const Color(0xCC0A55B0);
    for (var i = 0; i < 3; i++) {
      final x = 43.0 + i * 4.6;
      canvas.drawPath(
        Path()
          ..moveTo(x, 40 - i * .4)
          ..quadraticBezierTo(x - 3.2, 46.5, x - .2, 53),
        paint,
      );
    }
  }

  void _face(Canvas canvas) {
    final cheek = Paint()..color = const Color(0x73FF8FA3);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(57.5, 47), width: 7.5, height: 4.2),
      cheek,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(88, 43.5), width: 6, height: 3.8),
      cheek,
    );

    _eye(canvas, const Offset(63, 37), 1);
    _eye(canvas, const Offset(81, 33.5), .93);
    _mouth(canvas);
  }

  void _eye(Canvas canvas, Offset center, double scale) {
    final open = (1 - blink * .94).clamp(.06, 1.0);
    final rx = 4.3 * scale;
    final ry = 5.3 * scale * open;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()..color = _ink,
    );
    if (open > .45) {
      final white = Paint()..color = Colors.white;
      canvas.drawCircle(
        center + Offset(-1.3 * scale, -1.9 * scale * open),
        1.7 * scale,
        white,
      );
      canvas.drawCircle(
        center + Offset(1.3 * scale, 1.9 * scale * open),
        .75 * scale,
        white,
      );
    }
  }

  void _mouth(Canvas canvas) {
    final depth = 2.6 + 11 * mouth.clamp(0.0, 1.0);
    final path = Path()
      ..moveTo(69, 54.5)
      ..quadraticBezierTo(79.5, 54.5 + depth * 2, 90, 53)
      ..quadraticBezierTo(79.5, 53.1, 69, 54.5)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF8E1F45));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(80, 54.5 + depth * .95),
        width: 13,
        height: depth * 1.1,
      ),
      Paint()..color = const Color(0xFFFF7D96),
    );
    if (depth > 5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(73, 53.4, 3.6, math.min(3.6, depth * .45)),
          const Radius.circular(1.2),
        ),
        Paint()..color = Colors.white,
      );
    }
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(69, 54.5)
        ..quadraticBezierTo(79.5, 53.1, 90, 53),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.3
        ..color = const Color(0xFF6D1438),
    );
  }

  void _scarf(Canvas canvas) {
    const knot = Offset(66, 75);
    // Hanging tails.
    canvas.drawPath(
      Path()
        ..moveTo(63, 77)
        ..lineTo(55, 94)
        ..lineTo(66, 88)
        ..close(),
      Paint()..color = _navy,
    );
    canvas.drawPath(
      Path()
        ..moveTo(69, 77)
        ..lineTo(76, 95)
        ..lineTo(64, 88)
        ..close(),
      Paint()..color = const Color(0xFF0D2A6B),
    );
    // The band wraps around the body, so it is clipped to the silhouette.
    canvas.save();
    canvas.clipPath(_body);
    final band = Path()
      ..moveTo(26, 62)
      ..quadraticBezierTo(60, 90, 102, 60);
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.6
        ..color = _navy,
    );
    canvas.drawPath(
      band.shift(const Offset(0, -2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x4DFFFFFF),
    );
    canvas.restore();
    canvas.drawCircle(knot, 5.2, Paint()..color = _navy);
    canvas.drawPath(_star(knot, 4.2), Paint()..color = _gold);
  }

  Path _star(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * .45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  double _crown(double x) => 19 + .014 * (x - 66) * (x - 66);

  Path _band(double from, double to, double lift) {
    final path = Path()..moveTo(from, _crown(from) - lift);
    for (var x = from + 2; x <= to; x += 2) {
      path.lineTo(x, _crown(x) - lift);
    }
    return path;
  }

  void _costume(Canvas canvas, int id) {
    final p = Paint()..isAntiAlias = true;
    final stroke = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (id) {
      case 0: // Captain tricorn.
        final hat = Path()
          ..moveTo(47, 24)
          ..lineTo(54, 13)
          ..quadraticBezierTo(67, 3.5, 81, 12)
          ..lineTo(89, 24)
          ..quadraticBezierTo(68, 17.5, 47, 24)
          ..close();
        p.color = const Color(0xFF153752);
        canvas.drawPath(hat, p);
        stroke
          ..color = _gold
          ..strokeWidth = 1.8;
        canvas.drawPath(
          Path()
            ..moveTo(54, 13)
            ..quadraticBezierTo(67, 3.5, 81, 12),
          stroke,
        );
        p.color = _gold;
        canvas.drawCircle(const Offset(67.5, 13), 2.6, p);
        p.color = const Color(0xFF153752);
        canvas.drawCircle(const Offset(67.5, 13), 1.1, p);
      case 1: // Diver goggles resting on the forehead.
        stroke
          ..color = const Color(0xFF0A5679)
          ..strokeWidth = 3.4;
        canvas.drawPath(_band(48, 88, 1.6), stroke);
        for (final (cx, cy) in const [(59.0, 15.0), (75.5, 12.5)]) {
          p.color = const Color(0xFF0A5679);
          canvas.drawCircle(Offset(cx, cy), 7.2, p);
          p.color = const Color(0xFFB9F3FF);
          canvas.drawCircle(Offset(cx, cy), 5.4, p);
          p.color = const Color(0xCCFFFFFF);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx - 1.6, cy - 2),
              width: 3.8,
              height: 2.1,
            ),
            p,
          );
        }
        p.color = const Color(0xFF0A5679);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(64, 12, 6.4, 3.4),
            const Radius.circular(1.7),
          ),
          p,
        );
      case 2: // Ocean crown.
        p.color = const Color(0xFFFFCB55);
        canvas.drawPath(
          Path()
            ..moveTo(54, 24)
            ..lineTo(52, 8)
            ..lineTo(60.5, 14.5)
            ..lineTo(67.5, 4)
            ..lineTo(74.5, 14.5)
            ..lineTo(83, 7)
            ..lineTo(82, 24)
            ..close(),
          p,
        );
        p.color = const Color(0xFFE8A92E);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(53.5, 19.5, 29, 5),
            const Radius.circular(1.8),
          ),
          p,
        );
        p.color = const Color(0xFF167AC1);
        canvas.drawCircle(const Offset(68, 22), 2, p);
        p.color = const Color(0xFFFF5D73);
        canvas.drawCircle(const Offset(58.5, 22), 1.4, p);
        canvas.drawCircle(const Offset(77.5, 22), 1.4, p);
        p.color = Colors.white;
        for (final tip in const [
          Offset(52, 8),
          Offset(67.5, 4),
          Offset(83, 7),
        ]) {
          canvas.drawCircle(tip, 1.6, p);
        }
      case 3: // Explorer headband and compass.
        stroke
          ..color = const Color(0xFF1A846E)
          ..strokeWidth = 3.8;
        canvas.drawPath(_band(48, 88, 2.2), stroke);
        stroke.strokeWidth = 2.6;
        canvas.drawPath(
          Path()
            ..moveTo(49.5, _crown(49.5) - 2)
            ..lineTo(43.5, 28)
            ..moveTo(50.5, _crown(50.5) - 1.2)
            ..lineTo(46.5, 31.5),
          stroke,
        );
        p.color = const Color(0xFFFFE5A0);
        canvas.drawCircle(const Offset(67.5, 17), 5, p);
        stroke
          ..color = const Color(0xFF173F55)
          ..strokeWidth = 1;
        canvas.drawCircle(const Offset(67.5, 17), 5, stroke);
        p.color = const Color(0xFFE94B5E);
        canvas.drawPath(
          Path()
            ..moveTo(67.5, 13)
            ..lineTo(69.1, 17)
            ..lineTo(65.9, 17)
            ..close(),
          p,
        );
        p.color = const Color(0xFF173F55);
        canvas.drawPath(
          Path()
            ..moveTo(67.5, 21)
            ..lineTo(69.1, 17)
            ..lineTo(65.9, 17)
            ..close(),
          p,
        );
      case 4: // Sailor cap.
        final cap = Path()
          ..moveTo(51, 21)
          ..quadraticBezierTo(52.5, 7, 68, 6)
          ..quadraticBezierTo(84, 7, 86, 22)
          ..close();
        p.color = Colors.white;
        canvas.drawPath(cap, p);
        stroke
          ..color = const Color(0xFF8FB8D3)
          ..strokeWidth = 1;
        canvas.drawPath(cap, stroke);
        stroke
          ..color = const Color(0xFF164F7D)
          ..strokeWidth = 4.6;
        canvas.drawPath(_band(49, 89, 1.6), stroke);
        p.color = const Color(0xFFF0BA4A);
        canvas.drawCircle(const Offset(68, 18), 2.3, p);
    }
  }

  @override
  bool shouldRepaint(SharkArtPainter old) =>
      old.tail != tail ||
      old.fin != fin ||
      old.blink != blink ||
      old.mouth != mouth ||
      old.skinId != skinId;
}
