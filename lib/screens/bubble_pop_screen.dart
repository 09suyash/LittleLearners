import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

enum _GameState { idle, playing, finished }

class _Bubble {
  final int id;
  final double x; // 0..1 horizontal fraction
  final int spawnMs;
  final bool isBad;
  final String emoji;
  final Color color;
  _Bubble({required this.id, required this.x, required this.spawnMs, required this.isBad, required this.emoji, required this.color});
}

class BubblePopScreen extends StatefulWidget {
  final VoidCallback onBack;
  const BubblePopScreen({super.key, required this.onBack});

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends State<BubblePopScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final _rng = Random();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _spawnMs = [900, 600, 380];
  static const _lifetimeMs = [3800, 2800, 1900];
  static const _badChance = [0.0, 0.25, 0.4];
  static const _targets = [22, 36, 52];
  static const _roundMs = 45000;
  int _diffIdx = 0;

  static const _goodEmoji = ['🐟', '🍎', '🎈', '⭐', '🍭', '🦋', '🌸', '🍬', '🍓', '🐬'];
  static const _goodColors = [
    Color(0xFF4D96FF), Color(0xFF51CF66), Color(0xFFFFD93D),
    Color(0xFFc471f5), Color(0xFF00CEC9), Color(0xFFFF9F43),
  ];

  _GameState _state = _GameState.idle;
  final List<_Bubble> _bubbles = [];
  int _score = 0;
  int _elapsedMs = 0;
  int _lastSpawnMs = 0;
  int _nextId = 0;
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
    setState(() => _bestScore = prefs.getInt('bubble_best_score') ?? 0);
  }

  Future<void> _saveBest() async {
    if (_score <= _bestScore) return;
    _bestScore = _score;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bubble_best_score', _bestScore);
  }

  int get _target => _targets[_diffIdx];

  void _startGame() {
    setState(() {
      _bubbles.clear();
      _score = 0;
      _elapsedMs = 0;
      _lastSpawnMs = 0;
      _state = _GameState.playing;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsedMs += 50;
      _bubbles.removeWhere((b) => (_elapsedMs - b.spawnMs) / _lifetimeMs[_diffIdx] >= 1.0);
      if (_elapsedMs - _lastSpawnMs >= _spawnMs[_diffIdx]) {
        _lastSpawnMs = _elapsedMs;
        final isBad = _rng.nextDouble() < _badChance[_diffIdx];
        _bubbles.add(_Bubble(
          id: _nextId++,
          x: 0.08 + _rng.nextDouble() * 0.84,
          spawnMs: _elapsedMs,
          isBad: isBad,
          emoji: isBad ? '💣' : _goodEmoji[_rng.nextInt(_goodEmoji.length)],
          color: isBad ? const Color(0xFF636e72) : _goodColors[_rng.nextInt(_goodColors.length)],
        ));
      }
    });
  }

  void _pop(_Bubble b) {
    if (_state != _GameState.playing) return;
    setState(() {
      _bubbles.removeWhere((x) => x.id == b.id);
      _score = (b.isBad ? _score - 1 : _score + 1).clamp(0, 9999);
    });
    _sfx.play(b.isBad ? SoundType.buzz : SoundType.pop);
  }

  Future<void> _endRound() async {
    _ticker?.cancel();
    await _saveBest();
    final metTarget = _score >= _target;
    _sfx.play(metTarget ? SoundType.win : SoundType.correct);
    await AppState.addStars(metTarget ? 10 : 5);
    if (!mounted) return;
    setState(() {
      _bubbles.clear();
      _state = _GameState.finished;
    });
    if (metTarget) {
      await awardWithToast(context, _bs, 'bubble_first');
    }
    if (_score >= 45 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'bubble_ace', stars: 50);
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
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.08, child: const Text('🫧', style: TextStyle(fontSize: 140)))),
          Positioned(bottom: -10, left: -10,
              child: Opacity(opacity: 0.06, child: const Text('💧', style: TextStyle(fontSize: 90)))),
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
        const Text('🫧', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Bubble Pop',
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
          child: CountdownBar(seconds: _roundMs ~/ 1000, onFinish: _endRound),
        ),
      ],
      const SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _state == _GameState.idle ? _buildStartPrompt() : _buildBubbleField(),
        ),
      ),
    ]);
  }

  Widget _buildStartPrompt() {
    return Center(
      child: TapScale(
        onTap: _startGame,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x4400B4DB), blurRadius: 18)],
          ),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🫧', style: TextStyle(fontSize: 44)),
            SizedBox(height: 8),
            Text('Tap to Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(height: 4),
            Text('Pop the good bubbles, avoid the bombs!',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBubbleField() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: w, height: h,
          color: Colors.white.withAlpha(8),
          child: Stack(children: [
            for (final b in _bubbles)
              _buildBubbleWidget(b, w, h),
          ]),
        ),
      );
    });
  }

  Widget _buildBubbleWidget(_Bubble b, double w, double h) {
    const size = 58.0;
    final progress = ((_elapsedMs - b.spawnMs) / _lifetimeMs[_diffIdx]).clamp(0.0, 1.0);
    final y = h * (1.0 - progress) - size / 2;
    final x = w * b.x - size / 2;
    return Positioned(
      left: x.clamp(0, max(0, w - size)),
      top: y,
      child: GestureDetector(
        onTap: () => _pop(b),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: b.color.withAlpha(110),
            border: Border.all(color: b.color, width: 2),
            boxShadow: [BoxShadow(color: b.color.withAlpha(90), blurRadius: 10)],
          ),
          child: Center(child: Text(b.emoji, style: const TextStyle(fontSize: 26))),
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
            Text(_metTarget ? 'Target reached!' : 'Nice popping!',
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
              backgroundColor: const Color(0xFF00B4DB),
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
