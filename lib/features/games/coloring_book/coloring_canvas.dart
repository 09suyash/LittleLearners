import 'package:flutter/material.dart';
import 'coloring_models.dart';

class ColoringPainter extends CustomPainter {
  final List<ColoringRegion> regions;
  final List<ColoringStrokeData> strokes;
  final ColoringStrokeData? currentStroke;
  final Offset? cursorPos;
  final Color cursorColor;
  final double cursorSize;
  final ColoringTool tool;

  ColoringPainter(
    this.regions,
    this.strokes,
    this.currentStroke, {
    this.cursorPos,
    this.cursorColor = Colors.white,
    this.cursorSize = 10,
    this.tool = ColoringTool.brush,
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
      if (tool == ColoringTool.brush) {
        _drawBrushCursor(canvas);
      } else if (tool == ColoringTool.eraser) {
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
      Rect.fromCenter(
        center: pos + const Offset(1.5, 2),
        width: s + 4,
        height: s * 0.7 + 4,
      ),
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

  void _drawStroke(Canvas canvas, ColoringStrokeData stroke) {
    if (stroke.points.isEmpty) return;

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
  bool shouldRepaint(ColoringPainter old) => true;
}
