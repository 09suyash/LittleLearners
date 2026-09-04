import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

// ── Tool mode ──────────────────────────────────────────────────────────
enum _Tool { brush, fill, eraser }

// ── Palette (29 colors – organized by hue family) ─────────────────────
const List<Color> _palette = [
  // Reds & Pinks
  Color(0xFFFF1744),
  Color(0xFFFF6B6B),
  Color(0xFFE91E63),
  Color(0xFFFF80AB),
  Color(0xFFFF4081),
  // Oranges
  Color(0xFFFF6D00), Color(0xFFFF922B), Color(0xFFFFAB40),
  // Yellows
  Color(0xFFFFD93D), Color(0xFFFFEB3B), Color(0xFFFFF176),
  // Greens
  Color(0xFFA9E34B),
  Color(0xFF6BCB77),
  Color(0xFF00C853),
  Color(0xFF20C997),
  Color(0xFF2E7D32),
  // Blues
  Color(0xFF74C0FC), Color(0xFF4D96FF), Color(0xFF2979FF), Color(0xFF1565C0),
  // Purples
  Color(0xFFCE93D8), Color(0xFF845EF7), Color(0xFF6A1B9A),
  // Earth tones
  Color(0xFFD7CCC8), Color(0xFFA0522D), Color(0xFF5D4037),
  // Neutrals
  Color(0xFF9E9E9E), Color(0xFF212121),
  // White / erase fill
  Colors.white,
];

// ── Brush sizes ───────────────────────────────────────────────────────
const List<double> _brushSizes = [4.0, 9.0, 16.0, 26.0];

// ── Card gradients for scene picker ───────────────────────────────────
const List<List<Color>> _cardGrads = [
  [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
  [Color(0xFFFFC3A0), Color(0xFFFFAFBD)],
  [Color(0xFFFFD93D), Color(0xFFFFB347)],
  [Color(0xFFA8E6CF), Color(0xFF6BCB77)],
  [Color(0xFF74C0FC), Color(0xFF4D96FF)],
  [Color(0xFFDDA0DD), Color(0xFF845EF7)],
  [Color(0xFFFF80AB), Color(0xFFFF4081)],
  [Color(0xFF20C997), Color(0xFF00BFA5)],
  [Color(0xFFFFCC02), Color(0xFFFF6D00)],
  [Color(0xFF81D4FA), Color(0xFF0288D1)],
];

// ── Stroke data (with optional region clip path) ──────────────────────
class _StrokeData {
  final List<Offset> points;
  final Color color;
  final double width;
  final Path? clipPath; // Region path to clip brush strokes within

  _StrokeData({required this.color, required this.width, this.clipPath})
    : points = [];
}

// ── Region ─────────────────────────────────────────────────────────────
class _Reg {
  final String id;
  Color fill;
  Path path = Path();

  _Reg(this.id) : fill = Colors.white;
  bool get colored => fill.toARGB32() != Colors.white.toARGB32();
  void reset() => fill = Colors.white;
}

// ── Scene ──────────────────────────────────────────────────────────────
class _Scene {
  final String name;
  final String emoji;
  final List<_Reg> regions;
  bool completed = false;
  final List<_StrokeData> strokes = [];

  _Scene(this.name, this.emoji, this.regions);

  bool get allColored => regions.every((r) => r.colored);
  void reset() {
    for (final r in regions) {
      r.reset();
    }
    strokes.clear();
    completed = false;
  }

  _Reg? hit(Offset pt) {
    for (int i = regions.length - 1; i >= 0; i--) {
      if (regions[i].path.contains(pt)) return regions[i];
    }
    return null;
  }
}

// ── Painter (with cursor + region clipping) ───────────────────────────
class _Painter extends CustomPainter {
  final List<_Reg> regions;
  final List<_StrokeData> strokes;
  final _StrokeData? currentStroke;
  final Offset? cursorPos;
  final Color cursorColor;
  final double cursorSize;
  final _Tool tool;

  _Painter(
    this.regions,
    this.strokes,
    this.currentStroke, {
    this.cursorPos,
    this.cursorColor = Colors.white,
    this.cursorSize = 10,
    this.tool = _Tool.brush,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Region fills
    final fp = Paint()..style = PaintingStyle.fill;
    for (final r in regions) {
      fp.color = r.fill;
      canvas.drawPath(r.path, fp);
    }

    // Brush strokes (clipped to their region)
    for (final s in strokes) {
      _drawStroke(canvas, s);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    // Region outlines (always on top — thick for chunky feel)
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xFF1a1a1a)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final r in regions) {
      canvas.drawPath(r.path, lp);
    }

    // Tool cursor
    if (cursorPos != null) {
      if (tool == _Tool.brush) {
        _drawBrushCursor(canvas);
      } else if (tool == _Tool.eraser) {
        _drawEraserCursor(canvas);
      }
    }
  }

  /// Draws a paintbrush-shaped cursor at [cursorPos].
  void _drawBrushCursor(Canvas canvas) {
    final pos = cursorPos!;
    final r = cursorSize / 2;

    // ── Shadow beneath brush tip ──
    canvas.drawCircle(
      pos + const Offset(1.5, 2),
      r + 2,
      Paint()
        ..color = Colors.black.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Brush tip (colored bristle area) ──
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = cursorColor.withAlpha(200)
        ..style = PaintingStyle.fill,
    );

    // ── Brush tip outline ──
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Ferrule (metallic band) ──
    final ferruleStart = Offset(pos.dx + r * 0.4, pos.dy - r - 1);
    final ferruleEnd = Offset(pos.dx + r * 0.9, pos.dy - r - 9);
    canvas.drawLine(
      ferruleStart,
      ferruleEnd,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..strokeWidth = r * 0.7
        ..strokeCap = StrokeCap.round,
    );
    // Ferrule shine
    canvas.drawLine(
      Offset(ferruleStart.dx - 1, ferruleStart.dy + 1),
      Offset(ferruleEnd.dx - 1, ferruleEnd.dy + 1),
      Paint()
        ..color = Colors.white.withAlpha(120)
        ..strokeWidth = r * 0.2
        ..strokeCap = StrokeCap.round,
    );

    // ── Wooden handle ──
    final handleStart = ferruleEnd;
    final handleEnd = Offset(
      pos.dx + r * 1.6,
      pos.dy - r - 28,
    );
    // Handle body
    canvas.drawLine(
      handleStart,
      handleEnd,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = r * 0.55
        ..strokeCap = StrokeCap.round,
    );
    // Handle highlight
    canvas.drawLine(
      Offset(handleStart.dx - 1, handleStart.dy),
      Offset(handleEnd.dx - 1, handleEnd.dy),
      Paint()
        ..color = const Color(0xFFBCAAA4).withAlpha(160)
        ..strokeWidth = r * 0.18
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Draws a rectangular eraser cursor at [cursorPos].
  void _drawEraserCursor(Canvas canvas) {
    final pos = cursorPos!;
    final s = cursorSize;

    // Shadow
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos + const Offset(1.5, 2), width: s + 4, height: s * 0.7 + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      shadowRect,
      Paint()
        ..color = Colors.black.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Eraser body (pink)
    final eraserRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: s + 2, height: s * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      eraserRect,
      Paint()..color = const Color(0xFFFFB4C2),
    );
    // Eraser outline
    canvas.drawRRect(
      eraserRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Eraser label band
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - s * 0.12),
        width: s * 0.6,
        height: s * 0.18,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      bandRect,
      Paint()..color = const Color(0xFF1565C0).withAlpha(100),
    );
  }

  void _drawStroke(Canvas canvas, _StrokeData stroke) {
    if (stroke.points.isEmpty) return;

    // Clip to region if available
    final hasClip = stroke.clipPath != null;
    if (hasClip) {
      canvas.save();
      canvas.clipPath(stroke.clipPath!);
    }

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.width / 2,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      );
    } else {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

      for (int i = 1; i < stroke.points.length - 1; i++) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;
        path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }

    if (hasClip) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Painter p) => true;
}

// ── Star path helper ──────────────────────────────────────────────────
Path _starPath(double cx, double cy, double outerR, double innerR, int pts) {
  final path = Path();
  final count = pts * 2;
  for (int i = 0; i < count; i++) {
    final r = i.isEven ? outerR : innerR;
    final a = (i * pi / pts) - pi / 2;
    final pt = Offset(cx + cos(a) * r, cy + sin(a) * r);
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  return path;
}

// ── Scene factories (10 chunky, kid-friendly designs) ─────────────────
List<_Scene> _makeScenes() => [
  _Scene('Sun & Sky', '☀️', [
    _Reg('sky'),
    _Reg('hill'),
    _Reg('sun'),
    _Reg('cloud1'),
    _Reg('cloud2'),
    _Reg('ground'),
  ]),
  _Scene('Happy Cat', '🐱', [
    _Reg('bg'),
    _Reg('body'),
    _Reg('head'),
    _Reg('ears'),
    _Reg('eyes'),
    _Reg('nose'),
    _Reg('tail'),
  ]),
  _Scene('Cozy House', '🏠', [
    _Reg('sky'),
    _Reg('ground'),
    _Reg('wall'),
    _Reg('roof'),
    _Reg('door'),
    _Reg('windows'),
    _Reg('chimney'),
  ]),
  _Scene('Big Flower', '🌸', [
    _Reg('sky'),
    _Reg('ground'),
    _Reg('stem'),
    _Reg('leaves'),
    _Reg('petals'),
    _Reg('center'),
    _Reg('sun'),
  ]),
  _Scene('Happy Fish', '🐟', [
    _Reg('water'),
    _Reg('body'),
    _Reg('tail'),
    _Reg('fin'),
    _Reg('eye'),
    _Reg('stripes'),
    _Reg('bubbles'),
  ]),
  _Scene('Butterfly', '🦋', [
    _Reg('sky'),
    _Reg('body'),
    _Reg('lwing_t'),
    _Reg('lwing_b'),
    _Reg('rwing_t'),
    _Reg('rwing_b'),
    _Reg('head'),
  ]),
  _Scene('Rainbow', '🌈', [
    _Reg('sky'),
    _Reg('ground'),
    _Reg('outer'),
    _Reg('mid'),
    _Reg('inner'),
    _Reg('sun'),
    _Reg('cloud'),
  ]),
  _Scene('Rocket', '🚀', [
    _Reg('sky'),
    _Reg('body'),
    _Reg('nose'),
    _Reg('lfin'),
    _Reg('rfin'),
    _Reg('window'),
    _Reg('flame'),
  ]),
  _Scene('Big Tree', '🌳', [
    _Reg('sky'),
    _Reg('ground'),
    _Reg('trunk'),
    _Reg('canopy'),
    _Reg('fruits'),
    _Reg('apples'),
    _Reg('sun'),
  ]),
  _Scene('Starry Night', '🌙', [
    _Reg('sky'),
    _Reg('hills'),
    _Reg('moon'),
    _Reg('star1'),
    _Reg('star2'),
    _Reg('star3'),
    _Reg('ground'),
  ]),
];

// ── Path building (chunky, rounded, kid-friendly) ─────────────────────
void _buildPaths(int idx, List<_Reg> regs, Size s) {
  final w = s.width, h = s.height;
  _Reg r(String id) => regs.firstWhere((x) => x.id == id);

  switch (idx) {
    case 0: // Sun & Sky ☀️
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .62));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .82, w, h * .18));
      // Rolling green hill
      final hill = Path()
        ..moveTo(0, h * .82)
        ..quadraticBezierTo(w * .25, h * .58, w * .5, h * .65)
        ..quadraticBezierTo(w * .75, h * .72, w, h * .62)
        ..lineTo(w, h * .82)
        ..close();
      r('hill').path = hill;
      // Big chunky sun
      r('sun').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .3),
            width: w * .44,
            height: w * .44,
          ),
        );
      // Two fluffy clouds
      final c1 = Path();
      c1.addOval(
        Rect.fromCenter(
          center: Offset(w * .18, h * .14),
          width: w * .2,
          height: w * .14,
        ),
      );
      c1.addOval(
        Rect.fromCenter(
          center: Offset(w * .10, h * .16),
          width: w * .14,
          height: w * .1,
        ),
      );
      c1.addOval(
        Rect.fromCenter(
          center: Offset(w * .26, h * .16),
          width: w * .14,
          height: w * .1,
        ),
      );
      r('cloud1').path = c1;
      final c2 = Path();
      c2.addOval(
        Rect.fromCenter(
          center: Offset(w * .8, h * .08),
          width: w * .18,
          height: w * .12,
        ),
      );
      c2.addOval(
        Rect.fromCenter(
          center: Offset(w * .73, h * .1),
          width: w * .12,
          height: w * .08,
        ),
      );
      c2.addOval(
        Rect.fromCenter(
          center: Offset(w * .87, h * .1),
          width: w * .12,
          height: w * .08,
        ),
      );
      r('cloud2').path = c2;
      break;

    case 1: // Happy Cat 🐱
      r('bg').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
      // Round body
      r('body').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .78),
            width: w * .6,
            height: h * .36,
          ),
        );
      // Big chunky head
      r('head').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .44),
            width: w * .72,
            height: h * .52,
          ),
        );
      // Chunky triangle ears
      final ears = Path();
      ears.moveTo(w * .15, h * .32);
      ears.lineTo(w * .26, h * .06);
      ears.lineTo(w * .40, h * .25);
      ears.close();
      ears.moveTo(w * .85, h * .32);
      ears.lineTo(w * .74, h * .06);
      ears.lineTo(w * .60, h * .25);
      ears.close();
      r('ears').path = ears;
      // Big round eyes
      final eyes = Path();
      eyes.addOval(
        Rect.fromCenter(
          center: Offset(w * .34, h * .38),
          width: w * .18,
          height: w * .18,
        ),
      );
      eyes.addOval(
        Rect.fromCenter(
          center: Offset(w * .66, h * .38),
          width: w * .18,
          height: w * .18,
        ),
      );
      r('eyes').path = eyes;
      // Chunky nose
      r('nose').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .52),
            width: w * .14,
            height: w * .1,
          ),
        );
      // Curvy tail
      final tail = Path()
        ..moveTo(w * .78, h * .72)
        ..quadraticBezierTo(w * .95, h * .5, w * .88, h * .38)
        ..quadraticBezierTo(w * .82, h * .3, w * .78, h * .38)
        ..quadraticBezierTo(w * .85, h * .5, w * .72, h * .72)
        ..close();
      r('tail').path = tail;
      break;

    case 2: // Cozy House 🏠
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .45));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .45, w, h * .55));
      // Big chunky wall
      r('wall').path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .12, h * .45, w * .76, h * .32),
            const Radius.circular(4),
          ),
        );
      // Tall chunky roof
      final roof = Path()
        ..moveTo(w * .05, h * .47)
        ..lineTo(w * .5, h * .1)
        ..lineTo(w * .95, h * .47)
        ..close();
      r('roof').path = roof;
      // Big rounded door
      r('door').path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .38, h * .58, w * .24, h * .19),
            const Radius.circular(12),
          ),
        );
      // Two square windows
      final win = Path();
      win.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .16, h * .52, w * .16, h * .13),
          const Radius.circular(4),
        ),
      );
      win.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .68, h * .52, w * .16, h * .13),
          const Radius.circular(4),
        ),
      );
      r('windows').path = win;
      // Chimney
      r('chimney').path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .7, h * .14, w * .1, h * .2),
            const Radius.circular(3),
          ),
        );
      break;

    case 3: // Big Flower 🌸
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .62));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .62, w, h * .38));
      // Thick chunky stem
      r('stem').path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .44, h * .38, w * .12, h * .28),
            const Radius.circular(6),
          ),
        );
      // Leaves
      final leaves = Path();
      leaves.addOval(
        Rect.fromCenter(
          center: Offset(w * .34, h * .52),
          width: w * .2,
          height: w * .1,
        ),
      );
      leaves.addOval(
        Rect.fromCenter(
          center: Offset(w * .66, h * .48),
          width: w * .2,
          height: w * .1,
        ),
      );
      r('leaves').path = leaves;
      // Big fat petals
      final petals = Path();
      for (int i = 0; i < 6; i++) {
        final a = i * pi / 3;
        petals.addOval(
          Rect.fromCenter(
            center: Offset(
              w * .5 + cos(a) * w * .18,
              h * .24 + sin(a) * h * .14,
            ),
            width: w * .22,
            height: h * .18,
          ),
        );
      }
      r('petals').path = petals;
      // Big round center
      r('center').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .24),
            width: w * .22,
            height: w * .22,
          ),
        );
      // Little sun
      r('sun').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .85, h * .08),
            width: w * .14,
            height: w * .14,
          ),
        );
      break;

    case 4: // Happy Fish 🐟
      r('water').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
      // Fat round body
      r('body').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .42, h * .5),
            width: w * .6,
            height: h * .46,
          ),
        );
      // Big chunky tail
      final tail = Path()
        ..moveTo(w * .72, h * .32)
        ..quadraticBezierTo(w * .95, h * .15, w * .92, h * .5)
        ..quadraticBezierTo(w * .95, h * .85, w * .72, h * .68)
        ..close();
      r('tail').path = tail;
      // Top fin
      final fin = Path()
        ..moveTo(w * .32, h * .28)
        ..quadraticBezierTo(w * .42, h * .08, w * .56, h * .28)
        ..close();
      r('fin').path = fin;
      // Big round eye
      r('eye').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .24, h * .42),
            width: w * .12,
            height: w * .12,
          ),
        );
      // Stripes on body
      final stripes = Path();
      stripes.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .38, h * .34, w * .05, h * .32),
          const Radius.circular(3),
        ),
      );
      stripes.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .48, h * .32, w * .05, h * .36),
          const Radius.circular(3),
        ),
      );
      stripes.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .58, h * .36, w * .05, h * .28),
          const Radius.circular(3),
        ),
      );
      r('stripes').path = stripes;
      // Bubbles
      final bub = Path();
      bub.addOval(
        Rect.fromCenter(
          center: Offset(w * .12, h * .18),
          width: w * .08,
          height: w * .08,
        ),
      );
      bub.addOval(
        Rect.fromCenter(
          center: Offset(w * .08, h * .28),
          width: w * .06,
          height: w * .06,
        ),
      );
      bub.addOval(
        Rect.fromCenter(
          center: Offset(w * .16, h * .12),
          width: w * .05,
          height: w * .05,
        ),
      );
      r('bubbles').path = bub;
      break;

    case 5: // Butterfly 🦋
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
      // Chunky body
      r('body').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .52),
            width: w * .1,
            height: h * .4,
          ),
        );
      // Left upper wing
      r('lwing_t').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .26, h * .36),
            width: w * .36,
            height: h * .32,
          ),
        );
      // Left lower wing
      r('lwing_b').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .28, h * .64),
            width: w * .28,
            height: h * .22,
          ),
        );
      // Right upper wing
      r('rwing_t').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .74, h * .36),
            width: w * .36,
            height: h * .32,
          ),
        );
      // Right lower wing
      r('rwing_b').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .72, h * .64),
            width: w * .28,
            height: h * .22,
          ),
        );
      // Round head
      r('head').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .22),
            width: w * .16,
            height: w * .16,
          ),
        );
      break;

    case 6: // Rainbow 🌈
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .62));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .62, w, h * .38));
      final cx6 = w * .5, cy6 = h * .62;
      // Outer arc band
      final outer = Path()
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx6, cy6),
            width: w * .92,
            height: h * .82,
          ),
          pi,
          pi,
          false,
        )
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx6, cy6),
            width: w * .68,
            height: h * .58,
          ),
          0,
          -pi,
          false,
        )
        ..close();
      r('outer').path = outer;
      // Middle arc band
      final mid = Path()
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx6, cy6),
            width: w * .66,
            height: h * .56,
          ),
          pi,
          pi,
          false,
        )
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx6, cy6),
            width: w * .46,
            height: h * .36,
          ),
          0,
          -pi,
          false,
        )
        ..close();
      r('mid').path = mid;
      // Inner arc band
      final inner = Path()
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx6, cy6),
            width: w * .44,
            height: h * .34,
          ),
          pi,
          pi,
          false,
        )
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx6, cy6),
            width: w * .28,
            height: h * .18,
          ),
          0,
          -pi,
          false,
        )
        ..close();
      r('inner').path = inner;
      // Sun
      r('sun').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .86, h * .1),
            width: w * .18,
            height: w * .18,
          ),
        );
      // Cloud
      final cld6 = Path();
      cld6.addOval(
        Rect.fromCenter(
          center: Offset(w * .14, h * .1),
          width: w * .2,
          height: w * .14,
        ),
      );
      cld6.addOval(
        Rect.fromCenter(
          center: Offset(w * .07, h * .12),
          width: w * .14,
          height: w * .1,
        ),
      );
      cld6.addOval(
        Rect.fromCenter(
          center: Offset(w * .22, h * .12),
          width: w * .14,
          height: w * .1,
        ),
      );
      r('cloud').path = cld6;
      break;

    case 7: // Rocket 🚀
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
      // Chunky body
      r('body').path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .3, h * .2, w * .4, h * .52),
            const Radius.circular(12),
          ),
        );
      // Nose cone
      final nose = Path()
        ..moveTo(w * .3, h * .22)
        ..quadraticBezierTo(w * .5, h * .02, w * .7, h * .22)
        ..close();
      r('nose').path = nose;
      // Left fin
      final lfin = Path()
        ..moveTo(w * .3, h * .58)
        ..quadraticBezierTo(w * .1, h * .82, w * .22, h * .82)
        ..lineTo(w * .3, h * .72)
        ..close();
      r('lfin').path = lfin;
      // Right fin
      final rfin = Path()
        ..moveTo(w * .7, h * .58)
        ..quadraticBezierTo(w * .9, h * .82, w * .78, h * .82)
        ..lineTo(w * .7, h * .72)
        ..close();
      r('rfin').path = rfin;
      // Round window
      r('window').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .5, h * .38),
            width: w * .22,
            height: w * .22,
          ),
        );
      // Flame
      final flame = Path()
        ..moveTo(w * .34, h * .72)
        ..quadraticBezierTo(w * .38, h * .88, w * .5, h * .95)
        ..quadraticBezierTo(w * .62, h * .88, w * .66, h * .72)
        ..close();
      r('flame').path = flame;
      break;

    case 8: // Big Tree 🌳
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .58));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .58, w, h * .42));
      // Thick trunk
      r('trunk').path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .38, h * .42, w * .24, h * .24),
            const Radius.circular(6),
          ),
        );
      // Big bushy canopy (overlapping ovals)
      final canopy = Path();
      canopy.addOval(
        Rect.fromCenter(
          center: Offset(w * .5, h * .26),
          width: w * .52,
          height: h * .32,
        ),
      );
      canopy.addOval(
        Rect.fromCenter(
          center: Offset(w * .32, h * .3),
          width: w * .32,
          height: h * .24,
        ),
      );
      canopy.addOval(
        Rect.fromCenter(
          center: Offset(w * .68, h * .3),
          width: w * .32,
          height: h * .24,
        ),
      );
      r('canopy').path = canopy;
      // Fruits (oranges)
      final fruits = Path();
      fruits.addOval(
        Rect.fromCenter(
          center: Offset(w * .38, h * .2),
          width: w * .09,
          height: w * .09,
        ),
      );
      fruits.addOval(
        Rect.fromCenter(
          center: Offset(w * .62, h * .22),
          width: w * .09,
          height: w * .09,
        ),
      );
      fruits.addOval(
        Rect.fromCenter(
          center: Offset(w * .5, h * .32),
          width: w * .09,
          height: w * .09,
        ),
      );
      r('fruits').path = fruits;
      // Apples
      final apples = Path();
      apples.addOval(
        Rect.fromCenter(
          center: Offset(w * .28, h * .36),
          width: w * .08,
          height: w * .08,
        ),
      );
      apples.addOval(
        Rect.fromCenter(
          center: Offset(w * .72, h * .34),
          width: w * .08,
          height: w * .08,
        ),
      );
      r('apples').path = apples;
      // Little sun
      r('sun').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .88, h * .08),
            width: w * .14,
            height: w * .14,
          ),
        );
      break;

    case 9: // Starry Night 🌙
      r('sky').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .68));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .82, w, h * .18));
      // Rolling hills
      final hills = Path()
        ..moveTo(0, h * .82)
        ..quadraticBezierTo(w * .2, h * .62, w * .4, h * .7)
        ..quadraticBezierTo(w * .6, h * .78, w * .8, h * .66)
        ..quadraticBezierTo(w * .9, h * .6, w, h * .68)
        ..lineTo(w, h * .82)
        ..close();
      r('hills').path = hills;
      // Big round moon
      r('moon').path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * .78, h * .16),
            width: w * .24,
            height: w * .24,
          ),
        );
      // Three chunky 5-pointed stars
      r('star1').path = _starPath(w * .2, h * .14, w * .1, w * .045, 5);
      r('star2').path = _starPath(w * .48, h * .08, w * .08, w * .035, 5);
      r('star3').path = _starPath(w * .35, h * .32, w * .07, w * .03, 5);
      break;
  }
}

// ── Screen ─────────────────────────────────────────────────────────────
class ColoringBookScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ColoringBookScreen({super.key, required this.onBack});

  @override
  State<ColoringBookScreen> createState() => _ColoringBookScreenState();
}

class _ColoringBookScreenState extends State<ColoringBookScreen> {
  final _bs = BadgeService();
  final _sfx = SoundService();
  late final List<_Scene> _scenes;
  int _sceneIdx = 0;
  Color _pick = const Color(0xFFFF6B6B);
  bool _showConfetti = false;
  Size? _lastSize;
  String _filter = 'all';

  // ── Painting state ──
  _Tool _tool = _Tool.brush;
  int _brushSizeIdx = 1;
  _StrokeData? _currentStroke;
  Offset? _cursorPos;

  // ── Scene picker ──
  bool _showPicker = false;

  @override
  void initState() {
    super.initState();
    _scenes = _makeScenes();
  }

  _Scene get _scene => _scenes[_sceneIdx];

  // ── Fill mode tap ──
  Future<void> _onFillTap(Offset pt) async {
    final reg = _scene.hit(pt);
    if (reg == null) return;
    setState(() => reg.fill = _pick);
    _sfx.play(SoundType.tap);
    await awardWithToast(context, _bs, 'color_first', stars: 10);
    if (!_scene.completed && _scene.allColored) {
      setState(() {
        _scene.completed = true;
        _showConfetti = true;
      });
      _sfx.play(SoundType.win);
      await AppState.addStars(10);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) await awardWithToast(context, _bs, 'color_scene');
      }
    }
  }

  // ── Brush / eraser pan handlers (with cursor + region clipping) ──
  void _onPanStart(DragStartDetails d) {
    final color = _tool == _Tool.eraser ? Colors.white : _pick;
    final reg = _scene.hit(d.localPosition);
    setState(() {
      _cursorPos = d.localPosition;
      _currentStroke = _StrokeData(
        color: color,
        width: _brushSizes[_brushSizeIdx],
        clipPath: reg?.path, // clip to region where stroke started
      );
      _currentStroke!.points.add(d.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_currentStroke == null) return;
    setState(() {
      _cursorPos = d.localPosition;
      _currentStroke!.points.add(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentStroke == null) return;
    setState(() {
      _scene.strokes.add(_currentStroke!);
      _currentStroke = null;
      _cursorPos = null;
    });
    _sfx.play(SoundType.tap);
  }

  void _undo() {
    if (_scene.strokes.isEmpty) return;
    setState(() => _scene.strokes.removeLast());
    _sfx.play(SoundType.tap);
  }

  void _switchScene(int i) {
    if (i == _sceneIdx) return;
    if (_currentStroke != null) {
      _scene.strokes.add(_currentStroke!);
      _currentStroke = null;
      _cursorPos = null;
    }
    setState(() {
      _sceneIdx = i;
      _showConfetti = false;
      _lastSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMain(),
        MascotCorner(celebrating: _showConfetti),
        ConfettiOverlay(trigger: _showConfetti),
        // Scene picker overlay
        if (_showPicker) _pickerOverlay(),
      ],
    );
  }

  Widget _buildMain() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF2d1b69)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/coloring_card.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -10,
            child: Opacity(
              opacity: 0.05,
              child: const Text('🌟', style: TextStyle(fontSize: 100)),
            ),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: Opacity(
              opacity: 0.06,
              child: const Text('✨', style: TextStyle(fontSize: 90)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 8),
                _currentSceneBadge(),
                const SizedBox(height: 8),
                Expanded(child: _canvas()),
                const SizedBox(height: 6),
                _toolBar(),
                const SizedBox(height: 6),
                _paletteRow(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Colors.white70, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(
            'assets/images/coloring_card.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Coloring Book',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _scene.reset();
              _currentStroke = null;
              _cursorPos = null;
              _showConfetti = false;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(36)),
              ),
              child: const Text(
                '🗑 Reset',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Current scene indicator + "Change Design" button ──
  Widget _currentSceneBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => setState(() => _showPicker = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Row(
            children: [
              Text(_scene.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                _scene.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (_scene.completed) ...[
                const SizedBox(width: 6),
                const Text('✅', style: TextStyle(fontSize: 12)),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: Color(0xFF1a0533),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Choose Design',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1a0533),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (_, cst) {
            final size = Size(cst.maxWidth, cst.maxHeight);
            if (_lastSize != size) {
              _lastSize = size;
              _buildPaths(_sceneIdx, _scene.regions, size);
            }
            final cursorColor = _tool == _Tool.eraser
                ? Colors.grey
                : _pick.toARGB32() == Colors.white.toARGB32()
                ? Colors.grey
                : _pick;
            final paint = CustomPaint(
              size: size,
              painter: _Painter(
                _scene.regions,
                _scene.strokes,
                _currentStroke,
                cursorPos: _cursorPos,
                cursorColor: cursorColor,
                cursorSize: _brushSizes[_brushSizeIdx],
                tool: _tool,
              ),
            );
            if (_tool == _Tool.fill) {
              return GestureDetector(
                onTapDown: (d) => _onFillTap(d.localPosition),
                child: paint,
              );
            }
            return Listener(
              onPointerHover: (e) {
                setState(() => _cursorPos = e.localPosition);
              },
              onPointerMove: (e) {
                // Keep cursor visible during pointer moves
                if (_currentStroke == null) {
                  setState(() => _cursorPos = e.localPosition);
                }
              },
              onPointerUp: (_) {
                // Hide cursor when pointer leaves
                setState(() => _cursorPos = null);
              },
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: paint,
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Tool toolbar ─────────────────────────────────────────────────────
  Widget _toolBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(24)),
        ),
        child: Row(
          children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolBtn(Icons.brush_rounded, 'Brush', _Tool.brush),
                    const SizedBox(width: 6),
                    _toolBtn(
                      Icons.format_color_fill_rounded,
                      'Fill',
                      _Tool.fill,
                    ),
                    const SizedBox(width: 6),
                    _toolBtn(
                      Icons.auto_fix_high_rounded,
                      'Eraser',
                      _Tool.eraser,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withAlpha(30),
                    ),
                    const SizedBox(width: 10),
                    if (_tool != _Tool.fill) ...[
                      for (int i = 0; i < _brushSizes.length; i++) ...[
                        _brushSizeDot(i),
                        if (i < _brushSizes.length - 1)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _undo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _scene.strokes.isNotEmpty
                      ? Colors.white.withAlpha(22)
                      : Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.undo_rounded,
                      size: 16,
                      color: _scene.strokes.isNotEmpty
                          ? Colors.white70
                          : Colors.white24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Undo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _scene.strokes.isNotEmpty
                            ? Colors.white70
                            : Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, _Tool tool) {
    final sel = _tool == tool;
    return GestureDetector(
      onTap: () => setState(() => _tool = tool),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFD93D) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: sel ? const Color(0xFF1a0533) : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sel ? const Color(0xFF1a0533) : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brushSizeDot(int idx) {
    final sel = _brushSizeIdx == idx;
    final dotSize = 8.0 + idx * 5.0;
    return GestureDetector(
      onTap: () => setState(() => _brushSizeIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: sel ? Colors.white.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: sel
              ? Border.all(color: const Color(0xFFFFD93D), width: 1.5)
              : null,
        ),
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _paletteRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemCount: _palette.length,
        itemBuilder: (_, i) {
          final color = _palette[i];
          final sel = color.toARGB32() == _pick.toARGB32();
          return GestureDetector(
            onTap: () => setState(() => _pick = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: sel ? 46 : 36,
              height: sel ? 46 : 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? Colors.white : Colors.white.withAlpha(80),
                  width: sel ? 3 : 1.5,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: color.withAlpha(130),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: color.toARGB32() == Colors.white.toARGB32()
                  ? const Center(
                      child: Text('🗑', style: TextStyle(fontSize: 14)),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ── Full-screen scene picker overlay ─────────────────────────────────
  Widget _pickerOverlay() {
    // Compute filtered indices for current filter
    List<int> filteredIndices() {
      switch (_filter) {
        case 'todo':
          return [
            for (int i = 0; i < _scenes.length; i++)
              if (!_scenes[i].completed) i,
          ];
        case 'done':
          return [
            for (int i = 0; i < _scenes.length; i++)
              if (_scenes[i].completed) i,
          ];
        default:
          return List.generate(_scenes.length, (i) => i);
      }
    }

    final indices = filteredIndices();

    return Container(
      color: const Color(0xFF1a0533).withAlpha(245),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Text('🎨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Choose a Design',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showPicker = false),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  for (final (key, label) in [
                    ('all', 'All'),
                    ('todo', 'To Do'),
                    ('done', 'Done ✅'),
                  ]) ...[
                    GestureDetector(
                      onTap: () => setState(() => _filter = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _filter == key
                              ? const Color(0xFFFFD93D)
                              : Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _filter == key
                                ? const Color(0xFF1a0533)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    if (key != 'done') const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid
            Expanded(
              child: indices.isEmpty
                  ? Center(
                      child: Text(
                        _filter == 'done'
                            ? 'No scenes completed yet — start coloring!'
                            : 'All scenes completed! 🎉',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                      itemCount: indices.length,
                      itemBuilder: (_, i) => _sceneCard(indices[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneCard(int sceneIdx) {
    final scene = _scenes[sceneIdx];
    final isCurrent = sceneIdx == _sceneIdx;
    final grad = _cardGrads[sceneIdx % _cardGrads.length];

    return GestureDetector(
      onTap: () {
        _switchScene(sceneIdx);
        setState(() => _showPicker = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: grad,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? Colors.white : Colors.white.withAlpha(40),
            width: isCurrent ? 3 : 1.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: grad[0].withAlpha(100),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Completed badge
            if (scene.completed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✅', style: TextStyle(fontSize: 14)),
                ),
              ),
            // Current indicator
            if (isCurrent)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1a0533),
                    ),
                  ),
                ),
              ),
            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(scene.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    scene.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1a0533),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
