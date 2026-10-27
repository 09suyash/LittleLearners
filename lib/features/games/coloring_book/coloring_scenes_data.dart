import 'dart:math';
import 'package:flutter/material.dart';
import 'coloring_models.dart';

// ── Star path helper ──────────────────────────────────────────────────
Path starPath(double cx, double cy, double outerR, double innerR, int pts) {
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
List<ColoringScene> makeColoringScenes() => [
  ColoringScene('Sun & Sky', '☀️', [
    ColoringRegion('sky'),
    ColoringRegion('hill'),
    ColoringRegion('sun'),
    ColoringRegion('cloud1'),
    ColoringRegion('cloud2'),
    ColoringRegion('ground'),
  ]),
  ColoringScene('Happy Cat', '🐱', [
    ColoringRegion('bg'),
    ColoringRegion('body'),
    ColoringRegion('head'),
    ColoringRegion('ears'),
    ColoringRegion('eyes'),
    ColoringRegion('nose'),
    ColoringRegion('tail'),
  ]),
  ColoringScene('Cozy House', '🏠', [
    ColoringRegion('sky'),
    ColoringRegion('ground'),
    ColoringRegion('wall'),
    ColoringRegion('roof'),
    ColoringRegion('door'),
    ColoringRegion('windows'),
    ColoringRegion('chimney'),
  ]),
  ColoringScene('Big Flower', '🌸', [
    ColoringRegion('sky'),
    ColoringRegion('ground'),
    ColoringRegion('stem'),
    ColoringRegion('leaves'),
    ColoringRegion('petals'),
    ColoringRegion('center'),
    ColoringRegion('sun'),
  ]),
  ColoringScene('Happy Fish', '🐟', [
    ColoringRegion('water'),
    ColoringRegion('body'),
    ColoringRegion('tail'),
    ColoringRegion('fin'),
    ColoringRegion('eye'),
    ColoringRegion('stripes'),
    ColoringRegion('bubbles'),
  ]),
  ColoringScene('Butterfly', '🦋', [
    ColoringRegion('sky'),
    ColoringRegion('body'),
    ColoringRegion('lwing_t'),
    ColoringRegion('lwing_b'),
    ColoringRegion('rwing_t'),
    ColoringRegion('rwing_b'),
    ColoringRegion('head'),
  ]),
  ColoringScene('Rainbow', '🌈', [
    ColoringRegion('sky'),
    ColoringRegion('ground'),
    ColoringRegion('outer'),
    ColoringRegion('mid'),
    ColoringRegion('inner'),
    ColoringRegion('sun'),
    ColoringRegion('cloud'),
  ]),
  ColoringScene('Rocket', '🚀', [
    ColoringRegion('sky'),
    ColoringRegion('body'),
    ColoringRegion('nose'),
    ColoringRegion('lfin'),
    ColoringRegion('rfin'),
    ColoringRegion('window'),
    ColoringRegion('flame'),
  ]),
  ColoringScene('Big Tree', '🌳', [
    ColoringRegion('sky'),
    ColoringRegion('ground'),
    ColoringRegion('trunk'),
    ColoringRegion('canopy'),
    ColoringRegion('fruits'),
    ColoringRegion('apples'),
    ColoringRegion('sun'),
  ]),
  ColoringScene('Starry Night', '🌙', [
    ColoringRegion('sky'),
    ColoringRegion('hills'),
    ColoringRegion('moon'),
    ColoringRegion('star1'),
    ColoringRegion('star2'),
    ColoringRegion('star3'),
    ColoringRegion('ground'),
  ]),
];

// ── Path building (chunky, rounded, kid-friendly) ─────────────────────
void buildColoringPaths(int idx, List<ColoringRegion> regs, Size s) {
  final w = s.width, h = s.height;
  ColoringRegion r(String id) => regs.firstWhere((x) => x.id == id);

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
      r('star1').path = starPath(w * .2, h * .14, w * .1, w * .045, 5);
      r('star2').path = starPath(w * .48, h * .08, w * .08, w * .035, 5);
      r('star3').path = starPath(w * .35, h * .32, w * .07, w * .03, 5);
      break;
  }
}
