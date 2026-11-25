import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show isCanvasKit, kIsWeb;
import 'package:flutter/material.dart';

class SharkRig {
  SharkRig(this.image) {
    final shader = ui.ImageShader(
      image.image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Matrix4.identity().storage,
      filterQuality: FilterQuality.low,
    );
    _paint = Paint()..shader = shader;

    for (final y in _ys) {
      for (final x in _xs) {
        _points.add((
          x: x,
          y: y,
          tail: _falloff(x, y, .16, .80, .22, .36),
          fin: _falloff(x, y, .88, .43, .14, .13),
          eyelid:
              (y - .3026) * _falloff(x, y, .583, .3026, .065, .090) +
              (y - .2472) * _falloff(x, y, .774, .2472, .060, .085),
        ));
      }
    }

    _positions = Float32List(_points.length * 2);
    _texture = Float32List(_points.length * 2);
    for (var i = 0; i < _points.length; i++) {
      _texture[i * 2] = _points[i].x * image.image.width;
      _texture[i * 2 + 1] = _points[i].y * image.image.height;
    }
  }

  final ImageInfo image;
  late final Paint _paint;
  late final Float32List _positions;
  late final Float32List _texture;
  final _points =
      <({double x, double y, double tail, double fin, double eyelid})>[];

  static final _xs = _axis([702, 731, 760, 945, 970, 996]);
  static final _ys = _axis([269, 310, 334, 351, 380, 425]);
  static final _triangles = Uint16List.fromList([
    for (var row = 0; row < _ys.length - 1; row++)
      for (var column = 0; column < _xs.length - 1; column++) ...[
        row * _xs.length + column,
        row * _xs.length + column + 1,
        (row + 1) * _xs.length + column,
        row * _xs.length + column + 1,
        (row + 1) * _xs.length + column + 1,
        (row + 1) * _xs.length + column,
      ],
  ]);

  // Extra mesh points follow the eyes on the original 1254 px mascot.
  static List<double> _axis(List<int> eyePoints) => [
    for (var i = 0; i <= 24; i++) i / 24,
    for (final point in eyePoints) point / 1254,
  ]..sort();

  static double _falloff(
    double x,
    double y,
    double centerX,
    double centerY,
    double width,
    double height,
  ) {
    final dx = (x - centerX) / width;
    final dy = (y - centerY) / height;
    return math.exp(-(dx * dx + dy * dy));
  }

  void paint(
    Canvas canvas,
    Size size, {
    required double tail,
    required double fin,
    required double blink,
  }) {
    for (var i = 0; i < _points.length; i++) {
      final point = _points[i];
      _positions[2 * i] = (point.x + tail * .014 * point.tail) * size.width;
      _positions[2 * i + 1] =
          (point.y +
              tail * .05 * point.tail +
              fin * .055 * point.fin -
              blink * point.eyelid) *
          size.height;
    }

    final mesh = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      textureCoordinates: _texture,
      indices: _triangles,
    );
    canvas.drawVertices(mesh, BlendMode.src, _paint);
    mesh.dispose();
  }

  void dispose() {
    _paint.shader!.dispose();
    // CanvasKit's image shader disposes the image handle it was given.
    if (!kIsWeb || !isCanvasKit) image.dispose();
  }
}
