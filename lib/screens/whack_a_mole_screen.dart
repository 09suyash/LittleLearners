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
  final bool isHit;
  final int? hitAtMs;
  final String hitText;
  final Color hitColor;

  const _MoleState({
    required this.isDecoy,
    required this.poppedAtMs,
    this.isHit = false,
    this.hitAtMs,
    this.hitText = '',
    this.hitColor = const Color(0xFFFFD93D),
  });

  _MoleState copyWith({
    bool? isDecoy,
    int? poppedAtMs,
    bool? isHit,
    int? hitAtMs,
    String? hitText,
    Color? hitColor,
  }) {
    return _MoleState(
      isDecoy: isDecoy ?? this.isDecoy,
      poppedAtMs: poppedAtMs ?? this.poppedAtMs,
      isHit: isHit ?? this.isHit,
      hitAtMs: hitAtMs ?? this.hitAtMs,
      hitText: hitText ?? this.hitText,
      hitColor: hitColor ?? this.hitColor,
    );
  }
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
  static const _hitAnimMs = 550;

  int _diffIdx = 0;

  _GameState _state = _GameState.idle;
  final Map<int, _MoleState> _active = {};
  int _score = 0;
  int _elapsedMs = 0;
  int _lastSpawnMs = 0;
  int _bestScore = 0;
  bool _sparkle = false;
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
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsedMs += 50;

      // Clean up expired moles
      _active.removeWhere((_, m) {
        if (m.isHit) {
          return (m.hitAtMs != null && (_elapsedMs - m.hitAtMs! >= _hitAnimMs));
        }
        return _elapsedMs - m.poppedAtMs >= _visibleMs[_diffIdx];
      });

      // Spawn new mole if slots available
      final unhitCount = _active.values.where((m) => !m.isHit).length;
      if (unhitCount < _maxSimultaneous[_diffIdx] &&
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
    if (mole == null || mole.isHit) return;

    final isDecoy = mole.isDecoy;
    final hitTexts = isDecoy
        ? ['OUCH! 💢', 'NOPE! ❌', 'OUCH! 🦔']
        : ['POW! 💥', 'BAM! ⭐', 'WHACK! 💫', 'SMASH! 🔨', '+1 ⭐', 'BOOM! 💥'];
    final hitText = hitTexts[_rng.nextInt(hitTexts.length)];
    final hitColor = isDecoy ? const Color(0xFFFF4757) : const Color(0xFFFFD93D);

    setState(() {
      _active[hole] = mole.copyWith(
        isHit: true,
        hitAtMs: _elapsedMs,
        hitText: hitText,
        hitColor: hitColor,
      );
      _score = (isDecoy ? _score - 1 : _score + 1).clamp(0, 9999);
      if (!isDecoy) _sparkle = true;
    });

    _sfx.play(isDecoy ? SoundType.buzz : SoundType.pop);
    if (!isDecoy) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _sparkle = false);
      });
    }
  }

  Future<void> _endRound() async {
    _ticker?.cancel();
    await _saveBest();
    final metTarget = _score >= _target;
    final pct = _target > 0 ? ((_score / _target) * 100).round() : 0;
    final starsEarned = pct >= 100 ? 10 : (pct >= 50 ? 5 : (_score > 0 ? 2 : 0));

    _sfx.play(metTarget ? SoundType.win : (_score > 0 ? SoundType.correct : SoundType.wrong));
    if (starsEarned > 0) {
      await AppState.addStars(starsEarned);
    }

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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1654), Color(0xFF160829)],
          ),
        ),
        child: Stack(children: [
          Positioned(
            top: -20,
            right: -20,
            child: Opacity(
              opacity: 0.07,
              child: const Text('🔨', style: TextStyle(fontSize: 160)),
            ),
          ),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: _state == _GameState.finished
                    ? _buildFinishedBanner()
                    : _buildGameArea(),
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.finished && _metTarget),
      ConfettiOverlay(trigger: _state == _GameState.finished && _metTarget),
      SparkleBurst(trigger: _sparkle),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            _ticker?.cancel();
            widget.onBack();
          },
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
        const Text('🔨', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Whack-a-Mole',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
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
            child: Text(
              _difficulties[_diffIdx],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFD93D),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildGameArea() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statChip('⭐', 'Score', '$_score'),
            _statChip('🎯', 'Goal', '$_target'),
            _statChip('🏆', 'Best', '$_bestScore'),
          ],
        ),
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
          child: _state == _GameState.idle
              ? _buildStartPrompt()
              : _buildHoleGrid(),
        ),
      ),
    ]);
  }

  Widget _buildStartPrompt() {
    return TapScale(
      onTap: _startGame,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E62).withAlpha(100),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🔨', style: TextStyle(fontSize: 48)),
          SizedBox(height: 10),
          Text(
            'Tap to Start!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Whack the moles 🐹, dodge hedgehogs 🦔!',
            style: TextStyle(fontSize: 13, color: Colors.white),
          ),
        ]),
      ),
    );
  }

  Widget _buildHoleGrid() {
    return SizedBox(
      width: 320,
      height: 320,
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(_holeCount, (i) {
          return _HoleCell(
            key: ValueKey('hole_$i'),
            mole: _active[i],
            onTap: () => _whack(i),
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
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(89)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildFinishedBanner() {
    final pct = _target > 0 ? ((_score / _target) * 100).round() : 0;
    final stars = pct >= 80
        ? '⭐⭐⭐'
        : pct >= 50
            ? '⭐⭐'
            : (_score > 0 ? '⭐' : '☆☆☆');
    final emoji = pct >= 100
        ? '🏆'
        : pct >= 80
            ? '🎉'
            : (pct >= 50 ? '👍' : (_score > 0 ? '💫' : '😢'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _metTarget
                  ? [const Color(0xFFFFD93D), const Color(0xFFFF6B6B)]
                  : [Colors.white.withAlpha(30), Colors.white.withAlpha(14)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: _metTarget
                ? null
                : Border.all(color: Colors.white.withAlpha(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            Text(
              _metTarget ? 'Target reached!' : 'Nice whacking!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Score: $_score  •  Goal was $_target',
              style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(220)),
            ),
            const SizedBox(height: 8),
            Text(stars, style: const TextStyle(fontSize: 26, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5E62),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            child: const Text(
              '🔄 Play Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '🏠 Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Rich animated hole cell with dizzy spinning stars, hammer smack, and smash text particles.
class _HoleCell extends StatefulWidget {
  final _MoleState? mole;
  final VoidCallback onTap;

  const _HoleCell({
    super.key,
    required this.mole,
    required this.onTap,
  });

  @override
  State<_HoleCell> createState() => _HoleCellState();
}

class _HoleCellState extends State<_HoleCell> with TickerProviderStateMixin {
  late AnimationController _dizzyStarCtrl;
  late AnimationController _hitFxCtrl;
  late AnimationController _wobbleCtrl;

  @override
  void initState() {
    super.initState();
    _dizzyStarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    _hitFxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.mole?.isHit == true) {
      _triggerHitFx();
    }
  }

  @override
  void didUpdateWidget(_HoleCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasHit = oldWidget.mole?.isHit ?? false;
    final isHit = widget.mole?.isHit ?? false;

    if (!wasHit && isHit) {
      _triggerHitFx();
    } else if (widget.mole == null) {
      _hitFxCtrl.reset();
      _wobbleCtrl.reset();
    }
  }

  void _triggerHitFx() {
    _hitFxCtrl.forward(from: 0.0);
    _wobbleCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _dizzyStarCtrl.dispose();
    _hitFxCtrl.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mole = widget.mole;
    final isPresent = mole != null;
    final isHit = mole?.isHit ?? false;
    final isDecoy = mole?.isDecoy ?? false;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Hole Mound / 3D Dirt Pit ────────────────────────
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 0.85,
                colors: [
                  Color(0xFF1B0F07),
                  Color(0xFF2E1A0F),
                  Color(0xFF4A2818),
                ],
                stops: [0.45, 0.75, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF6E3C1E).withAlpha(100),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: isHit
                    ? (isDecoy ? const Color(0xFFFF4757) : const Color(0xFFFFD93D))
                    : const Color(0xFF5D3820),
                width: isHit ? 3.0 : 2.5,
              ),
            ),
          ),

          // ── Mole Inside Hole ────────────────────────────────
          if (isPresent)
            AnimatedBuilder(
              animation: Listenable.merge([_wobbleCtrl, _hitFxCtrl]),
              builder: (context, child) {
                double scaleX = 1.0;
                double scaleY = 1.0;
                double shakeOffsetX = 0.0;
                double shakeOffsetY = 0.0;

                if (isHit) {
                  final t = _hitFxCtrl.value;
                  // Squish & recoil
                  if (t < 0.3) {
                    final squish = sin(t / 0.3 * pi);
                    scaleX = 1.0 + squish * 0.35;
                    scaleY = 1.0 - squish * 0.45;
                  } else {
                    final shrink = (1.0 - (t - 0.3) / 0.7).clamp(0.0, 1.0);
                    scaleX = shrink;
                    scaleY = shrink;
                  }
                  // Rapid dizzy vibration
                  shakeOffsetX = sin(_wobbleCtrl.value * pi * 8) * (1 - t) * 6;
                  shakeOffsetY = cos(_wobbleCtrl.value * pi * 6) * (1 - t) * 3;
                }

                String emoji;
                if (!isHit) {
                  emoji = isDecoy ? '🦔' : '🐹';
                } else {
                  emoji = isDecoy ? '😱' : '😵‍💫';
                }

                return Transform.translate(
                  offset: Offset(shakeOffsetX, shakeOffsetY),
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Mole Character
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 44),
                          ),

                          // Dizzy Orbiting Stars around Mole Head ("Chakkar")
                          if (isHit && !isDecoy)
                            AnimatedBuilder(
                              animation: _dizzyStarCtrl,
                              builder: (context, _) {
                                final angle = _dizzyStarCtrl.value * 2 * pi;
                                final radius = 26.0;
                                return SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Star 1
                                      Transform.translate(
                                        offset: Offset(
                                          cos(angle) * radius,
                                          sin(angle) * (radius * 0.45) - 22,
                                        ),
                                        child: const Text('💫', style: TextStyle(fontSize: 16)),
                                      ),
                                      // Star 2
                                      Transform.translate(
                                        offset: Offset(
                                          cos(angle + pi) * radius,
                                          sin(angle + pi) * (radius * 0.45) - 22,
                                        ),
                                        child: const Text('⭐', style: TextStyle(fontSize: 14)),
                                      ),
                                      // Star 3
                                      Transform.translate(
                                        offset: Offset(
                                          cos(angle + pi / 2) * radius,
                                          sin(angle + pi / 2) * (radius * 0.45) - 22,
                                        ),
                                        child: const Text('✨', style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Decoy Angry Sparks
                          if (isHit && isDecoy)
                            Positioned(
                              top: -18,
                              child: Text(
                                '💢⚡',
                                style: TextStyle(
                                  fontSize: 18,
                                  shadows: [
                                    Shadow(
                                      color: Colors.red.withAlpha(200),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── Whack Hammer Strike Animation ──────────────────
          if (isHit)
            AnimatedBuilder(
              animation: _hitFxCtrl,
              builder: (context, child) {
                final t = _hitFxCtrl.value;
                if (t > 0.4) return const SizedBox.shrink();

                // Hammer swing: drops in from top-right and smashes down
                final swingT = (t / 0.4).clamp(0.0, 1.0);
                final rotation = -0.6 + swingT * 0.7; // swings down
                final offsetY = -35 + swingT * 25;
                final opacity = (1.0 - swingT * 0.5).clamp(0.0, 1.0);

                return Positioned(
                  top: offsetY,
                  right: -4,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: rotation,
                      child: const Text('🔨', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                );
              },
            ),

          // ── Impact Comic Burst & Particles ("Tootne footne wala UI") ──
          if (isHit)
            AnimatedBuilder(
              animation: _hitFxCtrl,
              builder: (context, _) {
                final t = _hitFxCtrl.value;
                final burstOpacity = (1.0 - t).clamp(0.0, 1.0);
                final burstScale = 0.5 + t * 0.8;
                final floatUp = -t * 40;

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Impact explosion starburst sparks
                    for (int i = 0; i < 6; i++)
                      Transform.translate(
                        offset: Offset(
                          cos(i * pi / 3) * (20 + t * 45),
                          sin(i * pi / 3) * (20 + t * 45),
                        ),
                        child: Opacity(
                          opacity: burstOpacity,
                          child: Text(
                            isDecoy ? '💥' : (i % 2 == 0 ? '💥' : '⭐'),
                            style: TextStyle(fontSize: 14 - t * 6),
                          ),
                        ),
                      ),

                    // Comic Pop-Up Banner (e.g. "POW! 💥", "BAM! ⭐", "WHACK! 💫")
                    Transform.translate(
                      offset: Offset(0, floatUp - 12),
                      child: Opacity(
                        opacity: burstOpacity,
                        child: Transform.scale(
                          scale: burstScale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDecoy
                                    ? [const Color(0xFFFF4757), const Color(0xFFFF6B81)]
                                    : [const Color(0xFFFFE600), const Color(0xFFFF9F1A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(120),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              mole?.hitText.isNotEmpty == true
                                  ? mole!.hitText
                                  : (isDecoy ? 'OUCH! 💢' : 'POW! 💥'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDecoy ? Colors.white : const Color(0xFF5A2A00),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

