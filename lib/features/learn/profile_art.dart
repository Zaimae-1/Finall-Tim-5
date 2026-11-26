import 'dart:math' as math;

import 'package:flutter/material.dart';

const avatarNames = ['Terumbu', 'Kompas', 'Bintang Laut', 'Ombak', 'Mutiara'];
const _colors = [
  Color(0xFFE88675),
  Color(0xFF376CAB),
  Color(0xFFEAAE48),
  Color(0xFF40B8C2),
  Color(0xFFAF85CC),
];

class ProfileArt extends StatelessWidget {
  const ProfileArt({super.key, required this.id, this.size = 68});
  final int id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final valid = id >= 0 && id < avatarNames.length;
    return Semantics(
      label: valid ? 'Avatar ${avatarNames[id]}' : 'Avatar dasar',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: valid
                ? [_colors[id].withValues(alpha: .75), _colors[id]]
                : [const Color(0xFFB7D9EB), const Color(0xFF5B93B8)],
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x290B4167),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: valid
            ? CustomPaint(painter: _AvatarPainter(id))
            : Icon(Icons.person_rounded, color: Colors.white, size: size * .52),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.id);
  final int id;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint()..isAntiAlias = true;
    switch (id) {
      case 0: // Coral reef.
        p.color = const Color(0xFFFFE4A1);
        canvas.drawOval(const Rect.fromLTWH(14, 77, 72, 13), p);
        p.color = const Color(0xFFFFF5E7);
        p.strokeWidth = 8;
        p.strokeCap = StrokeCap.round;
        for (final branch in [
          [const Offset(49, 78), const Offset(49, 24)],
          [const Offset(49, 55), const Offset(25, 33)],
          [const Offset(49, 48), const Offset(73, 28)],
          [const Offset(25, 33), const Offset(25, 20)],
          [const Offset(73, 28), const Offset(80, 18)],
        ]) {
          canvas.drawLine(branch[0], branch[1], p);
        }
        p.color = const Color(0xFFB74756);
        canvas.drawCircle(const Offset(49, 22), 5, p);
      case 1: // Nautical compass.
        p.color = const Color(0xFFFFDE8B);
        canvas.drawCircle(const Offset(50, 50), 34, p);
        p.color = const Color(0xFF1E648A);
        canvas.drawCircle(const Offset(50, 50), 27, p);
        p.color = Colors.white;
        canvas.drawPath(
          Path()
            ..moveTo(50, 20)
            ..lineTo(59, 52)
            ..lineTo(50, 80)
            ..lineTo(41, 52)
            ..close(),
          p,
        );
        p.color = const Color(0xFFFFC05B);
        canvas.drawPath(
          Path()
            ..moveTo(50, 20)
            ..lineTo(59, 52)
            ..lineTo(50, 49)
            ..lineTo(41, 52)
            ..close(),
          p,
        );
        p.color = const Color(0xFF103552);
        canvas.drawCircle(const Offset(50, 50), 4, p);
      case 2: // Starfish.
        p.color = const Color(0xFFFFE9A4);
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final radius = i.isEven ? 35 : 17;
          final point = Offset(
            50 + radius * math.cos(angle),
            50 + radius * math.sin(angle),
          );
          if (i == 0) {
            star.moveTo(point.dx, point.dy);
          } else {
            star.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(star..close(), p);
        p.color = const Color(0xFFB36A41);
        for (final dot in [
          const Offset(42, 45),
          const Offset(58, 45),
          const Offset(50, 58),
        ]) {
          canvas.drawCircle(dot, 2.4, p);
        }
      case 3: // Breaking wave.
        p.color = const Color(0xFFE8FDFF);
        canvas.drawPath(
          Path()
            ..moveTo(7, 69)
            ..quadraticBezierTo(34, 57, 47, 32)
            ..quadraticBezierTo(49, 59, 74, 55)
            ..quadraticBezierTo(86, 55, 94, 68)
            ..lineTo(94, 90)
            ..lineTo(7, 90)
            ..close(),
          p,
        );
        p.color = const Color(0xFF117FA7);
        canvas.drawPath(
          Path()
            ..moveTo(7, 70)
            ..quadraticBezierTo(28, 62, 45, 46)
            ..quadraticBezierTo(48, 68, 73, 64)
            ..quadraticBezierTo(84, 64, 94, 73)
            ..lineTo(94, 90)
            ..lineTo(7, 90)
            ..close(),
          p,
        );
        p.color = Colors.white;
        canvas.drawCircle(const Offset(64, 35), 4, p);
      case 4: // Pearl and shell.
        p.color = const Color(0xFF674D9D);
        canvas.drawPath(
          Path()
            ..moveTo(16, 61)
            ..quadraticBezierTo(50, 11, 84, 61)
            ..quadraticBezierTo(50, 75, 16, 61)
            ..close(),
          p,
        );
        p.color = const Color(0xFFEEDCF8);
        canvas.drawPath(
          Path()
            ..moveTo(15, 64)
            ..quadraticBezierTo(50, 89, 85, 64)
            ..quadraticBezierTo(73, 91, 50, 91)
            ..quadraticBezierTo(27, 91, 15, 64)
            ..close(),
          p,
        );
        p.color = Colors.white;
        canvas.drawCircle(const Offset(50, 57), 17, p);
        p.color = const Color(0x99FFFFFF);
        canvas.drawCircle(const Offset(44, 51), 5, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.id != id;
}
