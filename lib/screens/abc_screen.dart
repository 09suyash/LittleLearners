import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_data.dart';
import '../models/letter_stroke_data.dart';
import '../utils/tts_service.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

class AbcScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const AbcScreen({super.key, this.onGoHome});

  @override
  State<AbcScreen> createState() => _AbcScreenState();
}

enum AbcView { grid, trace, quiz, result }

class _AbcScreenState extends State<AbcScreen> {
  final TtsService _tts = TtsService();
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final Set<int> _learned = {};
  int? _selectedIdx;
  bool _traceLowercase = false;
  AbcView _view = AbcView.grid;

  // Quiz state
  List<_QuizQuestion> _quizQs = [];
  int _qCur = 0;
  int _qScore = 0;
  int? _quizBest;
  int? _chosenIdx;
  bool _qAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final list = prefs.getStringList('abc_learned_letters') ?? [];
      for (final l in list) {
        final idx = letters.indexWhere((d) => d.letter == l);
        if (idx >= 0) _learned.add(idx);
      }
      _quizBest = prefs.getInt('abc_quiz_best');
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('abc_learned_letters', _learned.map((i) => letters[i].letter).toList());
    await prefs.setInt('abc_learned', _learned.length);
    if (_quizBest != null) await prefs.setInt('abc_quiz_best', _quizBest!);
    // Badge checks
    if (_learned.isNotEmpty && mounted)   await awardWithToast(context, _bs, 'abc_first', stars: 10);
    if (_learned.length >= 13 && mounted) await awardWithToast(context, _bs, 'abc_half', stars: 25);
    if (_learned.length >= 26 && mounted) await awardWithToast(context, _bs, 'abc_all', stars: 50);
    _checkExplorerBadge();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _openLetter(int idx) {
    _tts.stop();
    setState(() {
      _selectedIdx = idx;
      _learned.add(idx);
    });
    _savePrefs();
    Future.delayed(const Duration(milliseconds: 300), () {
      _tts.speak(letters[idx].letter, rate: 0.7, pitch: 1.3);
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LetterSheet(
        idx: _selectedIdx!,
        tts: _tts,
        onTraceUpper: () {
          Navigator.pop(context);
          setState(() {
            _traceLowercase = false;
            _view = AbcView.trace;
          });
        },
        onTraceLower: () {
          Navigator.pop(context);
          setState(() {
            _traceLowercase = true;
            _view = AbcView.trace;
          });
        },
        onNav: (dir) {
          final next = ((_selectedIdx ?? 0) + dir + 26) % 26;
          setState(() => _selectedIdx = next);
          Navigator.pop(context);
          _openLetter(next);
        },
      ),
    );
  }

  void _startQuiz() {
    final rng = Random();
    final shuffled = List.of(letters)..shuffle(rng);
    _quizQs = shuffled.take(10).map((d) {
      final wrongs = letters.where((x) => x.letter != d.letter).toList()..shuffle(rng);
      final choices = [d, wrongs[0], wrongs[1], wrongs[2]]..shuffle(rng);
      return _QuizQuestion(answer: d.letter, emoji: d.emoji, word: d.primaryWord, choices: choices.map((c) => c.letter).toList());
    }).toList();
    setState(() {
      _qCur = 0;
      _qScore = 0;
      _chosenIdx = null;
      _qAnswered = false;
      _view = AbcView.quiz;
    });
  }

  Future<void> _answerQuiz(int choiceIdx) async {
    if (_qAnswered) return;
    final correct = choiceIdx >= 0 && _quizQs[_qCur].choices[choiceIdx] == _quizQs[_qCur].answer;
    setState(() {
      _chosenIdx = choiceIdx;
      _qAnswered = true;
      if (correct) _qScore++;
    });
    if (correct) {
      _sfx.play(SoundType.correct);
      await _tts.speak('Correct! Brilliant!');
    } else if (choiceIdx >= 0) {
      _sfx.play(SoundType.wrong);
      await _tts.speak('The answer was ${_quizQs[_qCur].answer}');
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _nextQuestion();
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_qCur + 1 >= _quizQs.length) {
      _showResult();
    } else {
      setState(() {
        _qCur++;
        _chosenIdx = null;
        _qAnswered = false;
      });
    }
  }

  Future<void> _checkExplorerBadge() async {
    final p = await SharedPreferences.getInstance();
    final hasMath    = (p.getInt('math_best') ?? -1) >= 0;
    final hasStories = (p.getStringList('stories_done') ?? []).isNotEmpty;
    if (_learned.isNotEmpty && hasMath && hasStories && mounted) {
      await awardWithToast(context, _bs, 'all_apps', stars: 50);
    }
  }

  Future<void> _showResult() async {
    if (_quizBest == null || _qScore > _quizBest!) {
      _quizBest = _qScore;
      _savePrefs();
    }
    setState(() => _view = AbcView.result);
    await AppState.addStars(10);
    if (mounted && _qScore >= 5)  await awardWithToast(context, _bs, 'abc_quiz5');
    if (mounted && _qScore >= 10) await awardWithToast(context, _bs, 'abc_quiz10', stars: 50);
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_view) {
      case AbcView.trace:
        screen = _TraceScreen(
          idx: _selectedIdx ?? 0,
          initialLowercase: _traceLowercase,
          onBack: () => setState(() => _view = AbcView.grid),
        );
        break;
      case AbcView.quiz:
        screen = _QuizScreen(questions: _quizQs, current: _qCur, score: _qScore, chosenIdx: _chosenIdx, answered: _qAnswered, onAnswer: _answerQuiz, onClose: () { _tts.stop(); setState(() => _view = AbcView.grid); });
        break;
      case AbcView.result:
        screen = _ResultScreen(score: _qScore, best: _quizBest, learned: _learned.length, onHome: () { _tts.stop(); setState(() => _view = AbcView.grid); }, onRetry: () { _tts.stop(); _startQuiz(); });
        break;
      case AbcView.grid:
        screen = _buildGrid();
        break;
    }
    return Stack(children: [
      screen,
      Positioned(top: -30, right: -30, child: IgnorePointer(child: Opacity(opacity: 0.12, child: Image.asset('assets/images/abc_card.png', width: 160, height: 160, fit: BoxFit.contain)))),
      Positioned(bottom: -10, right: -10, child: IgnorePointer(child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90))))),
    ]);
  }

  Widget _buildGrid() {
    return Container(
      color: const Color(0xFF0f0c29),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  Row(children: [
                    if (widget.onGoHome != null)
                      GestureDetector(
                        onTap: () { _tts.stop(); widget.onGoHome?.call(); },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                          child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
                        ),
                      ),
                    const Spacer(),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('assets/images/abc_card.png', width: 32, height: 32, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B), Color(0xFF6BCB77), Color(0xFF4D96FF), Color(0xFFc471f5)],
                      ).createShader(b),
                      child: const Text('ABC & Phonics Pro',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text('Tap · Hear · Trace · Quiz — Learn all 26 letters!',
                      style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 12)),
                ],
              ),
            ),
            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(children: [
                _statCard('${_learned.length}/26', 'Letters Learned'),
                const SizedBox(width: 8),
                _statCard(_quizBest != null ? '$_quizBest/10' : '—', 'Quiz Best'),
                const SizedBox(width: 8),
                _statCard('⭐${_learned.length >= 26 ? 3 : _learned.length >= 13 ? 2 : _learned.length >= 5 ? 1 : 0}', 'Stars Earned'),
              ]),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _learned.length / 26,
                      minHeight: 9,
                      backgroundColor: Colors.white.withAlpha(18),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _learned.length == 26 ? '🎉 All 26 letters learned!' : _learned.length >= 13 ? '${26 - _learned.length} more to go!' : 'Tap letters to start learning!',
                    style: TextStyle(color: Colors.white.withAlpha(82), fontSize: 11),
                  ),
                ],
              ),
            ),
            // Mode tab
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withAlpha(26)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeTab('📖 Learn', true),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _startQuiz,
                    child: _modeTab('🧠 Quiz Me!', false),
                  ),
                ],
              ),
            ),
            // Letter grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 82,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                ),
                itemCount: 26,
                itemBuilder: (_, i) => _letterCard(i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String num, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Column(children: [
          Text(num, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFFFD93D))),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(102))),
        ]),
      ),
    );
  }

  Widget _modeTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: active ? const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]) : null,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.white60,
          )),
    );
  }

  Widget _letterCard(int i) {
    final d = letters[i];
    final learned = _learned.contains(i);
    return GestureDetector(
      onTap: () => _openLetter(i),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [d.color, _darken(d.color)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: learned ? Colors.white.withAlpha(140) : Colors.white.withAlpha(46),
            width: 2,
          ),
          boxShadow: [BoxShadow(color: d.color.withAlpha(107), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${d.letter}${d.letter.toLowerCase()}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Text(d.emoji, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (learned)
              Positioned(
                top: 3, right: 4,
                child: Container(
                  width: 15, height: 15,
                  decoration: BoxDecoration(color: Colors.black.withAlpha(51), shape: BoxShape.circle),
                  child: const Center(child: Text('✓', style: TextStyle(fontSize: 8, color: Colors.white))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}

// ── Letter Bottom Sheet ──
class _LetterSheet extends StatelessWidget {
  final int idx;
  final TtsService tts;
  final VoidCallback onTraceUpper;
  final VoidCallback onTraceLower;
  final void Function(int) onNav;

  const _LetterSheet({
    required this.idx,
    required this.tts,
    required this.onTraceUpper,
    required this.onTraceLower,
    required this.onNav,
  });

  @override
  Widget build(BuildContext context) {
    final d = letters[idx];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1035), Color(0xFF0f0c29)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 38, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Text(
                  '${d.letter}${d.letter.toLowerCase()}',
                  style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: d.color, height: 1),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(46)),
                  ),
                  child: Text('🔊 ${d.phonetic}', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(166))),
                ),
              ],
            ),
          ),
          // Word chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 7,
              children: d.words.map((w) {
                final emoji = wordEmojis[w] ?? '';
                return GestureDetector(
                  onTap: () => tts.speak(w),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
                    margin: const EdgeInsets.only(bottom: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withAlpha(33)),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 3),
                        Text(w, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 1),
                        Text('Tap to hear ▶', style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(97))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Trace & audio buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTraceUpper,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('🔤 Trace "${d.letter}" (Capital)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTraceLower,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFc471f5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('🔡 Trace "${d.letter.toLowerCase()}" (Small)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await tts.stop();
                      await tts.speak(d.letter, rate: 0.7, pitch: 1.3);
                      await Future.delayed(const Duration(milliseconds: 300));
                      for (final w in d.words) {
                        await tts.speak(w);
                        await Future.delayed(const Duration(milliseconds: 300));
                      }
                    },
                    icon: const Text('🔊', style: TextStyle(fontSize: 15)),
                    label: const Text('Hear All Words'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Prev / Next
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onNav(-1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text('← Prev'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onNav(1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text('Next →'),
                ),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// ── Trace Screen ──
class _TraceScreen extends StatefulWidget {
  final int idx;
  final bool initialLowercase;
  final VoidCallback onBack;
  const _TraceScreen({
    required this.idx,
    this.initialLowercase = false,
    required this.onBack,
  });

  @override
  State<_TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<_TraceScreen> with TickerProviderStateMixin {
  final SoundService _sfx = SoundService();
  final TtsService _tts = TtsService();

  late bool _isLowercase;
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  Color _penColor = const Color(0xFFFFD93D);
  bool _showPraise = false;
  bool _isError = false;
  String _hintText = '';
  Timer? _completionTimer;

  late final AnimationController _guide;
  late final AnimationController _shakeCtrl;

  static const _colors = [
    Color(0xFFFFD93D), Color(0xFFFF6B6B), Color(0xFF51CF66),
    Color(0xFF4D96FF), Color(0xFFc471f5),
  ];

  @override
  void initState() {
    super.initState();
    _isLowercase = widget.initialLowercase;
    _guide = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _updateHint();
  }

  void _updateHint() {
    final step = _strokes.length + 1;
    setState(() {
      _hintText = 'Start at glowing dot $step and follow the path!';
      _isError = false;
    });
  }

  void _switchCase(bool lowercase) {
    if (_isLowercase == lowercase) return;
    _sfx.play(SoundType.tap);
    setState(() {
      _isLowercase = lowercase;
      _strokes.clear();
      _current.clear();
      _showPraise = false;
      _completionTimer?.cancel();
    });
    _updateHint();
  }

  void _clearCanvas() {
    _sfx.play(SoundType.tap);
    setState(() {
      _strokes.clear();
      _current.clear();
      _showPraise = false;
      _completionTimer?.cancel();
    });
    _updateHint();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _guide.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = letters[widget.idx];
    final activeLetter = _isLowercase ? d.letter.toLowerCase() : d.letter.toUpperCase();

    return Container(
      color: const Color(0xFF0a0820),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(38)),
                    ),
                    child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Trace "$activeLetter"',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                // Clear button
                GestureDetector(
                  onTap: _clearCanvas,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(36)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('Reset', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            // Case switcher (Capital / Small)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(16),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchCase(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            gradient: !_isLowercase ? const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]) : null,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Center(
                            child: Text('🔤 Capital (${d.letter})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_isLowercase ? Colors.white : Colors.white60,
                                )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchCase(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            gradient: _isLowercase ? const LinearGradient(colors: [Color(0xFF6BCB77), Color(0xFF4D96FF)]) : null,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Center(
                            child: Text('🔡 Small (${d.letter.toLowerCase()})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isLowercase ? Colors.white : Colors.white60,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                        final guide = letterGuide(activeLetter, canvasSize);
                        final totalSteps = guide.length;
                        final currentStep = _strokes.length;

                        return GestureDetector(
                          onPanStart: (e) {
                            if (_showPraise || currentStep >= totalSteps) return;
                            setState(() {
                              _current = [e.localPosition];
                              _isError = false;
                            });
                          },
                          onPanUpdate: (e) {
                            if (_showPraise || currentStep >= totalSteps) return;
                            setState(() => _current.add(e.localPosition));
                          },
                          onPanEnd: (_) {
                            if (_showPraise || currentStep >= totalSteps || _current.isEmpty) return;

                            final activeMetric = guide[currentStep].computeMetrics().firstOrNull;
                            if (activeMetric == null) {
                              setState(() => _current = []);
                              return;
                            }

                            final isValid = StrokeValidator.validateStroke(
                              userPoints: _current,
                              guideMetric: activeMetric,
                              tolerance: canvasSize.width * 0.16,
                            );

                            if (isValid) {
                              _sfx.play(SoundType.pop);
                              setState(() {
                                _strokes.add(List.of(_current));
                                _current = [];
                                _isError = false;
                                if (_strokes.length >= totalSteps) {
                                  _showPraise = true;
                                  _hintText = '✨ Amazing! Letter completed! ✨';
                                  _sfx.play(SoundType.win);
                                  _tts.speak('${_isLowercase ? 'Small' : 'Capital'} ${d.letter}! ${d.primaryWord}');
                                  _completionTimer?.cancel();
                                  _completionTimer = Timer(const Duration(milliseconds: 2200), () {
                                    if (mounted) widget.onBack();
                                  });
                                } else {
                                  _hintText = 'Great job! Now trace line ${_strokes.length + 1} 👉';
                                }
                              });
                            } else {
                              _sfx.play(SoundType.wrong);
                              _shakeCtrl.forward(from: 0.0);
                              setState(() {
                                _current = [];
                                _isError = true;
                                _hintText = '⚠️ Follow line ${currentStep + 1} from the glowing dot to the end!';
                              });
                            }
                          },
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_guide, _shakeCtrl]),
                            builder: (_, _) {
                              final shakeOffset = _isError ? sin(_shakeCtrl.value * pi * 4) * 6 : 0.0;
                              return Transform.translate(
                                offset: Offset(shakeOffset, 0),
                                child: CustomPaint(
                                  painter: _TracePainter(
                                    letter: activeLetter,
                                    strokes: _strokes,
                                    current: _current,
                                    penColor: _penColor,
                                    guideProgress: _guide.value,
                                    isError: _isError,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(13),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: _isError ? const Color(0xFFFF6B6B).withAlpha(180) : Colors.white.withAlpha(31),
                                        width: _isError ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Step instruction / hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _showPraise
                      ? const Color(0xFFFFD93D)
                      : _isError
                          ? const Color(0xFFFF6B6B)
                          : Colors.white.withAlpha(200),
                ),
                child: Text(_hintText, textAlign: TextAlign.center),
              ),
            ),
            // Color picker
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._colors.map((c) => GestureDetector(
                    onTap: () => setState(() => _penColor = c),
                    child: Container(
                      width: 30, height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _penColor == c ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final String letter;
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color penColor;
  final double guideProgress; // 0.0–1.0
  final bool isError;

  _TracePainter({
    required this.letter,
    required this.strokes,
    required this.current,
    required this.penColor,
    required this.guideProgress,
    this.isError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isLower = letter == letter.toLowerCase() && letter != letter.toUpperCase();

    // 1. Ghost letter in background
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.width * (isLower ? 0.70 : 0.65),
          color: Colors.white.withAlpha(20),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));

    // 2. Guide metrics & active index
    final guide = letterGuide(letter, size);
    final metrics = [for (final p in guide) ...p.computeMetrics().take(1)];
    final activeIndex = strokes.length;

    if (metrics.isNotEmpty && activeIndex < metrics.length) {
      _paintGuideLines(canvas, metrics, activeIndex);
    }

    // 3. User completed strokes
    final paint = Paint()
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      paint.color = penColor;
      _drawStroke(canvas, s, paint);
    }

    // 4. Current in-progress stroke
    if (current.isNotEmpty) {
      paint.color = isError ? const Color(0xFFFF6B6B) : penColor;
      _drawStroke(canvas, current, paint);
    }

    // 5. Active and future step badges
    if (metrics.isNotEmpty && activeIndex < metrics.length) {
      for (int i = 0; i < metrics.length; i++) {
        if (i < activeIndex) continue; // Already completed
        final isActive = (i == activeIndex);
        _paintBadge(canvas, metrics[i], i, isActive);
      }
    }
  }

  void _paintGuideLines(Canvas canvas, List<PathMetric> metrics, int activeIndex) {
    final totalStrokes = metrics.length;
    final activeMetric = metrics[activeIndex];

    // Faint dotted path for upcoming non-active strokes
    final backgroundDotPaint = Paint()
      ..color = Colors.white.withAlpha(28)
      ..style = PaintingStyle.fill;
    for (int i = activeIndex + 1; i < totalStrokes; i++) {
      final m = metrics[i];
      double pos = 0;
      while (pos <= m.length) {
        final t = m.getTangentForOffset(pos);
        if (t != null) canvas.drawCircle(t.position, 2.5, backgroundDotPaint);
        pos += 10;
      }
    }

    // Bright dotted path for current active stroke
    final activeDotPaint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..style = PaintingStyle.fill;
    double pos = 0;
    while (pos <= activeMetric.length) {
      final t = activeMetric.getTangentForOffset(pos);
      if (t != null) canvas.drawCircle(t.position, 3.5, activeDotPaint);
      pos += 9;
    }

    // Animated glowing dot moving along the current active stroke
    final target = guideProgress * activeMetric.length;
    final t = activeMetric.getTangentForOffset(target);
    if (t != null) {
      // Outer glow
      canvas.drawCircle(t.position, 18,
          Paint()..color = const Color(0xFFFFD93D).withAlpha(45)..style = PaintingStyle.fill);
      canvas.drawCircle(t.position, 11,
          Paint()..color = const Color(0xFFFFD93D).withAlpha(110)..style = PaintingStyle.fill);
      // Bright core
      canvas.drawCircle(t.position, 5,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
  }

  void _paintBadge(Canvas canvas, PathMetric metric, int index, bool isActive) {
    final badgeTangent = metric.getTangentForOffset(0);
    if (badgeTangent == null) return;

    final center = badgeTangent.position;
    final radius = isActive ? 13.0 : 9.0;
    final bgColor = isActive
        ? (isError ? const Color(0xFFFF6B6B) : const Color(0xFFFFD93D))
        : Colors.white.withAlpha(40);
    final textColor = isActive ? const Color(0xFF1a0533) : Colors.white70;

    if (isActive) {
      // Outer glow
      canvas.drawCircle(
        center, radius + 4,
        Paint()..color = bgColor.withAlpha(60)..style = PaintingStyle.fill,
      );
    }

    // Main circle
    canvas.drawCircle(center, radius, Paint()..color = bgColor..style = PaintingStyle.fill);

    // Border
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFF1a0533).withAlpha(isActive ? 200 : 80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Number text
    final numTp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: textColor,
          fontSize: isActive ? 12 : 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numTp.paint(canvas, Offset(center.dx - numTp.width / 2, center.dy - numTp.height / 2));
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, paint.strokeWidth / 2, Paint()..color = paint.color..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}

// ── Quiz Screen ──
class _QuizScreen extends StatefulWidget {
  final List<_QuizQuestion> questions;
  final int current;
  final int score;
  final int? chosenIdx;
  final bool answered;
  final void Function(int) onAnswer;
  final VoidCallback onClose;

  const _QuizScreen({
    required this.questions, required this.current, required this.score,
    required this.chosenIdx, required this.answered,
    required this.onAnswer, required this.onClose,
  });

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  static const _totalSecs = 12.0;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(vsync: this, duration: Duration(seconds: _totalSecs.toInt()))
      ..forward();
    _timerCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.answered) {
        widget.onAnswer(-1);
      }
    });
  }

  @override
  void didUpdateWidget(_QuizScreen old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      _timerCtrl.reset();
      _timerCtrl.forward();
    }
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.current >= widget.questions.length) return const SizedBox();
    final q = widget.questions[widget.current];
    return Container(
      color: const Color(0xFF0f0c29),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(children: [
                Text('⭐ ${widget.score}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
                const Spacer(),
                Text('Q ${widget.current + 1} / ${widget.questions.length}', style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 13)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(23), shape: BoxShape.circle),
                    child: const Center(child: Text('✕', style: TextStyle(color: Colors.white60, fontSize: 14))),
                  ),
                ),
              ]),
            ),
            // Timer bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: AnimatedBuilder(
                animation: _timerCtrl,
                builder: (context, child) {
                  final pct = 1.0 - _timerCtrl.value;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.white.withAlpha(18),
                      valueColor: AlwaysStoppedAnimation(pct > 0.25 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B)),
                    ),
                  );
                },
              ),
            ),
            // Question card
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Column(
                  children: [
                    Text(q.emoji, style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 9),
                    Text('What letter does this word start with?', style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(128))),
                    const SizedBox(height: 2),
                    Text(q.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
            ),
            // Choices
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (i) {
                  final letter = q.choices[i];
                  final isCorrect = letter == q.answer;
                  final isChosen = widget.chosenIdx == i;
                  Color borderColor = Colors.white.withAlpha(26);
                  Color bgColor = Colors.white.withAlpha(15);
                  Color textColor = Colors.white;
                  if (widget.answered) {
                    if (isCorrect) {
                      borderColor = const Color(0xFF51CF66);
                      bgColor = const Color(0xFF51CF66).withAlpha(51);
                      textColor = const Color(0xFF51CF66);
                    } else if (isChosen) {
                      borderColor = const Color(0xFFFF6B6B);
                      bgColor = const Color(0xFFFF6B6B).withAlpha(51);
                      textColor = const Color(0xFFFF6B6B);
                    }
                  }
                  return GestureDetector(
                    onTap: widget.answered ? null : () => widget.onAnswer(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Center(
                        child: Text(letter, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor)),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.answered)
              Text(
                widget.chosenIdx == -1
                    ? '⏰ Time up! Answer: ${q.answer}'
                    : q.choices[widget.chosenIdx!] == q.answer
                        ? '✅ Correct! Brilliant!'
                        : '❌ The answer was ${q.answer} for ${q.word}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: (widget.chosenIdx != null && widget.chosenIdx! >= 0 && q.choices[widget.chosenIdx!] == q.answer)
                      ? const Color(0xFF51CF66)
                      : const Color(0xFFFF6B6B),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Result Screen ──
class _ResultScreen extends StatelessWidget {
  final int score;
  final int? best;
  final int learned;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  const _ResultScreen({required this.score, required this.best, required this.learned, required this.onHome, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final pct = (score / 10 * 100).round();
    final trophy = pct >= 90 ? '🏆' : pct >= 70 ? '🎉' : pct >= 50 ? '👍' : '😊';
    final title = pct >= 90 ? 'Outstanding!' : pct >= 70 ? 'Great Job!' : pct >= 50 ? 'Good Try!' : 'Keep Practicing!';
    final stars = pct >= 80 ? '⭐⭐⭐' : pct >= 50 ? '⭐⭐' : (score > 0 ? '⭐' : '☆☆☆');
    final badges = <String>[
      if (pct == 100) '💯 Perfect Score!',
      if (score >= 8) '🎓 Quiz Master',
      if (learned >= 20) '📚 Avid Learner',
      if (learned == 26) '🏅 All 26 Learned!',
    ];

    return Container(
      color: const Color(0xFF0f0c29),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withAlpha(31)),
                  ),
                  child: Column(children: [
                    Text(trophy, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 7),
                    Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('$score/10 correct in the letter quiz!', style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 13)),
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]).createShader(b),
                      child: Text('$pct%', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    Text(stars, style: const TextStyle(fontSize: 28, letterSpacing: 4)),
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: badges.map((b) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: Colors.white.withAlpha(38)),
                          ),
                          child: Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        )).toList(),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 11),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onHome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white60,
                        side: const BorderSide(color: Colors.white12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('🏠 Home'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('🔄 Try Again'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final String answer;
  final String emoji;
  final String word;
  final List<String> choices;
  const _QuizQuestion({required this.answer, required this.emoji, required this.word, required this.choices});
}
