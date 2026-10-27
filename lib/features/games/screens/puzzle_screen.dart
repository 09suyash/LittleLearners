import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';

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

class _PuzzleScreenState extends State<PuzzleScreen> with SingleTickerProviderStateMixin {
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

  // Guide animation state
  bool _showInfoGuide = false;
  Timer? _guideTimer;
  late AnimationController _guideCtrl;
  late Animation<double> _guideBounceAnim;
  late Animation<double> _guidePulseAnim;

  int get _totalSlots => _gridSize * _gridSize;
  int get _tileCount  => _totalSlots - 1;
  int get _fastTarget => _gridSize == 2 ? 10 : 35;

  @override
  void initState() {
    super.initState();
    _newGame();

    _guideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _guideBounceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _guideCtrl, curve: Curves.easeInOut),
    );
    _guidePulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _guideCtrl, curve: Curves.easeOut),
    );

    // Always show popup of what to solve on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showGoalDialog();
      }
    });
  }

  @override
  void dispose() {
    _guideTimer?.cancel();
    _guideCtrl.dispose();
    super.dispose();
  }

  void _triggerInfoGuide() {
    _guideTimer?.cancel();
    if (mounted) {
      setState(() {
        _showInfoGuide = true;
      });
    }
    _guideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showInfoGuide = false;
        });
      }
    });
  }

  void _dismissGuide() {
    _guideTimer?.cancel();
    if (_showInfoGuide && mounted) {
      setState(() {
        _showInfoGuide = false;
      });
    }
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
    if (_showInfoGuide) _dismissGuide();
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

  // ── Goal / Tutorial dialog ──────────────────────────────────────

  void _showGoalDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF2C1654),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D).withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD93D).withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_scenes[_sceneIdx].icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '${_scenes[_sceneIdx].name} Puzzle ($_gridSize×$_gridSize)',
                        style: const TextStyle(
                          color: Color(0xFFFFD93D),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '🎯 Target Goal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arrange the tiles in this order to solve it!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF51CF66).withAlpha(150), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF51CF66).withAlpha(30),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _miniGoalGrid(),
                ),
                const SizedBox(height: 14),
                _tutStep('👆', 'How to Move',
                    'Tap any tile next to the empty box to slide it into place.'),
                const SizedBox(height: 8),
                _tutStep('ℹ️', 'Need a Reminder?',
                    'Tap the ℹ️ button at the top right anytime to view this goal again!'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _triggerInfoGuide();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD93D),
                      foregroundColor: const Color(0xFF1a0533),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text("Let's Play! 🎮",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tutStep(String icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
          const SizedBox(height: 2),
          Text(desc,
              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200), height: 1.35)),
        ])),
      ]),
    );
  }

  Widget _miniGoalGrid() {
    final emojis = _scenes[_sceneIdx].tiles;
    return LayoutBuilder(builder: (ctx, cst) {
      final gridWidth = (cst.maxWidth * 0.72).clamp(130.0, 200.0);
      return SizedBox(
        width: gridWidth,
        child: GridView.count(
          crossAxisCount: _gridSize,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (int i = 0; i < _tileCount; i++)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(35),
                      Colors.white.withAlpha(15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF51CF66), width: 1.8),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 2,
                      left: 4,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF51CF66),
                        ),
                      ),
                    ),
                    Center(child: Text(emojis[i], style: const TextStyle(fontSize: 22))),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔲', style: TextStyle(fontSize: 16)),
                    Text('Empty', style: TextStyle(fontSize: 9, color: Colors.white60, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildMain(),
      if (_showInfoGuide) _buildGuideOverlay(),
      MascotCorner(celebrating: _won),
      ConfettiOverlay(trigger: _showConfetti),
    ]);
  }

  Widget _buildGuideOverlay() {
    return Positioned(
      top: 58,
      right: 14,
      child: AnimatedBuilder(
        animation: _guideBounceAnim,
        builder: (context, child) {
          final dy = sin(_guideBounceAnim.value * 2 * pi) * 4.0;
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: () {
            _dismissGuide();
            _showGoalDialog();
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C1654), Color(0xFF4A154B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD93D), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD93D).withAlpha(90),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👆', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap ℹ️ anytime!',
                        style: TextStyle(
                          color: Color(0xFFFFD93D),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'To see target goal again',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismissGuide,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        // i- button
        _buildInfoButton(),
      ]),
    );
  }

  Widget _buildInfoButton() {
    return GestureDetector(
      onTap: () {
        _dismissGuide();
        _showGoalDialog();
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_showInfoGuide)
            AnimatedBuilder(
              animation: _guidePulseAnim,
              builder: (ctx, _) => Container(
                width: 36 + _guidePulseAnim.value * 14,
                height: 36 + _guidePulseAnim.value * 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD93D).withAlpha((255 * (1.0 - _guidePulseAnim.value)).toInt()),
                    width: 2.2,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD93D), Color(0xFFFF9F43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD93D).withAlpha(_showInfoGuide ? 180 : 80),
                  blurRadius: _showInfoGuide ? 10 : 6,
                  spreadRadius: _showInfoGuide ? 1.5 : 0,
                ),
              ],
            ),
            child: const Icon(Icons.info_rounded, color: Color(0xFF1a0533), size: 20),
          ),
        ],
      ),
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
            onTap: () {
              setState(() => _sceneIdx = i);
              _newGame();
            },
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
