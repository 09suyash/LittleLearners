import 'dart:math';
import 'dart:ui';

// Fluent path builder — coordinates in 0-100 space, scaled to [w]×[h].
class _PB {
  final Path _p = Path();
  final double w, h;
  _PB(this.w, this.h);
  double _x(double v) => v / 100 * w;
  double _y(double v) => v / 100 * h;
  _PB m(double x, double y) { _p.moveTo(_x(x), _y(y)); return this; }
  _PB l(double x, double y) { _p.lineTo(_x(x), _y(y)); return this; }
  _PB q(double cx, double cy, double ex, double ey) {
    _p.quadraticBezierTo(_x(cx), _y(cy), _x(ex), _y(ey)); return this;
  }
  _PB c(double c1x, double c1y, double c2x, double c2y, double ex, double ey) {
    _p.cubicTo(_x(c1x), _y(c1y), _x(c2x), _y(c2y), _x(ex), _y(ey)); return this;
  }
  Path build() => _p;
}

/// Returns the ordered guide stroke [Path]s for [letter] (uppercase or lowercase), scaled to [sz].
/// Each Path is one continuous stroke the child should trace in order.
List<Path> letterGuide(String letter, Size sz) {
  if (letter.isEmpty) return [];
  final w = sz.width, h = sz.height;
  _PB b() => _PB(w, h);

  // Lowercase letters
  if (letter == letter.toLowerCase() && letter != letter.toUpperCase()) {
    switch (letter) {
      case 'a': return [
        b().m(68, 48).c(65, 36, 28, 36, 28, 58).c(28, 80, 65, 80, 68, 68).build(),
        b().m(68, 38).l(68, 80).build(),
      ];
      case 'b': return [
        b().m(26, 12).l(26, 80).build(),
        b().m(26, 48).c(48, 36, 76, 40, 76, 58).c(76, 78, 48, 80, 26, 80).build(),
      ];
      case 'c': return [
        b().m(72, 46).c(68, 36, 28, 36, 28, 58).c(28, 80, 68, 80, 72, 70).build(),
      ];
      case 'd': return [
        b().m(72, 48).c(68, 36, 26, 36, 26, 58).c(26, 80, 68, 80, 72, 68).build(),
        b().m(72, 12).l(72, 80).build(),
      ];
      case 'e': return [
        b().m(26, 58).l(74, 58).c(74, 36, 26, 36, 26, 58).c(26, 80, 70, 80, 74, 72).build(),
      ];
      case 'f': return [
        b().m(68, 18).c(64, 10, 46, 10, 46, 26).l(46, 82).build(),
        b().m(28, 46).l(66, 46).build(),
      ];
      case 'g': return [
        b().m(70, 48).c(66, 36, 28, 36, 28, 58).c(28, 76, 66, 76, 70, 68).build(),
        b().m(70, 38).l(70, 78).c(70, 94, 34, 94, 28, 82).build(),
      ];
      case 'h': return [
        b().m(26, 12).l(26, 80).build(),
        b().m(26, 50).c(34, 36, 74, 36, 74, 54).l(74, 80).build(),
      ];
      case 'i': return [
        b().m(50, 42).l(50, 80).build(),
        b().m(50, 22).l(50, 25).build(),
      ];
      case 'j': return [
        b().m(58, 42).l(58, 80).c(58, 94, 28, 94, 24, 82).build(),
        b().m(58, 22).l(58, 25).build(),
      ];
      case 'k': return [
        b().m(28, 12).l(28, 80).build(),
        b().m(68, 42).l(28, 62).build(),
        b().m(36, 58).l(70, 80).build(),
      ];
      case 'l': return [
        b().m(50, 12).l(50, 80).build(),
      ];
      case 'm': return [
        b().m(20, 42).l(20, 80).build(),
        b().m(20, 52).c(26, 36, 50, 36, 50, 54).l(50, 80).build(),
        b().m(50, 52).c(56, 36, 80, 36, 80, 54).l(80, 80).build(),
      ];
      case 'n': return [
        b().m(26, 42).l(26, 80).build(),
        b().m(26, 52).c(34, 36, 74, 36, 74, 54).l(74, 80).build(),
      ];
      case 'o': return [
        b().m(50, 38).c(24, 38, 24, 80, 50, 80).c(76, 80, 76, 38, 50, 38).build(),
      ];
      case 'p': return [
        b().m(26, 42).l(26, 94).build(),
        b().m(26, 48).c(48, 36, 76, 40, 76, 58).c(76, 78, 48, 80, 26, 80).build(),
      ];
      case 'q': return [
        b().m(72, 48).c(68, 36, 26, 36, 26, 58).c(26, 80, 68, 80, 72, 68).build(),
        b().m(72, 42).l(72, 94).l(82, 86).build(),
      ];
      case 'r': return [
        b().m(30, 42).l(30, 80).build(),
        b().m(30, 52).c(36, 38, 62, 38, 70, 46).build(),
      ];
      case 's': return [
        b().m(68, 46).c(64, 36, 30, 36, 30, 48).c(30, 60, 70, 58, 70, 70).c(70, 80, 30, 80, 28, 70).build(),
      ];
      case 't': return [
        b().m(48, 16).l(48, 72).c(48, 80, 62, 80, 68, 74).build(),
        b().m(30, 38).l(66, 38).build(),
      ];
      case 'u': return [
        b().m(28, 42).l(28, 70).c(28, 80, 72, 80, 72, 70).l(72, 42).build(),
        b().m(72, 42).l(72, 80).build(),
      ];
      case 'v': return [
        b().m(24, 42).l(50, 80).build(),
        b().m(50, 80).l(76, 42).build(),
      ];
      case 'w': return [
        b().m(16, 42).l(32, 80).build(),
        b().m(32, 80).l(50, 54).build(),
        b().m(50, 54).l(68, 80).build(),
        b().m(68, 80).l(84, 42).build(),
      ];
      case 'x': return [
        b().m(24, 42).l(76, 80).build(),
        b().m(76, 42).l(24, 80).build(),
      ];
      case 'y': return [
        b().m(24, 42).l(50, 70).build(),
        b().m(76, 42).l(26, 94).build(),
      ];
      case 'z': return [
        b().m(25, 42).l(75, 42).build(),
        b().m(75, 42).l(25, 80).build(),
        b().m(25, 80).l(75, 80).build(),
      ];
      default: return [];
    }
  }

  // Uppercase letters
  switch (letter.toUpperCase()) {
    case 'A': return [
      b().m(50, 8).l(10, 92).build(),
      b().m(50, 8).l(90, 92).build(),
      b().m(28, 56).l(72, 56).build(),
    ];
    case 'B': return [
      b().m(22, 8).l(22, 92).build(),
      b().m(22, 8).l(56, 8).q(78, 8, 78, 30).q(78, 50, 56, 50).l(22, 50).build(),
      b().m(22, 50).l(60, 50).q(82, 50, 82, 72).q(82, 92, 60, 92).l(22, 92).build(),
    ];
    case 'C': return [
      b().m(78, 22).c(78, 5, 8, 5, 8, 50).c(8, 95, 78, 95, 78, 78).build(),
    ];
    case 'D': return [
      b().m(20, 8).l(20, 92).build(),
      b().m(20, 8).l(52, 8).c(88, 8, 88, 92, 52, 92).l(20, 92).build(),
    ];
    case 'E': return [
      b().m(22, 8).l(22, 92).build(),
      b().m(22, 8).l(78, 8).build(),
      b().m(22, 50).l(65, 50).build(),
      b().m(22, 92).l(78, 92).build(),
    ];
    case 'F': return [
      b().m(22, 8).l(22, 92).build(),
      b().m(22, 8).l(78, 8).build(),
      b().m(22, 50).l(65, 50).build(),
    ];
    case 'G': return [
      b().m(78, 22).c(78, 5, 8, 5, 8, 50).c(8, 95, 78, 95, 78, 72).l(55, 72).build(),
    ];
    case 'H': return [
      b().m(18, 8).l(18, 92).build(),
      b().m(82, 8).l(82, 92).build(),
      b().m(18, 50).l(82, 50).build(),
    ];
    case 'I': return [
      b().m(28, 8).l(72, 8).build(),
      b().m(50, 8).l(50, 92).build(),
      b().m(28, 92).l(72, 92).build(),
    ];
    case 'J': return [
      b().m(28, 8).l(72, 8).build(),
      b().m(72, 8).l(72, 72).q(72, 92, 50, 92).q(22, 92, 22, 72).build(),
    ];
    case 'K': return [
      b().m(20, 8).l(20, 92).build(),
      b().m(20, 50).l(82, 8).build(),
      b().m(20, 50).l(82, 92).build(),
    ];
    case 'L': return [
      b().m(22, 8).l(22, 92).build(),
      b().m(22, 92).l(78, 92).build(),
    ];
    case 'M': return [
      b().m(12, 92).l(12, 8).build(),
      b().m(12, 8).l(50, 58).build(),
      b().m(50, 58).l(88, 8).build(),
      b().m(88, 8).l(88, 92).build(),
    ];
    case 'N': return [
      b().m(15, 8).l(15, 92).build(),
      b().m(15, 8).l(85, 92).build(),
      b().m(85, 8).l(85, 92).build(),
    ];
    case 'O': return [
      b().m(50, 8)
         .c(82, 8, 90, 22, 90, 50)
         .c(90, 78, 82, 92, 50, 92)
         .c(18, 92, 10, 78, 10, 50)
         .c(10, 22, 18, 8, 50, 8)
         .build(),
    ];
    case 'P': return [
      b().m(20, 8).l(20, 92).build(),
      b().m(20, 8).l(58, 8).q(80, 8, 80, 29).q(80, 50, 58, 50).l(20, 50).build(),
    ];
    case 'Q': return [
      b().m(50, 8)
         .c(82, 8, 90, 22, 90, 50)
         .c(90, 78, 82, 92, 50, 92)
         .c(18, 92, 10, 78, 10, 50)
         .c(10, 22, 18, 8, 50, 8)
         .build(),
      b().m(62, 70).l(85, 90).build(),
    ];
    case 'R': return [
      b().m(20, 8).l(20, 92).build(),
      b().m(20, 8).l(58, 8).q(80, 8, 80, 29).q(80, 50, 58, 50).l(20, 50).build(),
      b().m(42, 50).l(82, 92).build(),
    ];
    case 'S': return [
      b().m(78, 22)
         .c(78, 5, 22, 5, 22, 32)
         .c(22, 50, 78, 50, 78, 68)
         .c(78, 95, 22, 95, 22, 78)
         .build(),
    ];
    case 'T': return [
      b().m(10, 8).l(90, 8).build(),
      b().m(50, 8).l(50, 92).build(),
    ];
    case 'U': return [
      b().m(20, 8).l(20, 65).q(20, 92, 50, 92).q(80, 92, 80, 65).l(80, 8).build(),
    ];
    case 'V': return [
      b().m(10, 8).l(50, 92).build(),
      b().m(50, 92).l(90, 8).build(),
    ];
    case 'W': return [
      b().m(8, 8).l(28, 92).build(),
      b().m(28, 92).l(50, 52).build(),
      b().m(50, 52).l(72, 92).build(),
      b().m(72, 92).l(92, 8).build(),
    ];
    case 'X': return [
      b().m(10, 8).l(90, 92).build(),
      b().m(90, 8).l(10, 92).build(),
    ];
    case 'Y': return [
      b().m(10, 8).l(50, 50).build(),
      b().m(90, 8).l(50, 50).build(),
      b().m(50, 50).l(50, 92).build(),
    ];
    case 'Z': return [
      b().m(10, 8).l(90, 8).build(),
      b().m(90, 8).l(10, 92).build(),
      b().m(10, 92).l(90, 92).build(),
    ];
    default: return [];
  }
}

/// Helper for validating kid's handwritten strokes step-by-step
class StrokeValidator {
  /// Validates whether the user's drawn points [userPoints] match the [expectedGuideMetric].
  static bool validateStroke({
    required List<Offset> userPoints,
    required PathMetric guideMetric,
    double tolerance = 48.0,
  }) {
    if (userPoints.length < 2) return false;

    final guideLen = guideMetric.length;

    // Small dot (e.g., top dot of 'i' or 'j')
    if (guideLen < 20) {
      final dotTangent = guideMetric.getTangentForOffset(0);
      if (dotTangent == null) return true;
      final dist = (userPoints.first - dotTangent.position).distance;
      return dist <= tolerance * 1.3;
    }

    // Sample guide checkpoints
    const numCheckpoints = 20;
    final checkpoints = <Offset>[];
    for (int i = 0; i <= numCheckpoints; i++) {
      final t = guideMetric.getTangentForOffset(i / numCheckpoints * guideLen);
      if (t != null) {
        checkpoints.add(t.position);
      }
    }
    if (checkpoints.isEmpty) return false;

    // 1. Start point proximity check (must start near the guide start)
    final startDist = (userPoints.first - checkpoints.first).distance;
    if (startDist > tolerance * 1.25) {
      return false;
    }

    // 2. End point proximity check (must end near the guide end)
    final endDist = (userPoints.last - checkpoints.last).distance;
    if (endDist > tolerance * 1.35) {
      return false;
    }

    // 3. Direction and checkpoint progression
    int checkpointIdx = 0;
    for (final pt in userPoints) {
      if (checkpointIdx < checkpoints.length) {
        final d = (pt - checkpoints[checkpointIdx]).distance;
        if (d <= tolerance) {
          checkpointIdx++;
        }
      }
    }

    // Must reach at least 60% of checkpoints in forward progression
    final requiredVisited = (checkpoints.length * 0.60).ceil();
    if (checkpointIdx < requiredVisited) {
      return false;
    }

    // 4. Mean deviation check (user stroke shouldn't stray wildly)
    double totalDev = 0;
    final sampleStep = max(1, userPoints.length ~/ 15);
    int samples = 0;
    for (int i = 0; i < userPoints.length; i += sampleStep) {
      final u = userPoints[i];
      double minDist = double.infinity;
      for (final cp in checkpoints) {
        final d = (u - cp).distance;
        if (d < minDist) minDist = d;
      }
      totalDev += minDist;
      samples++;
    }
    if (samples > 0 && (totalDev / samples) > tolerance * 1.2) {
      return false;
    }

    return true;
  }
}
