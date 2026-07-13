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

/// Returns the ordered guide stroke [Path]s for [letter], scaled to [sz].
/// Each Path is one continuous stroke the child should trace.
List<Path> letterGuide(String letter, Size sz) {
  final w = sz.width, h = sz.height;
  _PB b() => _PB(w, h);

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
