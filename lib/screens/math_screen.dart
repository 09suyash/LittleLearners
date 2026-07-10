import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/tts_service.dart';
import '../utils/fx.dart';
import '../utils/badge_service.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

enum MathView { modeSelect, settings, quiz, blitz, result }
enum MathMode { practice, tables, blitz }
enum MathOp { add, sub, mul }
enum Difficulty { easy, med, hard }

class MathScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const MathScreen({super.key, this.onGoHome});

  @override
  State<MathScreen> createState() => _MathScreenState();
}

class _MathScreenState extends State<MathScreen> {
  final TtsService _tts = TtsService();
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  MathView _view = MathView.modeSelect;
  MathMode _mode = MathMode.practice;

  // Settings
  MathOp _op = MathOp.add;
  Difficulty _diff = Difficulty.easy;
  int _totalQ = 10;
  String _missingMode = 'no';
  int _table = 2;
  final Set<MathOp> _blitzOps = {MathOp.add, MathOp.sub, MathOp.mul};
  Difficulty _blitzDiff = Difficulty.easy;
  String _playerName = '';

  // Quiz state
  List<_MathQuestion> _questions = [];
  int _qCur = 0;
  int _score = 0;
  int _streak = 0;
  int? _chosenIdx;
  bool _answered = false;
  bool _hintUsed = false;
  int _hintElimIdx = -1;

  // Blitz state
  List<_MathQuestion> _blitzQs = [];
  int _blitzIdx = 0;
  int _blitzScore = 0;
  int _blitzTotal = 0;
  int _blitzTime = 60;
  bool _blitzAnswered = false;
  int? _blitzChosen;

  // Leaderboard
  final List<_LbEntry> _lb = [];
  String _lastMode = 'practice';
  bool _showResultConfetti = false;
  int _blitzBest = 0;

  final _rng = Random();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  // ── Question generation ──
  _MathQuestion _genQ(MathOp op, Difficulty diff, String missing) {
    final max = diff == Difficulty.easy ? 10 : diff == Difficulty.med ? 20 : 50;
    int a, b, ans;
    String sym;
    if (op == MathOp.add) {
      a = _rng.nextInt(max) + 1; b = _rng.nextInt(max) + 1; ans = a + b; sym = '+';
    } else if (op == MathOp.sub) {
      a = _rng.nextInt(max) + 2; b = _rng.nextInt(a - 1) + 1; ans = a - b; sym = '−';
    } else {
      final tm = diff == Difficulty.easy ? 5 : diff == Difficulty.med ? 10 : 12;
      a = _rng.nextInt(tm) + 1; b = _rng.nextInt(tm) + 1; ans = a * b; sym = '×';
    }
    if (missing == 'yes') {
      return _MathQuestion(display: '? $sym $b = $ans', answer: a, choices: _genChoices(a));
    }
    return _MathQuestion(display: '$a $sym $b', answer: ans, choices: _genChoices(ans));
  }

  List<int> _genChoices(int ans) {
    final s = <int>{ans};
    int t = 0;
    while (s.length < 4 && t < 60) {
      final d = _rng.nextInt(max(4, (ans.abs() * 0.4).round()) + 1) + 1;
      final c = ans + (_rng.nextBool() ? d : -d);
      if (c >= 0 && c != ans) s.add(c);
      t++;
    }
    for (int x = 1; s.length < 4; x++) {
      if (ans + x >= 0) s.add(ans + x);
    }
    return s.toList()..shuffle(_rng);
  }

  // ── Start modes ──
  void _startPractice() {
    _questions = List.generate(_totalQ, (_) => _genQ(_op, _diff, _missingMode));
    _lastMode = 'practice';
    setState(() {
      _qCur = 0; _score = 0; _streak = 0; _chosenIdx = null; _answered = false; _hintUsed = false; _hintElimIdx = -1;
      _view = MathView.quiz;
    });
    _speakQuestion();
  }

  void _startTables() {
    _questions = List.generate(10, (_) {
      final b = _rng.nextInt(12) + 1;
      return _MathQuestion(display: '$_table × $b', answer: _table * b, choices: _genChoices(_table * b));
    });
    _lastMode = 'tables';
    setState(() {
      _qCur = 0; _score = 0; _streak = 0; _chosenIdx = null; _answered = false; _hintUsed = false; _hintElimIdx = -1;
      _view = MathView.quiz;
    });
    _speakQuestion();
  }

  void _startBlitz() {
    final ops = _blitzOps.isEmpty ? [MathOp.add] : _blitzOps.toList();
    _blitzQs = List.generate(200, (_) => _genQ(ops[_rng.nextInt(ops.length)], _blitzDiff, 'no'));
    _lastMode = 'blitz';
    setState(() {
      _blitzIdx = 0; _blitzScore = 0; _blitzTotal = 0; _blitzTime = 60;
      _blitzAnswered = false; _blitzChosen = null;
      _view = MathView.blitz;
    });
  }

  void _speakQuestion() {
    if (_qCur >= _questions.length) return;
    final q = _questions[_qCur];
    final text = q.display
        .replaceAll('+', 'plus').replaceAll('−', 'minus').replaceAll('×', 'times')
        .replaceAll('?', 'something').replaceAll('=', 'equals');
    _tts.speak(_missingMode == 'yes' ? '$text — what is the missing number?' : '$text equals what?');
  }

  void _checkAnswer(int choiceIdx) {
    if (_answered) return;
    final q = _questions[_qCur];
    final choices = q.choices;
    final correct = choiceIdx >= 0 && choices[choiceIdx] == q.answer;
    setState(() {
      _chosenIdx = choiceIdx;
      _answered = true;
      if (correct) { _score++; _streak++; } else { _streak = 0; }
    });
    if (correct) {
      _sfx.play(SoundType.correct);
      if (_streak >= 5) awardWithToast(context, _bs, 'math_streak5');
    } else {
      _sfx.play(SoundType.wrong);
    }
    _tts.speak(correct ? 'Correct!' : choiceIdx < 0 ? "Time's up!" : 'The answer was ${q.answer}');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _view != MathView.quiz) return;
      if (_qCur + 1 >= _questions.length) {
        _finishQuiz();
      } else {
        setState(() { _qCur++; _chosenIdx = null; _answered = false; _hintUsed = false; _hintElimIdx = -1; });
        _speakQuestion();
      }
    });
  }

  Future<void> _finishQuiz() async {
    final pct = (_score / _questions.length * 100).round();
    _lb.add(_LbEntry(name: _playerName.isEmpty ? 'Player' : _playerName, score: _score, total: _questions.length));
    _lb.sort((a, b) => b.score - a.score);
    if (_lb.length > 5) _lb.length = 5;
    _sfx.play(SoundType.win);
    _tts.speak('Game over! You got $_score points.');
    SharedPreferences.getInstance().then((p) {
      final prev = p.getInt('math_best') ?? -1;
      if (_score > prev) {
        p.setInt('math_best', _score);
        p.setInt('math_best_total', _questions.length);
      }
    });
    setState(() { _view = MathView.result; _showResultConfetti = pct >= 60; });
    await AppState.addStars(10);
    if (!mounted) return;
    await awardWithToast(context, _bs, 'math_first');
    if (pct == 100 && mounted) await awardWithToast(context, _bs, 'math_perfect', stars: 50);
    _checkExplorerBadge();
  }

  void _checkBlitz(int choiceIdx) {
    if (_blitzAnswered) return;
    final q = _blitzQs[_blitzIdx % _blitzQs.length];
    final correct = q.choices[choiceIdx] == q.answer;
    setState(() {
      _blitzAnswered = true;
      _blitzChosen = choiceIdx;
      _blitzTotal++;
      if (correct) _blitzScore++;
    });
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() { _blitzIdx++; _blitzAnswered = false; _blitzChosen = null; });
    });
  }

  Future<void> _finishBlitz() async {
    _tts.speak("Time's up! You scored $_blitzScore points!");
    SharedPreferences.getInstance().then((p) {
      final prev = p.getInt('blitz_best') ?? -1;
      if (_blitzScore > prev) p.setInt('blitz_best', _blitzScore);
      final best = _blitzScore > prev ? _blitzScore : prev;
      if (mounted) setState(() => _blitzBest = best);
    });
    setState(() { _view = MathView.result; _showResultConfetti = _blitzScore >= 10; });
    await AppState.addStars(10);
    if (!mounted) return;
    if (_blitzScore >= 10) await awardWithToast(context, _bs, 'math_blitz10');
    if (_blitzScore >= 25 && mounted) await awardWithToast(context, _bs, 'math_blitz25', stars: 50);
  }

  Future<void> _checkExplorerBadge() async {
    final p = await SharedPreferences.getInstance();
    final hasAbc     = (p.getInt('abc_learned') ?? 0) > 0;
    final hasStories = (p.getStringList('stories_done') ?? []).isNotEmpty;
    if (hasAbc && hasStories && mounted) await awardWithToast(context, _bs, 'all_apps', stars: 50);
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_view) {
      case MathView.modeSelect: screen = _buildModeSelect(); break;
      case MathView.settings:   screen = _buildSettings();   break;
      case MathView.quiz:       screen = _buildQuiz();       break;
      case MathView.blitz:      screen = _buildBlitz();      break;
      case MathView.result:     screen = _buildResult();     break;
    }
    return Stack(children: [
      screen,
      Positioned(top: -30, right: -30, child: IgnorePointer(child: Opacity(opacity: 0.12, child: Image.asset('assets/images/math_card.png', width: 160, height: 160, fit: BoxFit.contain)))),
      Positioned(bottom: -10, right: -10, child: IgnorePointer(child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90))))),
    ]);
  }

  // ── Mode Select ──
  Widget _buildModeSelect() {
    return Container(
      color: const Color(0xFF0d1b2a),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 490),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withAlpha(18)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 60)],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  if (widget.onGoHome != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.onGoHome,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
                          ),
                          const SizedBox(width: 7),
                          Text('Home', style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  if (widget.onGoHome != null) const SizedBox(height: 14),
                  Image.asset('assets/images/math_card.png', width: 80, height: 80, fit: BoxFit.contain),
                  const SizedBox(height: 5),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]).createShader(b),
                    child: const Text('Math Quiz Pro', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  Text('Choose your challenge mode', style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 13)),
                  const SizedBox(height: 22),
                  _modeCard('🎯', 'Practice', 'Add · Subtract · Multiply · Missing Numbers · Hints', MathMode.practice, false),
                  const SizedBox(height: 10),
                  _modeCard('📊', 'Times Tables', 'Master any table from 2× to 12×', MathMode.tables, false),
                  const SizedBox(height: 10),
                  _modeCard('⚡', '⚡ Blitz! 60s', '60 seconds — answer as many as you can!', MathMode.blitz, true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(String icon, String name, String desc, MathMode mode, bool featured) {
    return GestureDetector(
      onTap: () => setState(() { _mode = mode; _view = MathView.settings; }),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(featured ? 20 : 14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: featured ? const Color(0xFFFFD93D) : Colors.white.withAlpha(26), width: 1.5),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: featured ? const Color(0xFFFFD93D) : Colors.white)),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(107))),
          ])),
          Text('›', style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(77))),
        ]),
      ),
    );
  }

  // ── Settings ──
  Widget _buildSettings() {
    final title = _mode == MathMode.practice ? '🎯 Practice Settings'
        : _mode == MathMode.tables ? '📊 Times Tables' : '⚡ Blitz Settings';
    return Container(
      color: const Color(0xFF0d1b2a),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 490),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => setState(() => _view = MathView.modeSelect),
                  child: Row(children: [
                    const Icon(Icons.arrow_back, color: Colors.white70, size: 24),
                    const SizedBox(width: 7),
                    Text('Back to Modes', style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 18),
                Center(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white))),
                const SizedBox(height: 16),
                _settingsLabel('Your Name'),
                TextField(
                  onChanged: (v) => _playerName = v,
                  maxLength: 18,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your name…',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(51)),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withAlpha(15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(26))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(26))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD93D))),
                  ),
                ),
                const SizedBox(height: 14),
                if (_mode == MathMode.practice) ...[
                  _settingsLabel('Operation'),
                  _optRow(['➕ Add', '➖ Sub', '✖️ Mul'], ['add', 'sub', 'mul'],
                      _op == MathOp.add ? 'add' : _op == MathOp.sub ? 'sub' : 'mul',
                      (v) => setState(() => _op = v == 'add' ? MathOp.add : v == 'sub' ? MathOp.sub : MathOp.mul)),
                  const SizedBox(height: 14),
                  _settingsLabel('Difficulty'),
                  _optRow(['😊 Easy', '😐 Medium', '😤 Hard'], ['easy', 'med', 'hard'],
                      _diff == Difficulty.easy ? 'easy' : _diff == Difficulty.med ? 'med' : 'hard',
                      (v) => setState(() => _diff = v == 'easy' ? Difficulty.easy : v == 'med' ? Difficulty.med : Difficulty.hard)),
                  const SizedBox(height: 14),
                  _settingsLabel('Questions'),
                  _optRow(['5 Qs', '10 Qs', '15 Qs'], ['5', '10', '15'], _totalQ.toString(),
                      (v) => setState(() => _totalQ = int.parse(v))),
                  const SizedBox(height: 14),
                  _settingsLabel('Missing Number Mode'),
                  _optRow(['Off', 'On'], ['no', 'yes'], _missingMode,
                      (v) => setState(() => _missingMode = v)),
                ],
                if (_mode == MathMode.tables) ...[
                  _settingsLabel('Choose Table to Practice'),
                  GridView.count(
                    crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 7, mainAxisSpacing: 7, childAspectRatio: 1.4,
                    children: List.generate(11, (i) {
                      final t = i + 2;
                      return GestureDetector(
                        onTap: () => setState(() => _table = t),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _table == t ? const Color(0xFFFFD93D).withAlpha(38) : Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _table == t ? const Color(0xFFFFD93D) : Colors.white.withAlpha(26), width: 1.5),
                          ),
                          child: Center(child: Text('$t×',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                                  color: _table == t ? const Color(0xFFFFD93D) : Colors.white60))),
                        ),
                      );
                    }),
                  ),
                ],
                if (_mode == MathMode.blitz) ...[
                  _settingsLabel('Difficulty'),
                  _optRow(['😊 Easy', '😐 Medium', '😤 Hard'], ['easy', 'med', 'hard'],
                      _blitzDiff == Difficulty.easy ? 'easy' : _blitzDiff == Difficulty.med ? 'med' : 'hard',
                      (v) => setState(() => _blitzDiff = v == 'easy' ? Difficulty.easy : v == 'med' ? Difficulty.med : Difficulty.hard)),
                  const SizedBox(height: 14),
                  _settingsLabel('Operations (tap to toggle)'),
                  Row(children: [
                    for (final entry in [
                      (MathOp.add, '➕ Add'), (MathOp.sub, '➖ Sub'), (MathOp.mul, '✖️ Mul'),
                    ]) ...[
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() {
                          if (_blitzOps.contains(entry.$1)) {
                            if (_blitzOps.length > 1) _blitzOps.remove(entry.$1);
                          } else {
                            _blitzOps.add(entry.$1);
                          }
                        }),
                        child: Container(
                          margin: EdgeInsets.only(right: entry.$1 != MathOp.mul ? 7 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _blitzOps.contains(entry.$1) ? const Color(0xFFFFD93D).withAlpha(33) : Colors.white.withAlpha(13),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _blitzOps.contains(entry.$1) ? const Color(0xFFFFD93D) : Colors.white.withAlpha(26),
                              width: 1.5,
                            ),
                          ),
                          child: Center(child: Text(entry.$2,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: _blitzOps.contains(entry.$1) ? const Color(0xFFFFD93D) : Colors.white60))),
                        ),
                      )),
                    ],
                  ]),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_mode == MathMode.practice) { _startPractice(); }
                      else if (_mode == MathMode.tables) { _startTables(); }
                      else { _startBlitz(); }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    child: const Text('🚀 Start!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withAlpha(115), letterSpacing: 0.7)),
    );
  }

  Widget _optRow(List<String> labels, List<String> values, String selected, void Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: List.generate(labels.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () => onSelect(values[i]),
            child: Container(
              margin: EdgeInsets.only(right: i < labels.length - 1 ? 7 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected == values[i] ? const Color(0xFFFFD93D).withAlpha(33) : Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: selected == values[i] ? const Color(0xFFFFD93D) : Colors.white.withAlpha(26), width: 1.5),
              ),
              child: Center(child: Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: selected == values[i] ? const Color(0xFFFFD93D) : Colors.white60))),
            ),
          ),
        )),
      ),
    );
  }

  // ── Practice Quiz ──
  Widget _buildQuiz() {
    if (_qCur >= _questions.length) return const SizedBox();
    final q = _questions[_qCur];
    final choices = q.choices;
    return Container(
      color: const Color(0xFF0d1b2a),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 490),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => setState(() => _view = MathView.modeSelect),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(8)),
                      child: const Text('✕', style: TextStyle(fontSize: 14, color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('⭐ $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
                  const Spacer(),
                  Text('Q ${_qCur + 1}/${_questions.length}', style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 13)),
                  if (_streak >= 3) ...[
                    const SizedBox(width: 8),
                    Text('🔥 $_streak', style: const TextStyle(color: Color(0xFF51CF66), fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ]),
                const SizedBox(height: 14),
                _TimerBar(key: ValueKey('timer_$_qCur'), onTimeout: () => _checkAnswer(-1)),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(17)),
                  child: Text(
                    _missingMode == 'yes' ? q.display : '${q.display} = ?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: (_hintUsed || _answered) ? null : () {
                      final wrongIdxs = choices.asMap().entries
                          .where((e) => e.value != q.answer)
                          .map((e) => e.key)
                          .toList()..shuffle(_rng);
                      if (wrongIdxs.isNotEmpty) {
                        setState(() { _hintUsed = true; _hintElimIdx = wrongIdxs.first; });
                      }
                    },
                    icon: const Text('💡', style: TextStyle(fontSize: 14)),
                    label: Text(_hintUsed ? 'Used' : 'Hint (1 use)',
                        style: TextStyle(color: _hintUsed ? Colors.white38 : const Color(0xFFFFD93D), fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5,
                  children: List.generate(choices.length, (i) {
                    final val = choices[i];
                    final isCorrect = val == q.answer;
                    final isChosen = _chosenIdx == i;
                    final isElim = _hintElimIdx == i;
                    Color bg = Colors.white.withAlpha(14);
                    Color border = Colors.white.withAlpha(23);
                    if (_answered) {
                      if (isCorrect) { bg = const Color(0xFF51CF66).withAlpha(46); border = const Color(0xFF51CF66); }
                      else if (isChosen) { bg = const Color(0xFFFF6B6B).withAlpha(46); border = const Color(0xFFFF6B6B); }
                    }
                    return TapScale(
                      onTap: (_answered || isElim) ? null : () => _checkAnswer(i),
                      child: Opacity(
                        opacity: isElim ? 0.22 : 1.0,
                        child: AnimatedScale(
                          scale: (_answered && isCorrect) ? 1.06 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: border, width: 2),
                            ),
                            child: Center(child: Text('$val', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                if (_answered)
                  Text(
                    _chosenIdx == -1 ? "⏰ Time's up! Answer was ${q.answer}"
                        : choices[_chosenIdx!] == q.answer ? (_streak >= 3 ? '✅ Correct! 🔥 $_streak streak!' : '✅ Correct! Brilliant!')
                        : '❌ Answer was ${q.answer}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: (_chosenIdx != null && _chosenIdx! >= 0 && choices[_chosenIdx!] == q.answer) ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Blitz ──
  Widget _buildBlitz() {
    final q = _blitzQs[_blitzIdx % _blitzQs.length];
    final choices = q.choices;
    return Container(
      color: const Color(0xFF0d1b2a),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 490),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                _BlitzTimer(
                  key: const ValueKey('blitz_timer'),
                  onTick: (remaining) => setState(() => _blitzTime = remaining),
                  onFinish: _finishBlitz,
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$_blitzTime', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('⭐ $_blitzScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('answered', style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 12)),
                    Text('$_blitzTotal', style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 14, fontWeight: FontWeight.w800)),
                  ]),
                  GestureDetector(
                    onTap: () => setState(() => _view = MathView.modeSelect),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(8)),
                      child: const Text('✕', style: TextStyle(fontSize: 14, color: Colors.white54)),
                    ),
                  ),
                ]),
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(17)),
                  child: Text(
                    '${q.display} = ?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 13),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5,
                  children: List.generate(choices.length, (i) {
                    final val = choices[i];
                    final isCorrect = val == q.answer;
                    final isChosen = _blitzChosen == i;
                    Color bg = Colors.white.withAlpha(18);
                    Color border = Colors.white.withAlpha(26);
                    if (_blitzAnswered) {
                      if (isCorrect) { bg = const Color(0xFF51CF66).withAlpha(51); border = const Color(0xFF51CF66); }
                      else if (isChosen) { bg = const Color(0xFFFF6B6B).withAlpha(51); border = const Color(0xFFFF6B6B); }
                    }
                    return TapScale(
                      onTap: _blitzAnswered ? null : () => _checkBlitz(i),
                      child: Container(
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15), border: Border.all(color: border, width: 2)),
                        child: Center(child: Text('$val', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
                      ),
                    );
                  }),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Result ──
  Widget _buildResult() {
    final isBlitz = _lastMode == 'blitz';
    final sc = isBlitz ? _blitzScore : _score;
    final tot = isBlitz ? _blitzTotal : _questions.length;
    final pct = tot > 0 ? (sc / tot * 100).round() : 0;
    final emoji = isBlitz
        ? (sc >= 25 ? '🏆' : sc >= 15 ? '🎉' : sc >= 8 ? '👍' : '😊')
        : (pct >= 90 ? '🏆' : pct >= 70 ? '🎉' : pct >= 50 ? '👍' : '😊');
    final title = isBlitz
        ? (sc >= 25 ? 'Blitz Champion!' : sc >= 15 ? 'Speed Demon!' : sc >= 8 ? 'Nice Blitz!' : 'Good Effort!')
        : (pct >= 90 ? 'Outstanding!' : pct >= 70 ? 'Great Job!' : pct >= 50 ? 'Good Try!' : 'Keep Going!');
    final stars = isBlitz
        ? (sc >= 25 ? '⭐⭐⭐' : sc >= 15 ? '⭐⭐' : '⭐')
        : (pct >= 90 ? '⭐⭐⭐' : pct >= 60 ? '⭐⭐' : '⭐');

    final badges = <String>[
      if (!isBlitz && pct == 100) '💯 Perfect Score!',
      if (!isBlitz && _streak >= 5) '🔥 Streak Master',
      if (!isBlitz && pct >= 90) '🎯 Sharpshooter',
      if (isBlitz && sc >= 30) '⚡ Lightning Fast',
      if (isBlitz && sc >= 20) '🏆 Blitz Champion',
    ];

    return Stack(children: [
      Container(
        color: const Color(0xFF0d1b2a),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 490),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withAlpha(18)),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(children: [
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(
                  isBlitz ? '${_playerName.isEmpty ? 'Player' : _playerName} • $sc correct in 60 seconds!'
                      : '${_playerName.isEmpty ? 'Player' : _playerName} • $sc/$tot correct',
                  style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(stars, style: const TextStyle(fontSize: 28, letterSpacing: 4)),
                if (isBlitz && _blitzBest > 0) ...[
                  const SizedBox(height: 4),
                  Text('🏅 Personal Best: $_blitzBest',
                      style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]).createShader(b),
                  child: Text(isBlitz ? '$sc ✓' : '$pct%',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('🏅 Badges Earned', style: TextStyle(color: Colors.white.withAlpha(89), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7, runSpacing: 7,
                    children: badges.map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(36))),
                      child: Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    )).toList(),
                  ),
                ],
                if (!isBlitz && _lb.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('🏆 Leaderboard', style: TextStyle(color: Colors.white.withAlpha(89), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                  const SizedBox(height: 7),
                  ..._lb.take(5).toList().asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Text(['🥇', '🥈', '🥉'][e.key < 3 ? e.key : 2], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 9),
                        Expanded(child: Text(e.value.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                        Text('${e.value.score}/${e.value.total}', style: const TextStyle(color: Color(0xFFFFD93D), fontWeight: FontWeight.w800, fontSize: 14)),
                      ]),
                    ),
                  )),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() => _view = MathView.modeSelect),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white60, side: const BorderSide(color: Colors.white12), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('🏠 Modes'),
                  )),
                  const SizedBox(width: 9),
                  Expanded(child: ElevatedButton(
                    onPressed: () => setState(() => _view = MathView.settings),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('🔄 Try Again'),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    ),
      ConfettiOverlay(trigger: _showResultConfetti),
    ]);
  }
}

// ── Timer bar widget for practice quiz ──
class _TimerBar extends StatefulWidget {
  final VoidCallback onTimeout;
  const _TimerBar({super.key, required this.onTimeout});

  @override
  State<_TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<_TimerBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onTimeout();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final pct = 1.0 - _ctrl.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: Colors.white.withAlpha(18),
            valueColor: AlwaysStoppedAnimation(pct > 0.25 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B)),
          ),
        );
      },
    );
  }
}

// ── Blitz countdown timer ──
class _BlitzTimer extends StatefulWidget {
  final void Function(int) onTick;
  final VoidCallback onFinish;
  const _BlitzTimer({super.key, required this.onTick, required this.onFinish});

  @override
  State<_BlitzTimer> createState() => _BlitzTimerState();
}

class _BlitzTimerState extends State<_BlitzTimer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 60))..forward();
    _ctrl.addListener(() => widget.onTick(60 - (_ctrl.value * 60).round()));
    _ctrl.addStatusListener((s) { if (s == AnimationStatus.completed) widget.onFinish(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: 1.0 - _ctrl.value,
          minHeight: 8,
          backgroundColor: Colors.white.withAlpha(18),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF51CF66)),
        ),
      ),
    );
  }
}

class _MathQuestion {
  final String display;
  final int answer;
  final List<int> choices;
  const _MathQuestion({required this.display, required this.answer, required this.choices});
}

class _LbEntry {
  final String name;
  final int score, total;
  const _LbEntry({required this.name, required this.score, required this.total});
}
