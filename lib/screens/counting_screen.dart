import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/tts_service.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

const _dotEmojis = ['⭐', '🍎', '🐶', '🌈', '🎈', '🦋', '🍭', '🐸', '🌸', '🚀'];

class CountingScreen extends StatefulWidget {
  final VoidCallback onBack;
  const CountingScreen({super.key, required this.onBack});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen>
    with SingleTickerProviderStateMixin {
  final _tts = TtsService();
  final _bs  = BadgeService();
  final _sfx = SoundService();
  final _rng = Random();

  // Settings
  bool _easyMode = true;   // easy: 1-5, hard: 1-10
  int get _maxCount => _easyMode ? 5 : 10;

  // Round state
  static const _roundSize = 10;
  int _qIdx    = 0;
  int _score   = 0;
  bool _showResult = false;

  // Question state
  late int         _count;
  late String      _emoji;
  late List<int>   _choices;
  int?  _chosen;
  bool  _answered = false;
  bool  _showConfetti = false;

  // Wrong-answer shake
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
    _nextQuestion();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    _count    = _rng.nextInt(_maxCount) + 1;
    _emoji    = _dotEmojis[_rng.nextInt(_dotEmojis.length)];
    _choices  = _buildChoices(_count);
    _chosen   = null;
    _answered = false;
    _showConfetti = false;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _tts.speak('How many ${_emojiName(_emoji)} can you count?');
    });
  }

  List<int> _buildChoices(int correct) {
    final s = <int>{correct};
    int t = 0;
    while (s.length < 4 && t < 40) {
      final d = _rng.nextInt(3) + 1;
      final c = correct + (_rng.nextBool() ? d : -d);
      if (c >= 1 && c <= _maxCount + 2) s.add(c);
      t++;
    }
    for (int x = 1; s.length < 4; x++) { s.add(correct + x); }
    return (s.toList()..shuffle(_rng));
  }

  void _answer(int val) {
    if (_answered) return;
    setState(() { _chosen = val; _answered = true; });

    if (val == _count) {
      _score++;
      _sfx.play(SoundType.correct);
      setState(() => _showConfetti = true);
      // Speak feedback immediately
      _tts.speak('Yes! $_count! Amazing!');
      awardWithToast(context, _bs, 'count_first', stars: 10);
      // Advance after feedback completes
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _advance();
      });
    } else {
      _sfx.play(SoundType.wrong);
      _shakeCtrl.forward(from: 0);
      _tts.speak('Try again! Count carefully.');
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() { _chosen = null; _answered = false; _shakeCtrl.reset(); });
      });
    }
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (_qIdx + 1 >= _roundSize) {
      if (_score == _roundSize) {
        _sfx.play(SoundType.win);
        await AppState.addStars(10);
        if (mounted) await awardWithToast(context, _bs, 'count_perfect', stars: 50);
      }
      setState(() => _showResult = true);
    } else {
      setState(() { _qIdx++; _nextQuestion(); });
    }
  }

  void _restart() {
    setState(() { _qIdx = 0; _score = 0; _showResult = false; _nextQuestion(); });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResult();
    return Stack(children: [
      _buildGame(),
      ConfettiOverlay(trigger: _showConfetti),
    ]);
  }

  Widget _buildGame() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF2d1b69), Color(0xFF11998e)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildProgressBar(),
          const Spacer(),
          _buildDotGrid(),
          const Spacer(),
          _buildQuestion(),
          const SizedBox(height: 16),
          _buildChoiceButtons(),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🔢', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        const Expanded(child: Text('Counting Fun',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
        // Difficulty toggle
        GestureDetector(
          onTap: () => setState(() { _easyMode = !_easyMode; _qIdx = 0; _score = 0; _nextQuestion(); }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(36)),
            ),
            child: Text(_easyMode ? '😊 1–5' : '😎 1–10',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD93D))),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
          child: Text('⭐ $_score',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
        ),
      ]),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: _qIdx / _roundSize,
          minHeight: 6,
          backgroundColor: Colors.white.withAlpha(18),
          valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD93D)),
        ),
      ),
    );
  }

  Widget _buildDotGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10, runSpacing: 10,
        children: List.generate(_count, (i) => AnimatedScale(
          scale: 1.0,
          duration: Duration(milliseconds: 200 + i * 60),
          child: Container(
            width: _count <= 5 ? 64 : 52,
            height: _count <= 5 ? 64 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Center(child: Text(_emoji,
                style: TextStyle(fontSize: _count <= 5 ? 36 : 28))),
          ),
        )),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(children: [
      Text('How many $_emoji?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Q ${_qIdx + 1} of $_roundSize',
          style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(102))),
    ]);
  }

  Widget _buildChoiceButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_answered && _chosen != _count ? _shakeAnim.value : 0, 0),
          child: child,
        ),
        child: Row(
          children: _choices.map((val) {
            final isCorrect = val == _count;
            final isChosen  = _chosen == val;
            Color bg = Colors.white.withAlpha(18);
            Color border = Colors.white.withAlpha(36);
            if (_answered && isChosen) {
              if (isCorrect) { bg = const Color(0xFF51CF66).withAlpha(50); border = const Color(0xFF51CF66); }
              else            { bg = const Color(0xFFFF6B6B).withAlpha(50); border = const Color(0xFFFF6B6B); }
            }
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: TapScale(
                onTap: _answered ? null : () => _answer(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 68,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border, width: 2.5),
                  ),
                  child: Center(child: Text('$val',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
              ),
            ));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final pct = (_score / _roundSize * 100).round();
    final stars = pct == 100 ? '⭐⭐⭐' : pct >= 70 ? '⭐⭐' : '⭐';
    final title = pct == 100 ? 'Perfect Counter!' : pct >= 70 ? 'Great Counting!' : 'Keep Practising!';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF2d1b69), Color(0xFF11998e)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(pct == 100 ? '🏆' : '🎉', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text('$_score / $_roundSize correct',
                  style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 14)),
              const SizedBox(height: 14),
              Text(stars, style: const TextStyle(fontSize: 32, letterSpacing: 6)),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD93D),
                  foregroundColor: const Color(0xFF0d1b2a),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('🔄 Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              )),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('🏠 Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  String _emojiName(String emoji) {
    const names = {
      '⭐': 'stars', '🍎': 'apples', '🐶': 'dogs', '🌈': 'rainbows',
      '🎈': 'balloons', '🦋': 'butterflies', '🍭': 'lollipops',
      '🐸': 'frogs', '🌸': 'flowers', '🚀': 'rockets',
    };
    return names[emoji] ?? 'things';
  }
}
