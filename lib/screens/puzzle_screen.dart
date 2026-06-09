import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';

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
  final _rng = Random();

  int  _sceneIdx = 0;
  late List<int> _grid;   // 9 slots: value 1–8 = tile, 0 = empty
  late int _emptyIdx;
  int  _moves = 0;
  bool _won   = false;
  bool _showConfetti = false;

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
    // Start solved, make 100 random valid moves → always solvable
    _grid = List.generate(9, (i) => i < 8 ? i + 1 : 0);
    _emptyIdx = 8;
    int prev = -1;
    for (int s = 0; s < 100; s++) {
      final nbrs = _neighbors(_emptyIdx).where((n) => n != prev).toList();
      final swap = nbrs[_rng.nextInt(nbrs.length)];
      prev = _emptyIdx;
      _grid[_emptyIdx] = _grid[swap];
      _grid[swap] = 0;
      _emptyIdx = swap;
    }
  }

  List<int> _neighbors(int idx) {
    final row = idx ~/ 3, col = idx % 3;
    return [
      if (row > 0) (row - 1) * 3 + col,
      if (row < 2) (row + 1) * 3 + col,
      if (col > 0) row * 3 + col - 1,
      if (col < 2) row * 3 + col + 1,
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
    _checkWin();
  }

  void _checkWin() {
    for (int i = 0; i < 9; i++) {
      if (_grid[i] != (i < 8 ? i + 1 : 0)) return;
    }
    setState(() { _won = true; _showConfetti = true; });
    _bs.award('puzzle_first');
    if (_moves <= 35) _bs.award('puzzle_fast');
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildMain(),
      ConfettiOverlay(trigger: _showConfetti),
    ]);
  }

  Widget _buildMain() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _header(),
          const SizedBox(height: 8),
          _scenePicker(),
          Expanded(child: Center(child: _gridArea())),
          if (_won) _winBanner(),
          const SizedBox(height: 12),
          _bottomBar(),
          const SizedBox(height: 16),
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
            child: const Text('←', style: TextStyle(color: Colors.white70, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🧩', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        const Expanded(child: Text('Puzzle Pieces',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('🔀 $_moves',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
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
          final tile = (cst.maxWidth - gap * 2) / 3;
          return _buildGrid(tile, gap);
        }),
      ),
    );
  }

  Widget _buildGrid(double tile, double gap) {
    final total = tile * 3 + gap * 2;
    return SizedBox(
      width: total, height: total,
      child: Stack(children: [
        // Empty slot indicator
        Positioned(
          left: (_emptyIdx % 3) * (tile + gap),
          top:  (_emptyIdx ~/ 3) * (tile + gap),
          width: tile, height: tile,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(28), width: 2),
            ),
          ),
        ),
        // Tiles 1–8
        ...List.generate(8, (i) {
          final tileNum = i + 1;
          final pos     = _grid.indexOf(tileNum);
          final row     = pos ~/ 3;
          final col     = pos % 3;
          final emoji   = _scenes[_sceneIdx].tiles[i];
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
                        : Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _won
                          ? const Color(0xFF51CF66)
                          : Colors.white.withAlpha(55),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: TextStyle(fontSize: tile * 0.44)),
                  ),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _winBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        const Text('🎉 Puzzle Solved!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF51CF66))),
        const SizedBox(height: 3),
        Text('$_moves moves  •  ${_moves <= 35 ? "⚡ Amazing!" : "Well done!"}',
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
          child: Text(_won ? '🔄 New Puzzle' : '🔀 New Shuffle',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
