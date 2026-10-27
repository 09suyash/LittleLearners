import 'package:flutter/material.dart';

// ── Tool mode ──────────────────────────────────────────────────────────
enum ColoringTool { brush, fill, eraser }

// ── Palette (29 colors – organized by hue family) ─────────────────────
const List<Color> coloringPalette = [
  // Reds & Pinks
  Color(0xFFFF1744),
  Color(0xFFFF6B6B),
  Color(0xFFE91E63),
  Color(0xFFFF80AB),
  Color(0xFFFF4081),
  // Oranges
  Color(0xFFFF6D00),
  Color(0xFFFF922B),
  Color(0xFFFFAB40),
  // Yellows
  Color(0xFFFFD93D),
  Color(0xFFFFEB3B),
  Color(0xFFFFF176),
  // Greens
  Color(0xFFA9E34B),
  Color(0xFF6BCB77),
  Color(0xFF00C853),
  Color(0xFF20C997),
  Color(0xFF2E7D32),
  // Blues
  Color(0xFF74C0FC),
  Color(0xFF4D96FF),
  Color(0xFF2979FF),
  Color(0xFF1565C0),
  // Purples
  Color(0xFFCE93D8),
  Color(0xFF845EF7),
  Color(0xFF6A1B9A),
  // Earth tones
  Color(0xFFD7CCC8),
  Color(0xFFA0522D),
  Color(0xFF5D4037),
  // Neutrals
  Color(0xFF9E9E9E),
  Color(0xFF212121),
  // White / erase fill
  Colors.white,
];

// ── Brush sizes ───────────────────────────────────────────────────────
const List<double> coloringBrushSizes = [4.0, 9.0, 16.0, 26.0];

// ── Card gradients for scene picker ───────────────────────────────────
const List<List<Color>> coloringCardGrads = [
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
class ColoringStrokeData {
  final List<Offset> points;
  final Color color;
  final double width;
  final Path? clipPath; // Region path to clip brush strokes within

  ColoringStrokeData({
    required this.color,
    required this.width,
    this.clipPath,
  }) : points = [];
}

// ── Region ─────────────────────────────────────────────────────────────
class ColoringRegion {
  final String id;
  Color fill;
  Path path = Path();

  ColoringRegion(this.id) : fill = Colors.white;
  bool get colored => fill.toARGB32() != Colors.white.toARGB32();
  void reset() => fill = Colors.white;
}

// ── Scene ──────────────────────────────────────────────────────────────
class ColoringScene {
  final String name;
  final String emoji;
  final List<ColoringRegion> regions;
  bool completed = false;
  final List<ColoringStrokeData> strokes = [];

  ColoringScene(this.name, this.emoji, this.regions);

  bool get allColored => regions.every((r) => r.colored);
  void reset() {
    for (final r in regions) {
      r.reset();
    }
    strokes.clear();
    completed = false;
  }

  ColoringRegion? hit(Offset pt) {
    for (int i = regions.length - 1; i >= 0; i--) {
      if (regions[i].path.contains(pt)) return regions[i];
    }
    return null;
  }
}
