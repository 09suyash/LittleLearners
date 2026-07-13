import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/maze_data.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

enum _GameState { levelSelect, playing, won }

class MazeRunnerScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MazeRunnerScreen({super.key, required this.onBack});

  @override
  State<MazeRunnerScreen> createState() => _MazeRunnerScreenState();
}

class _MazeRunnerScreenState extends State<MazeRunnerScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();

  _GameState _state = _GameState.levelSelect;
  int _mazeBestLevel = 0;
  int _endlessBest = 0;
  int? _endlessLevel; // non-null while playing/won in Endless Mode

  MazeData? _current;
  (int, int) _playerPos = (0, 0);
  Set<(int, int)> _remainingStars = {};
  int _totalStars = 0;
  int _collected = 0;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _mazeBestLevel = prefs.getInt('maze_best_level') ?? 0;
      _endlessBest = prefs.getInt('maze_endless_level') ?? 0;
    });
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maze_best_level', _mazeBestLevel);
  }

  Future<void> _saveEndlessBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maze_endless_level', _endlessBest);
  }

  (int, int) _findCell(MazeData maze, CellType type) {
    for (int r = 0; r < maze.size; r++) {
      for (int c = 0; c < maze.size; c++) {
        if (maze.grid[r][c] == type) return (r, c);
      }
    }
    return (0, 0);
  }

  Set<(int, int)> _findStars(MazeData maze) {
    final stars = <(int, int)>{};
    for (int r = 0; r < maze.size; r++) {
      for (int c = 0; c < maze.size; c++) {
        if (maze.grid[r][c] == CellType.star) stars.add((r, c));
      }
    }
    return stars;
  }

  void _selectLevel(MazeData maze) {
    final stars = _findStars(maze);
    setState(() {
      _current = maze;
      _endlessLevel = null;
      _playerPos = _findCell(maze, CellType.start);
      _remainingStars = stars;
      _totalStars = stars.length;
      _collected = 0;
      _moves = 0;
      _state = _GameState.playing;
    });
  }

  void _selectEndless(int level) {
    final maze = generateMaze(level);
    final stars = _findStars(maze);
    setState(() {
      _current = maze;
      _endlessLevel = level;
      _playerPos = _findCell(maze, CellType.start);
      _remainingStars = stars;
      _totalStars = stars.length;
      _collected = 0;
      _moves = 0;
      _state = _GameState.playing;
    });
  }

  void _tryMove(int dr, int dc) {
    if (_state != _GameState.playing || _current == null) return;
    final maze = _current!;
    final nr = _playerPos.$1 + dr;
    final nc = _playerPos.$2 + dc;
    if (nr < 0 || nc < 0 || nr >= maze.size || nc >= maze.size ||
        maze.grid[nr][nc] == CellType.wall) {
      _sfx.play(SoundType.wrong);
      return;
    }
    final cellType = maze.grid[nr][nc];
    setState(() {
      _playerPos = (nr, nc);
      _moves++;
      if (_remainingStars.remove((nr, nc))) _collected++;
    });
    _sfx.play(cellType == CellType.star ? SoundType.chime : SoundType.tick);
    if (cellType == CellType.goal) _onWin();
  }

  Future<void> _onWin() async {
    final maze = _current!;
    final endless = _endlessLevel;
    if (endless != null) {
      if (endless > _endlessBest) {
        _endlessBest = endless;
        await _saveEndlessBest();
      }
    } else if (maze.id > _mazeBestLevel) {
      _mazeBestLevel = maze.id;
      await _saveBest();
    }
    _sfx.play(SoundType.win);
    await AppState.addStars(10 + _collected * 5);
    if (!mounted) return;
    setState(() => _state = _GameState.won);
    if (endless == null && maze.id == 1) {
      await awardWithToast(context, _bs, 'maze_first');
    }
    if (endless == null && _mazeBestLevel == 6 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'maze_all', stars: 50);
    }
    if (endless != null && _endlessBest >= 5 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'maze_endless5', stars: 50);
    }
  }

  void _backToLevels() {
    setState(() {
      _state = _GameState.levelSelect;
      _current = null;
      _endlessLevel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.09, child: const Text('🗺️', style: TextStyle(fontSize: 140)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: switch (_state) {
                  _GameState.levelSelect => _buildLevelSelect(),
                  _GameState.playing => _buildPlaying(),
                  _GameState.won => _buildWonBanner(),
                },
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.won),
      ConfettiOverlay(trigger: _state == _GameState.won),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: _state == _GameState.levelSelect ? widget.onBack : _backToLevels,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🗺️', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Maze Runner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _buildLevelSelect() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('$_mazeBestLevel / 6 mazes solved',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [for (final m in mazes) _buildLevelTile(m)],
          ),
        ),
        const SizedBox(height: 12),
        _buildEndlessCard(),
      ]),
    );
  }

  Widget _buildEndlessCard() {
    final unlocked = _mazeBestLevel >= 6;
    return TapScale(
      onTap: unlocked ? () => _selectEndless(_endlessBest + 1) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: unlocked
              ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)])
              : null,
          color: unlocked ? null : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: unlocked ? null : Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Row(children: [
          Text(unlocked ? '🌀' : '🔒', style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Endless Mode',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                    color: unlocked ? Colors.white : Colors.white.withAlpha(140))),
            Text(
              unlocked
                  ? 'New maze every time · Best: level $_endlessBest'
                  : 'Solve all 6 mazes to unlock',
              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(unlocked ? 210 : 100)),
            ),
          ])),
          if (unlocked) Text('›', style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(180))),
        ]),
      ),
    );
  }

  Widget _buildLevelTile(MazeData maze) {
    final unlocked = maze.id <= _mazeBestLevel + 1;
    final solved = maze.id <= _mazeBestLevel;
    return TapScale(
      onTap: unlocked ? () => _selectLevel(maze) : null,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? Colors.white.withAlpha(30) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: solved ? const Color(0xFFFFD93D) : Colors.white.withAlpha(40), width: 2),
        ),
        child: Center(
          child: unlocked
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${maze.id}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  if (solved) const Text('✅', style: TextStyle(fontSize: 14)),
                ])
              : const Text('🔒', style: TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    final maze = _current!;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('🗺️', 'Level', _endlessLevel != null ? 'E$_endlessLevel' : '${maze.id}'),
          _statChip('👣', 'Moves', '$_moves'),
          _statChip('⭐', 'Stars', '$_collected/$_totalStars'),
        ]),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(aspectRatio: 1, child: _buildMazeGrid(maze)),
          ),
        ),
      ),
      _buildDPad(),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildMazeGrid(MazeData maze) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: maze.size),
        itemCount: maze.size * maze.size,
        itemBuilder: (_, i) {
          final r = i ~/ maze.size, c = i % maze.size;
          return _buildCell(maze, r, c);
        },
      ),
    );
  }

  Widget _buildCell(MazeData maze, int r, int c) {
    final type = maze.grid[r][c];
    final isPlayer = _playerPos == (r, c);
    final isWall = type == CellType.wall;
    final isStarHere = type == CellType.star && _remainingStars.contains((r, c));
    return Container(
      margin: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        color: isWall ? const Color(0xFF16232f) : Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: isPlayer
            ? Text(AppState.mascot, style: const TextStyle(fontSize: 14))
            : type == CellType.goal
                ? const Text('🏁', style: TextStyle(fontSize: 12))
                : isStarHere
                    ? const Text('⭐', style: TextStyle(fontSize: 11))
                    : null,
      ),
    );
  }

  Widget _buildDPad() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _dpadBtn(Icons.keyboard_arrow_up, () => _tryMove(-1, 0)),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _dpadBtn(Icons.keyboard_arrow_left, () => _tryMove(0, -1)),
        const SizedBox(width: 56),
        _dpadBtn(Icons.keyboard_arrow_right, () => _tryMove(0, 1)),
      ]),
      const SizedBox(height: 6),
      _dpadBtn(Icons.keyboard_arrow_down, () => _tryMove(1, 0)),
    ]);
  }

  Widget _dpadBtn(IconData icon, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _statChip(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(89))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _buildWonBanner() {
    final maze = _current!;
    final endless = _endlessLevel;
    final hasNext = endless != null ? true : maze.id < 6;
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
            Text(endless != null ? 'Endless level $endless solved!' : 'Maze ${maze.id} solved!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('$_moves moves • $_collected/$_totalStars stars collected',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
            const SizedBox(height: 4),
            const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 20),
        if (hasNext)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => endless != null ? _selectEndless(endless + 1) : _selectLevel(mazes[maze.id]),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CA1AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
              child: const Text('➡️ Next Maze', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => endless != null ? _selectEndless(endless) : _selectLevel(maze),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('🔄 Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _backToLevels,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('🗺️ Level Select', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
