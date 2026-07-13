import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

enum _GameState { idle, showingSequence, playerInput, won, lost }

class SimonSaysScreen extends StatefulWidget {
  final VoidCallback onBack;
  const SimonSaysScreen({super.key, required this.onBack});

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final _rng = Random();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _targets = [5, 8, 12];
  static const _flashMs = [700, 500, 350];
  static const _gapMs = [300, 220, 150];
  int _diffIdx = 0;

  static const _padColors = [
    Color(0xFFFF6B6B), // red
    Color(0xFF51CF66), // green
    Color(0xFF4D96FF), // blue
    Color(0xFFFFD93D), // yellow
  ];

  _GameState _state = _GameState.idle;
  final List<int> _sequence = [];
  final List<int> _userSeq = [];
  int _activePad = -1;
  int _lives = 3;
  int _bestRound = 0;
  int _playToken = 0;
  bool _sparkle = false;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _bestRound = prefs.getInt('simon_best_round') ?? 0);
  }

  Future<void> _saveBest() async {
    if (_sequence.length <= _bestRound) return;
    _bestRound = _sequence.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('simon_best_round', _bestRound);
  }

  int get _round => _sequence.length;
  int get _target => _targets[_diffIdx];

  void _startGame() {
    _playToken++;
    setState(() {
      _sequence.clear();
      _userSeq.clear();
      _lives = 3;
      _state = _GameState.idle;
    });
    _addRoundAndPlay();
  }

  void _addRoundAndPlay() {
    _sequence.add(_rng.nextInt(4));
    _playSequence();
  }

  Future<void> _playSequence() async {
    final token = ++_playToken;
    setState(() {
      _userSeq.clear();
      _state = _GameState.showingSequence;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    for (final pad in _sequence) {
      if (!mounted || token != _playToken) return;
      setState(() => _activePad = pad);
      _sfx.play(SoundType.tap);
      await Future.delayed(Duration(milliseconds: _flashMs[_diffIdx]));
      if (!mounted || token != _playToken) return;
      setState(() => _activePad = -1);
      await Future.delayed(Duration(milliseconds: _gapMs[_diffIdx]));
    }
    if (!mounted || token != _playToken) return;
    setState(() => _state = _GameState.playerInput);
  }

  void _onPadTap(int i) {
    if (_state != _GameState.playerInput) return;
    _sfx.play(SoundType.tap);
    setState(() => _activePad = i);
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _activePad = -1);
    });

    final idx = _userSeq.length;
    _userSeq.add(i);

    if (_sequence[idx] != i) {
      _onMistake();
      return;
    }
    if (_userSeq.length == _sequence.length) {
      if (_round >= _target) {
        _onWin();
      } else {
        _onRoundComplete();
      }
    }
  }

  void _onRoundComplete() {
    _sfx.play(SoundType.chime);
    setState(() {
      _state = _GameState.showingSequence;
      _sparkle = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _sparkle = false);
    });
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      _addRoundAndPlay();
    });
  }

  void _onMistake() {
    _sfx.play(SoundType.wrong);
    _lives--;
    if (_lives <= 0) {
      _onLost();
      return;
    }
    setState(() => _state = _GameState.showingSequence);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _playSequence();
    });
  }

  Future<void> _onLost() async {
    _playToken++;
    await _saveBest();
    setState(() => _state = _GameState.lost);
  }

  Future<void> _onWin() async {
    _playToken++;
    await _saveBest();
    _sfx.play(SoundType.win);
    await AppState.addStars(10);
    if (!mounted) return;
    setState(() => _state = _GameState.won);
    await awardWithToast(context, _bs, 'simon_first');
    if (_diffIdx == 2 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'simon_hard', stars: 50);
    }
  }

  bool get _isTerminal => _state == _GameState.won || _state == _GameState.lost;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.08, child: const Text('🎯', style: TextStyle(fontSize: 140)))),
          Positioned(bottom: -10, left: -10,
              child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: _state == _GameState.won
                    ? _buildWinBanner()
                    : _state == _GameState.lost
                        ? _buildLostBanner()
                        : _buildGame(),
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.won),
      ConfettiOverlay(trigger: _state == _GameState.won),
      SparkleBurst(trigger: _sparkle),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () { _playToken++; widget.onBack(); },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🎯', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Simon Says',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        GestureDetector(
          onTap: () {
            if (_state == _GameState.idle || _isTerminal) {
              setState(() {
                _diffIdx = (_diffIdx + 1) % 3;
                _sequence.clear();
                _userSeq.clear();
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

  Widget _buildGame() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('🔁', 'Round', _state == _GameState.idle ? '—' : '$_round / $_target'),
          _statChip('❤️', 'Lives', '$_lives'),
          _statChip('🏆', 'Best', '$_bestRound'),
        ]),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: Center(
          child: _state == _GameState.idle
              ? _buildStartPrompt()
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _state == _GameState.showingSequence ? 'Watch closely...' : 'Your turn!',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: Colors.white.withAlpha(200)),
                  ),
                  const SizedBox(height: 18),
                  _buildPadGrid(),
                  if (_diffIdx == 2 && _state == _GameState.playerInput) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 220,
                      child: CountdownBar(
                        key: ValueKey('simon_timer_${_userSeq.length}'),
                        seconds: 4,
                        onFinish: _onMistake,
                      ),
                    ),
                  ],
                ]),
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
          gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x446C5CE7), blurRadius: 18)],
        ),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎯', style: TextStyle(fontSize: 44)),
          SizedBox(height: 8),
          Text('Tap to Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 4),
          Text('Watch the pattern, then repeat it!',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      ),
    );
  }

  Widget _buildPadGrid() {
    return SizedBox(
      width: 260, height: 260,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(4, (i) {
          final lit = _activePad == i;
          return GestureDetector(
            onTap: () => _onPadTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: lit ? _padColors[i] : _padColors[i].withAlpha(90),
                borderRadius: BorderRadius.circular(20),
                boxShadow: lit
                    ? [BoxShadow(color: _padColors[i].withAlpha(180), blurRadius: 22, spreadRadius: 2)]
                    : null,
                border: Border.all(color: Colors.white.withAlpha(lit ? 220 : 40), width: 2),
              ),
            ),
          );
        }),
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

  Widget _buildWinBanner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [const BoxShadow(color: Color(0x44FFD93D), blurRadius: 20)],
          ),
          child: Column(children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text('You reached round $_round!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('${_difficulties[_diffIdx]} tier complete',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
            const SizedBox(height: 4),
            const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 20),
        _buildActions(),
      ]),
    );
  }

  Widget _buildLostBanner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Column(children: [
            const Text('💫', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text('Good try! Reached round $_round',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Best: round $_bestRound',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(150))),
          ]),
        ),
        const SizedBox(height: 20),
        _buildActions(),
      ]),
    );
  }

  Widget _buildActions() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
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
          onPressed: () { _playToken++; widget.onBack(); },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white60,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('🏠 Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}
