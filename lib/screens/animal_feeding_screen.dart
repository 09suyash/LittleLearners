import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/tts_service.dart';
import '../utils/app_state.dart';

enum _GameState { idle, playing, finished }

class _Food {
  final Offset pos; // fractional 0..1 within the play area
  final String label;
  final bool isTarget;
  const _Food({required this.pos, required this.label, required this.isTarget});
}

class AnimalFeedingScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AnimalFeedingScreen({super.key, required this.onBack});

  @override
  State<AnimalFeedingScreen> createState() => _AnimalFeedingScreenState();
}

class _AnimalFeedingScreenState extends State<AnimalFeedingScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final TtsService _tts = TtsService();
  final _rng = Random();

  static const _animals = ['🦖', '🐊', '🦁', '🐳', '🐘', '🦈', '🐵', '🐸'];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _slotCounts = [4, 5, 6];
  static const _timeoutSec = [8, 6, 4];
  static const _totalQ = 10;
  static const _eatRadius = 42.0;

  static const _easyLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'K', 'M', 'S', 'T'];
  static const _allLetters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];
  static const _digits = ['0','1','2','3','4','5','6','7','8','9'];
  // Deliberate lookalike decoys for Hard tier discrimination practice.
  static const _lookalikes = {
    'O': 'Q', 'Q': 'O', 'B': 'D', 'D': 'B', 'P': 'R', 'M': 'N', 'N': 'M',
    '6': '9', '9': '6', '1': '7', '7': '1',
  };

  _GameState _state = _GameState.idle;
  int _animalIdx = 0;
  int _diffIdx = 0;
  int _qIndex = 0;
  int _score = 0;
  int _bestScore = -1;
  int _bestTotal = _totalQ;

  bool _promptIsLetter = true;
  String _target = '';
  bool _locked = false;

  List<_Food> _foods = [];
  _Food? _eatingFood;
  bool _sparkle = false;
  Offset _animalPos = const Offset(0.5, 0.85);
  double _areaW = 300, _areaH = 300;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedAnimal = prefs.getString('feeding_animal');
    setState(() {
      if (savedAnimal != null) {
        final idx = _animals.indexOf(savedAnimal);
        if (idx >= 0) _animalIdx = idx;
      }
      _bestScore = prefs.getInt('feeding_best') ?? -1;
      _bestTotal = prefs.getInt('feeding_best_total') ?? _totalQ;
    });
  }

  Future<void> _saveAnimal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('feeding_animal', _animals[_animalIdx]);
  }

  Future<void> _saveBest() async {
    if (_score <= _bestScore) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('feeding_best', _score);
    await prefs.setInt('feeding_best_total', _totalQ);
    _bestScore = _score;
    _bestTotal = _totalQ;
  }

  void _startGame() {
    setState(() {
      _qIndex = 0;
      _score = 0;
      _state = _GameState.playing;
    });
    _loadPrompt();
  }

  List<Offset> _placePositions(int count) {
    final positions = <Offset>[];
    int attempts = 0;
    while (positions.length < count && attempts < 500) {
      final p = Offset(0.15 + _rng.nextDouble() * 0.7, 0.12 + _rng.nextDouble() * 0.5);
      if (positions.every((q) => (q - p).distance > 0.22)) positions.add(p);
      attempts++;
    }
    while (positions.length < count) {
      positions.add(Offset(0.15 + _rng.nextDouble() * 0.7, 0.12 + _rng.nextDouble() * 0.5));
    }
    return positions;
  }

  void _loadPrompt() {
    final isLetter = _rng.nextBool();
    final pool = isLetter ? (_diffIdx == 0 ? _easyLetters : _allLetters) : _digits;
    final target = pool[_rng.nextInt(pool.length)];
    final slotCount = _slotCounts[_diffIdx];

    final distractorPool = List<String>.from(pool)..remove(target);
    final chosen = <String>[];
    if (_diffIdx == 2) {
      final lookalike = _lookalikes[target];
      if (lookalike != null && distractorPool.contains(lookalike)) {
        chosen.add(lookalike);
        distractorPool.remove(lookalike);
      }
    }
    distractorPool.shuffle(_rng);
    while (chosen.length < slotCount - 1 && distractorPool.isNotEmpty) {
      chosen.add(distractorPool.removeLast());
    }

    final labels = [target, ...chosen]..shuffle(_rng);
    final positions = _placePositions(labels.length);

    setState(() {
      _promptIsLetter = isLetter;
      _target = target;
      _foods = [
        for (int i = 0; i < labels.length; i++)
          _Food(pos: positions[i], label: labels[i], isTarget: labels[i] == target),
      ];
      _animalPos = const Offset(0.5, 0.85);
      _eatingFood = null;
      _locked = false;
    });
    _tts.speak('Find the ${isLetter ? 'letter' : 'number'} $target');
  }

  void _onAnimalPanUpdate(DragUpdateDetails d) {
    if (_locked || _state != _GameState.playing) return;
    setState(() {
      final nx = (_animalPos.dx + d.delta.dx / _areaW).clamp(0.06, 0.94);
      final ny = (_animalPos.dy + d.delta.dy / _areaH).clamp(0.10, 0.94);
      _animalPos = Offset(nx, ny);
    });
    _checkEating();
  }

  void _checkEating() {
    if (_locked) return;
    final animalPx = Offset(_animalPos.dx * _areaW, _animalPos.dy * _areaH);
    for (final f in _foods) {
      final foodPx = Offset(f.pos.dx * _areaW, f.pos.dy * _areaH);
      if ((animalPx - foodPx).distance <= _eatRadius) {
        if (f.isTarget) _onEat(f);
        return;
      }
    }
  }

  void _onEat(_Food food) {
    setState(() {
      _locked = true;
      _eatingFood = food;
      _sparkle = true;
    });
    _sfx.play(SoundType.chomp);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _sparkle = false);
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _score++);
      _advance();
    });
  }

  void _onTimeout() {
    if (_locked || _state != _GameState.playing) return;
    _locked = true;
    _advance();
  }

  void _advance() {
    if (!mounted) return;
    if (_qIndex + 1 >= _totalQ) {
      _finish();
    } else {
      setState(() => _qIndex++);
      _loadPrompt();
    }
  }

  Future<void> _finish() async {
    await _saveBest();
    final perfect = _score == _totalQ;
    _sfx.play(perfect ? SoundType.win : SoundType.correct);
    await AppState.addStars(10);
    if (!mounted) return;
    setState(() => _state = _GameState.finished);
    await awardWithToast(context, _bs, 'feed_first');
    if (_diffIdx == 2 && perfect && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'feed_ace', stars: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0b3d2e), Color(0xFF16A085), Color(0xFF0b3d2e)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.09, child: const Text('🦖', style: TextStyle(fontSize: 140)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: _state == _GameState.finished
                    ? _buildFinishedBanner()
                    : _state == _GameState.idle
                        ? _buildStartPrompt()
                        : _buildQuestion(),
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.finished && _score == _totalQ),
      ConfettiOverlay(trigger: _state == _GameState.finished && _score == _totalQ),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () { _tts.stop(); widget.onBack(); },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Animal Feeding',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        GestureDetector(
          onTap: () {
            if (_state != _GameState.playing) {
              setState(() => _animalIdx = (_animalIdx + 1) % _animals.length);
              _saveAnimal();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(36)),
            ),
            child: Text(_animals[_animalIdx], style: const TextStyle(fontSize: 18)),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (_state != _GameState.playing) {
              setState(() => _diffIdx = (_diffIdx + 1) % 3);
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

  Widget _buildStartPrompt() {
    return Center(
      child: TapScale(
        onTap: _startGame,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF16A085), Color(0xFFF4D03F)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x4416A085), blurRadius: 18)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_animals[_animalIdx], style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            const Text('Tap to Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Drag your animal to the right letter or number!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('❓', 'Question', '${_qIndex + 1} / $_totalQ'),
          _statChip('⭐', 'Score', '$_score'),
        ]),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CountdownBar(
          key: ValueKey('feed_timer_$_qIndex'),
          seconds: _timeoutSec[_diffIdx],
          onFinish: _onTimeout,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Find the ${_promptIsLetter ? 'letter' : 'number'} "$_target"',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildPlayArea(),
        ),
      ),
    ]);
  }

  Widget _buildPlayArea() {
    return LayoutBuilder(builder: (context, c) {
      _areaW = c.maxWidth;
      _areaH = c.maxHeight;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: _areaW, height: _areaH,
          color: Colors.white.withAlpha(8),
          child: Stack(children: [
            for (final f in _foods) _buildFoodWidget(f),
            _buildAnimalWidget(),
            Positioned(
              left: _animalPos.dx * _areaW - 40,
              top: _animalPos.dy * _areaH - 40,
              width: 80, height: 80,
              child: SparkleBurst(trigger: _sparkle),
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildFoodWidget(_Food f) {
    const size = 54.0;
    final isEating = identical(f, _eatingFood);
    final targetPos = isEating ? _animalPos : f.pos;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeIn,
      left: targetPos.dx * _areaW - size / 2,
      top: targetPos.dy * _areaH - size / 2,
      child: AnimatedScale(
        scale: isEating ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
        child: AnimatedOpacity(
          opacity: isEating ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 350),
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(30),
              border: Border.all(color: Colors.white.withAlpha(80), width: 2),
            ),
            child: Center(
                child: Text(f.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalWidget() {
    const visualSize = 46.0;
    const hitSize = 72.0;
    return Positioned(
      left: _animalPos.dx * _areaW - hitSize / 2,
      top: _animalPos.dy * _areaH - hitSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: _onAnimalPanUpdate,
        child: SizedBox(
          width: hitSize, height: hitSize,
          child: Center(
            child: AnimatedScale(
              scale: _locked ? 1.35 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(_animals[_animalIdx], style: const TextStyle(fontSize: visualSize)),
            ),
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
    final perfect = _score == _totalQ;
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
            Text(perfect ? '🏆' : '🎉', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text('${_animals[_animalIdx]} ate $_score / $_totalQ correctly!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Best: $_bestScore / $_bestTotal',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
            const SizedBox(height: 4),
            const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A085),
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
            onPressed: () { _tts.stop(); widget.onBack(); },
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
