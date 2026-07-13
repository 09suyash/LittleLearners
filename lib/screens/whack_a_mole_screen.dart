import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

enum _GameState { idle, playing, finished }

class _MoleState {
  final bool isDecoy;
  final int poppedAtMs;
  const _MoleState({required this.isDecoy, required this.poppedAtMs});
}

class WhackAMoleScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WhackAMoleScreen({super.key, required this.onBack});

  @override
  State<WhackAMoleScreen> createState() => _WhackAMoleScreenState();
}

class _WhackAMoleScreenState extends State<WhackAMoleScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final _rng = Random();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _visibleMs = [1400, 1000, 750];
  static const _spawnMs = [900, 650, 500];
  static const _maxSimultaneous = [1, 2, 2];
  static const _decoyChance = [0.0, 1 / 6, 0.25];
  static const _targets = [10, 18, 28];
  static const _roundSeconds = 30;
  static const _holeCount = 9;
  int _diffIdx = 0;

  _GameState _state = _GameState.idle;
  final Map<int, _MoleState> _active = {};
  int _score = 0;
  int _elapsedMs = 0;
  int _lastSpawnMs = 0;
  int _bestScore = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _bestScore = prefs.getInt('whack_best_score') ?? 0);
  }

  Future<void> _saveBest() async {
    if (_score <= _bestScore) return;
    _bestScore = _score;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('whack_best_score', _bestScore);
  }

  int get _target => _targets[_diffIdx];

  void _startGame() {
    setState(() {
      _active.clear();
      _score = 0;
      _elapsedMs = 0;
      _lastSpawnMs = 0;
      _state = _GameState.playing;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsedMs += 100;
      _active.removeWhere((_, m) => _elapsedMs - m.poppedAtMs >= _visibleMs[_diffIdx]);
      if (_active.length < _maxSimultaneous[_diffIdx] &&
          _elapsedMs - _lastSpawnMs >= _spawnMs[_diffIdx]) {
        final empty = [for (int i = 0; i < _holeCount; i++) i]
            .where((i) => !_active.containsKey(i))
            .toList();
        if (empty.isNotEmpty) {
          _lastSpawnMs = _elapsedMs;
          final hole = empty[_rng.nextInt(empty.length)];
          final isDecoy = _rng.nextDouble() < _decoyChance[_diffIdx];
          _active[hole] = _MoleState(isDecoy: isDecoy, poppedAtMs: _elapsedMs);
        }
      }
    });
  }

  void _whack(int hole) {
    if (_state != _GameState.playing) return;
    final mole = _active[hole];
    if (mole == null) return;
    setState(() {
      _active.remove(hole);
      _score = (mole.isDecoy ? _score - 1 : _score + 1).clamp(0, 9999);
    });
    _sfx.play(mole.isDecoy ? SoundType.buzz : SoundType.pop);
  }

  Future<void> _endRound() async {
    _ticker?.cancel();
    await _saveBest();
    final metTarget = _score >= _target;
    _sfx.play(metTarget ? SoundType.win : SoundType.correct);
    await AppState.addStars(metTarget ? 10 : 5);
    if (!mounted) return;
    setState(() {
      _active.clear();
      _state = _GameState.finished;
    });
    if (metTarget) {
      await awardWithToast(context, _bs, 'whack_first');
    }
    if (_score >= 20 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'whack_ace', stars: 50);
    }
  }

  bool get _metTarget => _score >= _target;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF41295a), Color(0xFF2F0743)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.09, child: const Text('🔨', style: TextStyle(fontSize: 140)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: _state == _GameState.finished ? _buildFinishedBanner() : _buildGameArea(),
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.finished && _metTarget),
      ConfettiOverlay(trigger: _state == _GameState.finished && _metTarget),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () { _ticker?.cancel(); widget.onBack(); },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🔨', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Whack-a-Mole',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        GestureDetector(
          onTap: () {
            if (_state != _GameState.playing) {
              setState(() {
                _diffIdx = (_diffIdx + 1) % 3;
                _state = _GameState.idle;
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

  Widget _buildGameArea() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('⭐', 'Score', '$_score'),
          _statChip('🎯', 'Goal', '$_target'),
          _statChip('🏆', 'Best', '$_bestScore'),
        ]),
      ),
      if (_state == _GameState.playing) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CountdownBar(seconds: _roundSeconds, onFinish: _endRound),
        ),
      ],
      const SizedBox(height: 14),
      Expanded(
        child: Center(
          child: _state == _GameState.idle ? _buildStartPrompt() : _buildHoleGrid(),
        ),
      ),
    ]);
  }

  Widget _buildStartPrompt() {
    return TapScale(
      onTap: _startGame,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFCB356B), Color(0xFFBD3F32)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x44CB356B), blurRadius: 18)],
        ),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🔨', style: TextStyle(fontSize: 44)),
          SizedBox(height: 8),
          Text('Tap to Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 4),
          Text('Whack the moles, dodge the hedgehogs!',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      ),
    );
  }

  Widget _buildHoleGrid() {
    return SizedBox(
      width: 300, height: 300,
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(_holeCount, (i) => _buildHole(i)),
      ),
    );
  }

  Widget _buildHole(int i) {
    final mole = _active[i];
    return GestureDetector(
      onTap: () => _whack(i),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3d2817),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withAlpha(120), width: 3),
        ),
        child: Center(
          child: AnimatedScale(
            scale: mole == null ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Text(mole == null ? '' : (mole.isDecoy ? '🦔' : '🐹'),
                style: const TextStyle(fontSize: 34)),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

  Widget _buildFinishedBanner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _metTarget
                ? [const Color(0xFFFFD93D), const Color(0xFFFF6B6B)]
                : [Colors.white.withAlpha(30), Colors.white.withAlpha(14)]),
            borderRadius: BorderRadius.circular(20),
            border: _metTarget ? null : Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Column(children: [
            Text(_metTarget ? '🎉' : '💫', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(_metTarget ? 'Target reached!' : 'Nice whacking!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Score: $_score  •  Goal was $_target',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
            if (_metTarget) ...[
              const SizedBox(height: 4),
              const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCB356B),
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
