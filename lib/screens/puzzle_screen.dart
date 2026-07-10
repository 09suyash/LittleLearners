import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

class _PScene {
  final String name, icon;
  final List<String> tiles; // 8 emojis for tiles 1–8
  const _PScene(this.name, this.icon, this.tiles);
}

const _scenes = [
  _PScene('Farm',   '🌻', ['🌻','☀️','🐄','🏠','🐔','🌱','🌺','🦋']),
  _PScene('Ocean',  '🌊', ['🌊','⛵','🐟','🐠','🦈','🐙','🦑','🐚']),
  _PScene('Space',  '🚀', ['⭐','🌟','🚀','🌙','💫','🪐','🛸','🌌']),
  _PScene('Jungle', '🌴', ['🌴','🐒','🦁','🌿','🐘','🌺','🦋','🌸']),
];

class PuzzleScreen extends StatefulWidget {
  final VoidCallback onBack;
  const PuzzleScreen({super.key, required this.onBack});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final _bs  = BadgeService();
  final _sfx = SoundService();
  final _rng = Random();

  int  _sceneIdx = 0;
  int  _gridSize = 3;       // 2 → Baby (2×2), 3 → Normal (3×3)
  late List<int> _grid;     // _gridSize² slots: value 1.._tileCount = tile, 0 = empty
  late int _emptyIdx;
  int  _moves = 0;
  bool _won   = false;
  bool _showConfetti = false;

  int get _totalSlots => _gridSize * _gridSize;
  int get _tileCount  => _totalSlots - 1;
  int get _fastTarget => _gridSize == 2 ? 10 : 35;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  // ── Game logic ──────────────────────────────────────────────────

  void _newGame() {
    setState(() {
      _won = false;
      _showConfetti = false;
      _moves = 0;
      _shuffle();
    });
  }

  void _shuffle() {
    final moves = _gridSize == 2 ? 25 : 100;
    _grid = List.generate(_totalSlots, (i) => i < _tileCount ? i + 1 : 0);
    _emptyIdx = _tileCount;
    int prev = -1;
    for (int s = 0; s < moves; s++) {
      final nbrs = _neighbors(_emptyIdx).where((n) => n != prev).toList();
      final swap = nbrs[_rng.nextInt(nbrs.length)];
      prev = _emptyIdx;
      _grid[_emptyIdx] = _grid[swap];
      _grid[swap] = 0;
      _emptyIdx = swap;
    }
  }

  List<int> _neighbors(int idx) {
    final row = idx ~/ _gridSize, col = idx % _gridSize;
    return [
      if (row > 0)              (row - 1) * _gridSize + col,
      if (row < _gridSize - 1)  (row + 1) * _gridSize + col,
      if (col > 0)              row * _gridSize + col - 1,
      if (col < _gridSize - 1)  row * _gridSize + col + 1,
    ];
  }

  void _tap(int gridPos) {
    if (_won || !_neighbors(_emptyIdx).contains(gridPos)) return;
    setState(() {
      _grid[_emptyIdx] = _grid[gridPos];
      _grid[gridPos]   = 0;
      _emptyIdx        = gridPos;
      _moves++;
    });
    _sfx.play(SoundType.slide);
    _checkWin();
  }

  Future<void> _checkWin() async {
    for (int i = 0; i < _totalSlots; i++) {
      if (_grid[i] != (i < _tileCount ? i + 1 : 0)) return;
    }
    setState(() { _won = true; _showConfetti = true; });
    _sfx.play(SoundType.win);
    await AppState.addStars(10);
    if (!mounted) return;
    await awardWithToast(context, _bs, 'puzzle_first');
    if (_moves <= _fastTarget && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'puzzle_fast', stars: 50);
    }
  }

  // ── Tutorial dialog ─────────────────────────────────────────────

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF2C1654),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/puzzle_card.png', width: 60, height: 60, fit: BoxFit.contain),
              const SizedBox(height: 6),
              const Text('How to Play',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 18),
              _tutStep('🖼️', 'Tiles are scrambled!',
                  '$_tileCount picture tiles are mixed up in a $_gridSize×$_gridSize grid. One box is always EMPTY.'),
              const SizedBox(height: 10),
              _tutStep('👆', 'Tap a tile next to the empty box',
                  'Only tiles that TOUCH the empty space can slide. Look for the glowing tiles!'),
              const SizedBox(height: 10),
              _tutStep('➡️', 'It slides into the empty space',
                  'Keep sliding tiles one by one to put them all in order.'),
              const SizedBox(height: 10),
              _tutStep('🏆', 'Win when all tiles are in order!',
                  'Tiles 1→8 must go left-to-right, top-to-bottom. Empty box goes last.'),
              const SizedBox(height: 18),
              _miniGoalGrid(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD93D),
                    foregroundColor: const Color(0xFF1a0533),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Let's Play! 🎮",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tutStep(String icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
          const SizedBox(height: 2),
          Text(desc,
              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _miniGoalGrid() {
    final emojis = _scenes[_sceneIdx].tiles;
    return Column(children: [
      const Text('🎯 Goal — tiles in this order:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60)),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (ctx, cst) => SizedBox(
        width: (cst.maxWidth * 0.55).clamp(120.0, 200.0),
        child: GridView.count(
          crossAxisCount: _gridSize,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (int i = 0; i < _tileCount; i++)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF51CF66), width: 1.5),
                ),
                child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 18))),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              ),
              child: const Center(child: Text('⬜', style: TextStyle(fontSize: 18))),
            ),
          ],
        ),
      )),
    ]);
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildMain(),
      MascotCorner(celebrating: _won),
      ConfettiOverlay(trigger: _showConfetti),
    ]);
  }

  Widget _buildMain() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF6C3483), Color(0xFF1F618D), Color(0xFF148F77)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.12, child: Image.asset('assets/images/puzzle_card.png', width: 160, height: 160, fit: BoxFit.contain))),
        Positioned(bottom: 80, left: -10,
            child: Opacity(opacity: 0.05, child: const Text('🌟', style: TextStyle(fontSize: 100)))),
        Positioned(bottom: -10, right: -10,
            child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
        SafeArea(
          child: Column(children: [
            _header(),
            const SizedBox(height: 8),
            _scenePicker(),
            const SizedBox(height: 6),
            _sizePicker(),
            const SizedBox(height: 6),
            _statusBar(),
            Expanded(child: Center(child: _gridArea())),
            if (_won) _winBanner(),
            const SizedBox(height: 12),
            _bottomBar(),
            const SizedBox(height: 16),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(35)),
        ),
        child: Row(children: [
          const Text('✨', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _won
                  ? '🎉 You solved it in $_moves moves!'
                  : 'Tap a glowing tile to slide it into the empty box!',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        Image.asset('assets/images/puzzle_card.png', width: 30, height: 30, fit: BoxFit.contain),
        const SizedBox(width: 6),
        const Expanded(child: Text('Puzzle Pieces',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
        // Moves counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/shuffle_card.png', width: 26, height: 26, fit: BoxFit.contain),
            const SizedBox(width: 5),
            Text('$_moves', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
          ]),
        ),
        const SizedBox(width: 8),
        // Help button
        GestureDetector(
          onTap: _showTutorialDialog,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D).withAlpha(40),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD93D).withAlpha(120), width: 1.5),
            ),
            child: const Text('?', style: TextStyle(color: Color(0xFFFFD93D), fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }

  Widget _scenePicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemCount: _scenes.length,
        itemBuilder: (_, i) {
          final sel = i == _sceneIdx;
          return GestureDetector(
            onTap: () { setState(() => _sceneIdx = i); _newGame(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withAlpha(36) : Colors.white.withAlpha(14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? const Color(0xFFFFD93D) : Colors.white.withAlpha(30),
                  width: sel ? 2 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_scenes[i].icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(_scenes[i].name,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : Colors.white60,
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _gridArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(builder: (_, cst) {
          const gap = 6.0;
          final tile = (cst.maxWidth - gap * (_gridSize - 1)) / _gridSize;
          return _buildGrid(tile, gap);
        }),
      ),
    );
  }

  Widget _buildGrid(double tile, double gap) {
    final total    = tile * _gridSize + gap * (_gridSize - 1);
    final slidable = _neighbors(_emptyIdx).toSet();
    return SizedBox(
      width: total, height: total,
      child: Stack(children: [
        // Empty slot
        Positioned(
          left: (_emptyIdx % _gridSize) * (tile + gap),
          top:  (_emptyIdx ~/ _gridSize) * (tile + gap),
          width: tile, height: tile,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD93D).withAlpha(160), width: 2.5),
            ),
            child: Center(
              child: Text('👆', style: TextStyle(fontSize: tile * 0.32)),
            ),
          ),
        ),
        // Tiles
        ...List.generate(_tileCount, (i) {
          final tileNum  = i + 1;
          final pos      = _grid.indexOf(tileNum);
          final row      = pos ~/ _gridSize;
          final col      = pos % _gridSize;
          final emoji    = _scenes[_sceneIdx].tiles[i];
          final canSlide = slidable.contains(pos) && !_won;
          return AnimatedPositioned(
            key: ValueKey(tileNum),
            duration: const Duration(milliseconds: 155),
            curve: Curves.easeOut,
            left: col * (tile + gap),
            top:  row * (tile + gap),
            width: tile, height: tile,
            child: GestureDetector(
              onTap: () => _tap(pos),
              child: TapScale(
                onTap: () => _tap(pos),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 155),
                  decoration: BoxDecoration(
                    color: _won
                        ? const Color(0xFF51CF66).withAlpha(45)
                        : canSlide
                            ? const Color(0xFFFFD93D).withAlpha(35)
                            : Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _won
                          ? const Color(0xFF51CF66)
                          : canSlide
                              ? const Color(0xFFFFD93D)
                              : Colors.white.withAlpha(55),
                      width: canSlide ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: canSlide
                            ? const Color(0xFFFFD93D).withAlpha(80)
                            : Colors.black.withAlpha(40),
                        blurRadius: canSlide ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: TextStyle(fontSize: tile * 0.44)),
                  ),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }

  // ── Size picker (Baby / Normal) ─────────────────────────────────

  Widget _sizePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _sizeBtn('👶 Baby  2×2', 2),
        const SizedBox(width: 10),
        _sizeBtn('🧩 Normal  3×3', 3),
      ]),
    );
  }

  Widget _sizeBtn(String label, int size) {
    final sel = _gridSize == size;
    return GestureDetector(
      onTap: () {
        if (_gridSize == size) return;
        setState(() { _gridSize = size; });
        _newGame();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? Colors.white.withAlpha(36) : Colors.white.withAlpha(14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? const Color(0xFFFF9F43) : Colors.white.withAlpha(30),
            width: sel ? 2 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: sel ? const Color(0xFFFF9F43) : Colors.white60,
            )),
      ),
    );
  }

  Widget _winBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        const Text('🎉 Puzzle Solved!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF51CF66))),
        const SizedBox(height: 3),
        Text('$_moves moves  •  ${_moves <= _fastTarget ? "⚡ Amazing!" : "Well done!"}',
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(140))),
      ]),
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _newGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD93D),
            foregroundColor: const Color(0xFF0d1b2a),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/shuffle_card.png', width: 28, height: 28, fit: BoxFit.contain,
                color: const Color(0xFF0d1b2a), colorBlendMode: BlendMode.srcIn),
            const SizedBox(width: 8),
            Text(_won ? 'New Puzzle' : 'Shuffle Again',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}
