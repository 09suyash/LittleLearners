import 'dart:math';
import 'package:flutter/material.dart';
import '../models/shape_data.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

class ShapeSorterScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ShapeSorterScreen({super.key, required this.onBack});

  @override
  State<ShapeSorterScreen> createState() => _ShapeSorterScreenState();
}

class _ShapeSorterScreenState extends State<ShapeSorterScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final _rng = Random();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _counts = [3, 5, 7];
  static const _holeSizes = [72.0, 60.0, 52.0];
  int _diffIdx = 0;

  late List<ShapeData> _roundShapes;
  late List<ShapeData> _holeOrder;
  late List<ShapeData> _trayOrder;
  final Set<String> _placed = {};
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _buildRound();
  }

  void _buildRound() {
    _roundShapes = shapes.take(_counts[_diffIdx]).toList();
    _holeOrder = List.of(_roundShapes)..shuffle(_rng);
    _trayOrder = List.of(_roundShapes)..shuffle(_rng);
    _placed.clear();
    _started = false;
  }

  bool get _won => _placed.length == _roundShapes.length;

  void _onDropAccepted(ShapeData hole) {
    setState(() {
      _placed.add(hole.id);
      _started = true;
    });
    _sfx.play(SoundType.correct);
    if (_won) _onWin();
  }

  void _onDropRejected() {
    _sfx.play(SoundType.wrong);
  }

  Future<void> _onWin() async {
    _sfx.play(SoundType.win);
    await AppState.addStars(10);
    if (!mounted) return;
    await awardWithToast(context, _bs, 'shape_first');
    if (_diffIdx == 2 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'shape_hard', stars: 50);
    }
  }

  void _restart() {
    setState(_buildRound);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF3a1c71), Color(0xFFd76d77), Color(0xFFffaf7b)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.10, child: const Text('🧸', style: TextStyle(fontSize: 140)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(child: _won ? _buildWinActions() : _buildGame()),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _won),
      ConfettiOverlay(trigger: _won),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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
        const Text('🧸', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Shape Sorter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        GestureDetector(
          onTap: () {
            if (!_started) {
              setState(() {
                _diffIdx = (_diffIdx + 1) % 3;
                _buildRound();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(36)),
            ),
            child: Text(_difficulties[_diffIdx],
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD93D))),
          ),
        ),
      ]),
    );
  }

  Widget _buildGame() {
    final holeSize = _holeSizes[_diffIdx];
    final tray = _trayOrder.where((s) => !_placed.contains(s.id)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text('${_placed.length} / ${_roundShapes.length} sorted',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Center(
          child: Wrap(
            spacing: 14, runSpacing: 14, alignment: WrapAlignment.center,
            children: [for (final hole in _holeOrder) _buildHole(hole, holeSize)],
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: const BoxConstraints(minHeight: 90),
        child: tray.isEmpty
            ? const SizedBox(height: 60)
            : Wrap(
                spacing: 14, runSpacing: 10, alignment: WrapAlignment.center,
                children: [for (final s in tray) _buildDraggableTile(s)],
              ),
      ),
    ]);
  }

  Widget _buildHole(ShapeData hole, double size) {
    final filled = _placed.contains(hole.id);
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == hole.id,
      onAcceptWithDetails: (_) => _onDropAccepted(hole),
      builder: (context, candidate, rejected) {
        final highlighting = candidate.isNotEmpty;
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: filled ? Colors.transparent : Colors.white.withAlpha(highlighting ? 60 : 26),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : highlighting ? Colors.white : Colors.white.withAlpha(90),
              width: 2,
              style: filled ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
          child: Center(
            child: filled
                ? AnimatedScale(
                    scale: 1.0, duration: const Duration(milliseconds: 250),
                    child: _ShapeVisual(type: hole.type, color: hole.color, size: size * 0.75),
                  )
                : Opacity(
                    opacity: 0.35,
                    child: _ShapeVisual(type: hole.type, color: Colors.white, size: size * 0.6),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableTile(ShapeData s) {
    final size = 54.0;
    final visual = _ShapeVisual(type: s.type, color: s.color, size: size);
    return Draggable<String>(
      data: s.id,
      feedback: Opacity(opacity: 0.9, child: _ShapeVisual(type: s.type, color: s.color, size: size * 1.15)),
      childWhenDragging: Opacity(opacity: 0.25, child: visual),
      onDraggableCanceled: (_, _) => _onDropRejected(),
      child: visual,
    );
  }

  Widget _buildWinActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x44FFD93D), blurRadius: 20)],
          ),
          child: Column(children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            const Text('All shapes sorted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _restart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDA085),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
            ),
            child: const Text('🔄 Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('🏠 Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _ShapeVisual extends StatelessWidget {
  final ShapeType type;
  final Color color;
  final double size;
  const _ShapeVisual({required this.type, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ShapeType.circle:
        return Container(width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color));
      case ShapeType.square:
        return Container(width: size, height: size,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)));
      case ShapeType.rectangle:
        return Container(width: size * 1.4, height: size * 0.7,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)));
      case ShapeType.oval:
        return Container(width: size * 1.4, height: size * 0.8,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)));
      case ShapeType.triangle:
      case ShapeType.star:
      case ShapeType.hexagon:
        return CustomPaint(size: Size(size, size), painter: _ShapePainter(type, color));
    }
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  const _ShapePainter(this.type, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = switch (type) {
      ShapeType.triangle => _trianglePath(size),
      ShapeType.star => _starPath(size),
      ShapeType.hexagon => _hexagonPath(size),
      _ => Path(),
    };
    canvas.drawPath(path, paint);
  }

  Path _trianglePath(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  Path _hexagonPath(Size size) {
    final path = Path();
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy);
    for (int i = 0; i < 6; i++) {
      final angle = pi / 180 * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  Path _starPath(Size size) {
    final path = Path();
    final cx = size.width / 2, cy = size.height / 2;
    final outerR = min(cx, cy);
    final innerR = outerR * 0.45;
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = pi / 180 * (36 * i - 90);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.type != type || old.color != color;
}
