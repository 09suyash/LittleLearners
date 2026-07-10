import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

// ── Palette ────────────────────────────────────────────────────────────
const List<Color> _palette = [
  Color(0xFFFF6B6B), Color(0xFFFF922B), Color(0xFFFFD93D), Color(0xFF6BCB77),
  Color(0xFF4D96FF), Color(0xFF845EF7), Color(0xFFFF80AB), Color(0xFF20C997),
  Color(0xFFA0522D), Color(0xFF74C0FC), Color(0xFFA9E34B), Colors.white,
];

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

  _Scene(this.name, this.emoji, this.regions);

  bool get allColored => regions.every((r) => r.colored);
  void reset() {
    for (final r in regions) { r.reset(); }
    completed = false;
  }

  _Reg? hit(Offset pt) {
    for (int i = regions.length - 1; i >= 0; i--) {
      if (regions[i].path.contains(pt)) return regions[i];
    }
    return null;
  }
}

// ── Painter ────────────────────────────────────────────────────────────
class _Painter extends CustomPainter {
  final List<_Reg> regions;
  _Painter(this.regions);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white);
    final fp = Paint()..style = PaintingStyle.fill;
    for (final r in regions) {
      fp.color = r.fill;
      canvas.drawPath(r.path, fp);
    }
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFF1a1a1a)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final r in regions) {
      canvas.drawPath(r.path, lp);
    }
  }

  @override
  bool shouldRepaint(_Painter p) => true;
}

// ── Scene factories ────────────────────────────────────────────────────
List<_Scene> _makeScenes() => [
      _Scene('Sun & Sky', '☀️', [_Reg('sky'), _Reg('ground'), _Reg('cloud'), _Reg('sun')]),
      _Scene('Happy Cat', '🐱', [_Reg('bg'), _Reg('head'), _Reg('ears'), _Reg('eyes'), _Reg('nose')]),
      _Scene('Cozy House', '🏠', [_Reg('sky'), _Reg('ground'), _Reg('wall'), _Reg('roof'), _Reg('details')]),
      _Scene('Big Flower', '🌸', [_Reg('sky'), _Reg('ground'), _Reg('stem'), _Reg('petals'), _Reg('center')]),
      _Scene('Happy Fish', '🐟', [_Reg('water'), _Reg('tail'), _Reg('body'), _Reg('fin'), _Reg('eye')]),
    ];

void _buildPaths(int idx, List<_Reg> regs, Size s) {
  final w = s.width, h = s.height;
  _Reg r(String id) => regs.firstWhere((x) => x.id == id);

  switch (idx) {
    case 0: // Sun & Sky
      r('sky').path    = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .72));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .72, w, h * .28));
      r('sun').path    = Path()..addOval(Rect.fromCenter(center: Offset(w * .5, h * .36), width: w * .38, height: w * .38));
      final cld = Path();
      cld.addOval(Rect.fromCenter(center: Offset(w * .78, h * .15), width: w * .22, height: w * .15));
      cld.addOval(Rect.fromCenter(center: Offset(w * .70, h * .17), width: w * .15, height: w * .11));
      cld.addOval(Rect.fromCenter(center: Offset(w * .86, h * .17), width: w * .15, height: w * .11));
      r('cloud').path  = cld;
      break;

    case 1: // Happy Cat
      r('bg').path   = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
      r('head').path = Path()..addOval(Rect.fromCenter(center: Offset(w * .5, h * .57), width: w * .74, height: h * .66));
      final ears = Path();
      ears.moveTo(w * .16, h * .37); ears.lineTo(w * .27, h * .12); ears.lineTo(w * .41, h * .31); ears.close();
      ears.moveTo(w * .84, h * .37); ears.lineTo(w * .73, h * .12); ears.lineTo(w * .59, h * .31); ears.close();
      r('ears').path = ears;
      final eyes = Path();
      eyes.addOval(Rect.fromCenter(center: Offset(w * .34, h * .5), width: w * .16, height: w * .16));
      eyes.addOval(Rect.fromCenter(center: Offset(w * .66, h * .5), width: w * .16, height: w * .16));
      r('eyes').path = eyes;
      r('nose').path = Path()..addOval(Rect.fromCenter(center: Offset(w * .5, h * .63), width: w * .12, height: w * .08));
      break;

    case 2: // Cozy House
      r('sky').path     = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .5));
      r('ground').path  = Path()..addRect(Rect.fromLTWH(0, h * .5, w, h * .5));
      r('wall').path    = Path()..addRect(Rect.fromLTWH(w * .14, h * .5, w * .72, h * .24));
      final roof = Path()..moveTo(w * .07, h * .5)..lineTo(w * .5, h * .14)..lineTo(w * .93, h * .5)..close();
      r('roof').path    = roof;
      final det = Path();
      det.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .42, h * .62, w * .16, h * .12), const Radius.circular(4)));
      det.addRect(Rect.fromLTWH(w * .19, h * .57, w * .14, h * .1));
      det.addRect(Rect.fromLTWH(w * .67, h * .57, w * .14, h * .1));
      r('details').path = det;
      break;

    case 3: // Big Flower
      r('sky').path    = Path()..addRect(Rect.fromLTWH(0, 0, w, h * .68));
      r('ground').path = Path()..addRect(Rect.fromLTWH(0, h * .68, w, h * .32));
      r('stem').path   = Path()..addRect(Rect.fromLTWH(w * .46, h * .38, w * .08, h * .32));
      final petals = Path();
      for (int i = 0; i < 8; i++) {
        final a = i * pi / 4;
        petals.addOval(Rect.fromCenter(
          center: Offset(w * .5 + cos(a) * w * .2, h * .26 + sin(a) * h * .17),
          width: w * .2, height: h * .18,
        ));
      }
      r('petals').path = petals;
      r('center').path = Path()..addOval(Rect.fromCenter(center: Offset(w * .5, h * .26), width: w * .25, height: w * .25));
      break;

    case 4: // Happy Fish
      r('water').path = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
      final tail = Path()..moveTo(w * .78, h * .3)..lineTo(w * .97, h * .1)..lineTo(w * .97, h * .9)..lineTo(w * .78, h * .7)..close();
      r('tail').path  = tail;
      r('body').path  = Path()..addOval(Rect.fromCenter(center: Offset(w * .42, h * .5), width: w * .64, height: h * .38));
      final fin = Path()..moveTo(w * .35, h * .31)..lineTo(w * .52, h * .14)..lineTo(w * .6, h * .31)..close();
      r('fin').path   = fin;
      r('eye').path   = Path()..addOval(Rect.fromCenter(center: Offset(w * .2, h * .44), width: w * .1, height: w * .1));
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
  final _bs  = BadgeService();
  final _sfx = SoundService();
  late final List<_Scene> _scenes;
  int    _sceneIdx = 0;
  Color  _pick = const Color(0xFFFF6B6B);
  bool   _showConfetti = false;
  Size?  _lastSize;
  String _filter = 'all'; // 'all' | 'todo' | 'done'

  List<int> get _filteredIndices {
    switch (_filter) {
      case 'todo': return [for (int i = 0; i < _scenes.length; i++) if (!_scenes[i].completed) i];
      case 'done': return [for (int i = 0; i < _scenes.length; i++) if (_scenes[i].completed) i];
      default:     return List.generate(_scenes.length, (i) => i);
    }
  }

  @override
  void initState() {
    super.initState();
    _scenes = _makeScenes();
  }

  _Scene get _scene => _scenes[_sceneIdx];

  Future<void> _onTap(Offset pt) async {
    final reg = _scene.hit(pt);
    if (reg == null) return;
    setState(() => reg.fill = _pick);
    _sfx.play(SoundType.tap);
    await awardWithToast(context, _bs, 'color_first', stars: 10);
    if (!_scene.completed && _scene.allColored) {
      setState(() { _scene.completed = true; _showConfetti = true; });
      _sfx.play(SoundType.win);
      await AppState.addStars(10);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) await awardWithToast(context, _bs, 'color_scene');
      }
    }
  }

  void _switchScene(int i) {
    if (i == _sceneIdx) return;
    setState(() { _sceneIdx = i; _showConfetti = false; _lastSize = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildMain(),
      MascotCorner(celebrating: _showConfetti),
      ConfettiOverlay(trigger: _showConfetti),
    ]);
  }

  Widget _buildMain() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF2d1b69)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.12, child: Image.asset('assets/images/coloring_card.png', width: 160, height: 160, fit: BoxFit.contain))),
        Positioned(bottom: 80, left: -10,
            child: Opacity(opacity: 0.05, child: const Text('🌟', style: TextStyle(fontSize: 100)))),
        Positioned(bottom: -10, right: -10,
            child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
        SafeArea(
        child: Column(children: [
          _header(),
          const SizedBox(height: 8),
          _filterRow(),
          const SizedBox(height: 6),
          _scenePicker(),
          const SizedBox(height: 8),
          Expanded(child: _canvas()),
          const SizedBox(height: 8),
          _paletteRow(),
          const SizedBox(height: 14),
        ]),
      ),
      ]),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        Image.asset('assets/images/coloring_card.png', width: 30, height: 30, fit: BoxFit.contain),
        const SizedBox(width: 6),
        const Expanded(child: Text('Coloring Book',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
        GestureDetector(
          onTap: () => setState(() { _scene.reset(); _showConfetti = false; }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(36)),
            ),
            child: const Text('🗑 Reset',
                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _filterRow() {
    const filters = [('all', 'All'), ('todo', 'To Do'), ('done', 'Done ✅')];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        for (final (key, label) in filters) ...[
          GestureDetector(
            onTap: () {
              if (_filter == key) return;
              final indices = key == 'all'
                  ? List.generate(_scenes.length, (i) => i)
                  : key == 'todo'
                      ? [for (int i = 0; i < _scenes.length; i++) if (!_scenes[i].completed) i]
                      : [for (int i = 0; i < _scenes.length; i++) if (_scenes[i].completed) i];
              setState(() {
                _filter = key;
                if (indices.isNotEmpty && !indices.contains(_sceneIdx)) {
                  _sceneIdx = indices.first;
                  _showConfetti = false;
                  _lastSize = null;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _filter == key ? const Color(0xFFFFD93D) : Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _filter == key ? const Color(0xFF1a0533) : Colors.white70,
                  )),
            ),
          ),
          if (key != 'done') const SizedBox(width: 8),
        ],
      ]),
    );
  }

  Widget _scenePicker() {
    final indices = _filteredIndices;
    if (indices.isEmpty) {
      return SizedBox(
        height: 44,
        child: Center(
          child: Text(
            _filter == 'done' ? 'No scenes completed yet — start coloring!' : 'All scenes completed! 🎉',
            style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        separatorBuilder: (_, s) => const SizedBox(width: 8),
        itemCount: indices.length,
        itemBuilder: (_, i) {
          final sceneI = indices[i];
          final sel = sceneI == _sceneIdx;
          return GestureDetector(
            onTap: () => _switchScene(sceneI),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withAlpha(36) : Colors.white.withAlpha(14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? const Color(0xFFFFD93D) : Colors.white.withAlpha(30),
                  width: sel ? 2 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_scenes[sceneI].emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(_scenes[sceneI].name,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : Colors.white60)),
                if (_scenes[sceneI].completed) ...[
                  const SizedBox(width: 4),
                  const Text('✅', style: TextStyle(fontSize: 10)),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _canvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(builder: (_, cst) {
          final size = Size(cst.maxWidth, cst.maxHeight);
          if (_lastSize != size) {
            _lastSize = size;
            _buildPaths(_sceneIdx, _scene.regions, size);
          }
          return GestureDetector(
            onTapDown: (d) => _onTap(d.localPosition),
            child: CustomPaint(
              size: size,
              painter: _Painter(_scene.regions),
            ),
          );
        }),
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
                    ? [BoxShadow(color: color.withAlpha(130), blurRadius: 12, spreadRadius: 2)]
                    : null,
              ),
              child: color.toARGB32() == Colors.white.toARGB32()
                  ? const Center(child: Text('🗑', style: TextStyle(fontSize: 14)))
                  : null,
            ),
          );
        },
      ),
    );
  }
}
