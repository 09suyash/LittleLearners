import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../coloring_book/coloring_models.dart';
import '../coloring_book/coloring_scenes_data.dart';
import '../coloring_book/coloring_canvas.dart';
import '../coloring_book/coloring_palette_bar.dart';
import '../coloring_book/coloring_scene_selector.dart';

class ColoringBookScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ColoringBookScreen({super.key, required this.onBack});

  @override
  State<ColoringBookScreen> createState() => _ColoringBookScreenState();
}

class _ColoringBookScreenState extends State<ColoringBookScreen> {
  final _bs = BadgeService();
  final _sfx = SoundService();
  late final List<ColoringScene> _scenes;
  int _sceneIdx = 0;
  Color _pick = const Color(0xFFFF6B6B);
  bool _showConfetti = false;
  Size? _lastSize;
  String _filter = 'all';

  // ── Painting state ──
  ColoringTool _tool = ColoringTool.brush;
  int _brushSizeIdx = 1;
  ColoringStrokeData? _currentStroke;
  Offset? _cursorPos;

  // ── Scene picker ──
  bool _showPicker = false;

  @override
  void initState() {
    super.initState();
    _scenes = makeColoringScenes();
  }

  ColoringScene get _scene => _scenes[_sceneIdx];

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
    final color = _tool == ColoringTool.eraser ? Colors.white : _pick;
    final reg = _scene.hit(d.localPosition);
    setState(() {
      _cursorPos = d.localPosition;
      _currentStroke = ColoringStrokeData(
        color: color,
        width: coloringBrushSizes[_brushSizeIdx],
        clipPath: reg?.path,
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
        if (_showPicker)
          ColoringSceneSelectorOverlay(
            scenes: _scenes,
            currentSceneIdx: _sceneIdx,
            filter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
            onSelectScene: (idx) {
              _switchScene(idx);
              setState(() => _showPicker = false);
            },
            onClose: () => setState(() => _showPicker = false),
          ),
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
                ColoringCurrentSceneBadge(
                  scene: _scene,
                  onTap: () => setState(() => _showPicker = true),
                ),
                const SizedBox(height: 8),
                Expanded(child: _canvas()),
                const SizedBox(height: 6),
                ColoringToolBar(
                  tool: _tool,
                  brushSizeIdx: _brushSizeIdx,
                  canUndo: _scene.strokes.isNotEmpty,
                  onSelectTool: (t) => setState(() => _tool = t),
                  onSelectBrushSize: (idx) => setState(() => _brushSizeIdx = idx),
                  onUndo: _undo,
                ),
                const SizedBox(height: 6),
                ColoringPaletteBar(
                  selectedColor: _pick,
                  onSelectColor: (c) => setState(() => _pick = c),
                ),
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
              buildColoringPaths(_sceneIdx, _scene.regions, size);
            }
            final cursorColor = _tool == ColoringTool.eraser
                ? Colors.grey
                : _pick.toARGB32() == Colors.white.toARGB32()
                    ? Colors.grey
                    : _pick;
            final paint = CustomPaint(
              size: size,
              painter: ColoringPainter(
                _scene.regions,
                _scene.strokes,
                _currentStroke,
                cursorPos: _cursorPos,
                cursorColor: cursorColor,
                cursorSize: coloringBrushSizes[_brushSizeIdx],
                tool: _tool,
              ),
            );
            if (_tool == ColoringTool.fill) {
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
                if (_currentStroke == null) {
                  setState(() => _cursorPos = e.localPosition);
                }
              },
              onPointerUp: (_) {
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
}
