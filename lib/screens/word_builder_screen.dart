import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/tts_service.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

// (word, emoji)
const _wordList = [
  ('CAT', '🐱'), ('DOG', '🐶'), ('SUN', '☀️'), ('HEN', '🐔'),
  ('PIG', '🐷'), ('COW', '🐄'), ('ANT', '🐜'), ('BEE', '🐝'),
  ('FOX', '🦊'), ('OWL', '🦉'), ('EGG', '🥚'), ('BAT', '🦇'),
  ('FISH', '🐟'), ('FROG', '🐸'), ('KITE', '🪁'), ('LION', '🦁'),
  ('MOON', '🌙'), ('NEST', '🪺'), ('BIRD', '🐦'), ('DUCK', '🦆'),
  ('CAKE', '🎂'), ('STAR', '⭐'), ('BOAT', '⛵'), ('GOAT', '🐐'),
  ('BEAR', '🐻'), ('WOLF', '🐺'), ('SWAN', '🦢'), ('FAWN', '🦌'),
];

class WordBuilderScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WordBuilderScreen({super.key, required this.onBack});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with TickerProviderStateMixin {
  final _tts = TtsService();
  final _bs  = BadgeService();
  final _sfx = SoundService();
  final _rng = Random();

  late List<(String, String)> _session;  // 10 words for this session
  int _wIdx   = 0;
  int _score  = 0;
  bool _won   = false;          // current word complete
  bool _showResult = false;

  // Per-word state
  late List<String?> _placed;   // letters placed in slots (null = empty)
  late List<_Tile>   _tiles;    // bottom letter tiles
  int  _shakeSlot = -1;         // slot index to shake on wrong
  bool _showConfetti = false;

  // Animation for wrong-letter shake on a slot
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  // Scale pop for correct slot
  final Map<int, AnimationController> _slotCtrl = {};

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
    _buildSession();
  }

  @override
  void dispose() {
    _tts.stop();
    _shakeCtrl.dispose();
    for (final c in _slotCtrl.values) { c.dispose(); }
    super.dispose();
  }

  void _buildSession() {
    final pool = List.of(_wordList)..shuffle(_rng);
    _session = pool.take(10).toList();
    _wIdx = 0; _score = 0; _showResult = false;
    _loadWord();
  }

  void _loadWord() {
    _won = false; _shakeSlot = -1; _showConfetti = false;
    final word = _session[_wIdx].$1;
    _placed = List.filled(word.length, null);
    // Create one tile per letter, shuffled
    final chars = word.split('')..shuffle(_rng);
    _tiles = chars.asMap().entries.map((e) => _Tile(id: e.key, letter: e.value)).toList();
    // Pre-build slot pop controllers
    for (final c in _slotCtrl.values) { c.dispose(); }
    _slotCtrl.clear();
    for (int i = 0; i < word.length; i++) {
      _slotCtrl[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    }
    _tts.speak('Spell ${_session[_wIdx].$1}');
  }

  void _tapTile(_Tile tile) {
    if (_won || tile.used) return;
    // Find the first empty slot
    final slotIdx = _placed.indexWhere((c) => c == null);
    if (slotIdx < 0) return;

    final word = _session[_wIdx].$1;
    if (tile.letter == word[slotIdx]) {
      // Correct
      setState(() {
        tile.used = true;
        _placed[slotIdx] = tile.letter;
      });
      _slotCtrl[slotIdx]?.forward(from: 0);
      // Check if word complete
      if (_placed.every((c) => c != null)) {
        _onWordComplete();
      }
    } else {
      // Wrong — shake the slot
      setState(() => _shakeSlot = slotIdx);
      _shakeCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _shakeSlot = -1);
      });
      _tts.speak('Try again!');
    }
  }

  Future<void> _onWordComplete() async {
    final word = _session[_wIdx].$1;
    _score++;
    _sfx.play(SoundType.correct);
    _tts.speak('$word! Well done!');
    setState(() { _won = true; _showConfetti = true; });
    await AppState.addStars(10);
    if (!mounted) return;
    await awardWithToast(context, _bs, 'word_first');
    if (_score >= 5 && mounted)  await awardWithToast(context, _bs, 'word_5');
    if (_score >= 10 && mounted) await awardWithToast(context, _bs, 'word_10', stars: 50);
  }

  void _next() {
    if (_wIdx + 1 >= _session.length) {
      setState(() => _showResult = true);
    } else {
      setState(() { _wIdx++; _loadWord(); });
    }
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
    final (word, emoji) = _session[_wIdx];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.12, child: Image.asset('assets/images/word_card.png', width: 160, height: 160, fit: BoxFit.contain))),
        Positioned(bottom: 80, left: -10,
            child: Opacity(opacity: 0.05, child: const Text('🌟', style: TextStyle(fontSize: 100)))),
        Positioned(bottom: -10, right: -10,
            child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
        SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
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
              Image.asset('assets/images/word_card.png', width: 30, height: 30, fit: BoxFit.contain),
              const SizedBox(width: 6),
              const Expanded(child: Text('Word Builder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                child: Text('${_wIdx + 1}/10',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFD93D))),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          // Score bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _wIdx / _session.length,
                minHeight: 6,
                backgroundColor: Colors.white.withAlpha(18),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF51CF66)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Emoji + hint
          Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _tts.speak('Spell $word'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔊', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 5),
                  Text('Tap to hear', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 28),
          // Letter slots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(word.length, (i) => _buildSlot(i, word)),
          ),
          const SizedBox(height: 10),
          if (_won) ...[
            const SizedBox(height: 8),
            Text('🎉 $word!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF51CF66))),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF51CF66),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_wIdx + 1 >= _session.length ? '🏁 See Results' : 'Next Word →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ],
          const Spacer(),
          // Letter tiles
          if (!_won) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12, runSpacing: 12,
                children: _tiles.map((tile) => _buildTile(tile)).toList(),
              ),
            ),
          ],
        ]),
      ),
      ]),
    );
  }

  Widget _buildSlot(int i, String word) {
    final letter = _placed[i];
    final isCorrect = letter != null;
    final isShaking = _shakeSlot == i;
    final ctrl = _slotCtrl[i];

    Widget slot = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: word.length <= 4 ? 64 : 52,
      height: word.length <= 4 ? 64 : 52,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF51CF66).withAlpha(40) : Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? const Color(0xFF51CF66) : Colors.white.withAlpha(50),
          width: 2.5,
        ),
      ),
      child: Center(
        child: Text(
          letter ?? '',
          style: TextStyle(
            fontSize: word.length <= 4 ? 28 : 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Pop scale on correct
    if (ctrl != null) {
      slot = ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.elasticOut))
            .animate(ctrl),
        child: slot,
      );
    }

    // Shake on wrong
    if (isShaking) {
      slot = AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0), child: child),
        child: slot,
      );
    }

    return slot;
  }

  Widget _buildTile(_Tile tile) {
    return TapScale(
      onTap: tile.used ? null : () => _tapTile(tile),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: tile.used ? 0.15 : 1.0,
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: tile.used ? Colors.white.withAlpha(10) : const Color(0xFFFFD93D).withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tile.used ? Colors.white.withAlpha(20) : const Color(0xFFFFD93D),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(tile.letter,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: tile.used ? Colors.white.withAlpha(40) : Colors.white,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final pct = (_score / _session.length * 100).round();
    final stars = pct == 100 ? '⭐⭐⭐' : pct >= 70 ? '⭐⭐' : '⭐';
    final title = pct == 100 ? 'Perfect Speller!' : pct >= 70 ? 'Great Job!' : 'Keep Practising!';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
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
              Text('$_score / ${_session.length} words spelled correctly',
                  style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 14)),
              const SizedBox(height: 14),
              Text(stars, style: const TextStyle(fontSize: 32, letterSpacing: 6)),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { _tts.stop(); setState(_buildSession); },
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
                onPressed: () { _tts.stop(); widget.onBack(); },
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
}

class _Tile {
  final int id;
  final String letter;
  bool used = false;
  _Tile({required this.id, required this.letter});
}
