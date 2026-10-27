import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/math_models.dart';
import '../widgets/math_mode_select_view.dart';
import '../widgets/math_settings_view.dart';
import '../widgets/math_quiz_view.dart';
import '../widgets/math_blitz_view.dart';
import '../widgets/math_result_view.dart';

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
  final String _playerName = '';

  // Quiz state
  List<MathQuestion> _questions = [];
  int _qCur = 0;
  int _score = 0;
  int _streak = 0;
  int? _chosenIdx;
  bool _answered = false;
  bool _hintUsed = false;
  int _hintElimIdx = -1;

  // Blitz state
  List<MathQuestion> _blitzQs = [];
  int _blitzIdx = 0;
  int _blitzScore = 0;
  int _blitzTotal = 0;
  int _blitzTime = 60;
  bool _blitzAnswered = false;
  int? _blitzChosen;

  // Leaderboard
  final List<MathLeaderboardEntry> _lb = [];
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
  MathQuestion _genQ(MathOp op, Difficulty diff, String missing) {
    final maxVal =
        diff == Difficulty.easy ? 10 : diff == Difficulty.med ? 20 : 50;
    int a, b, ans;
    String sym;
    if (op == MathOp.add) {
      a = _rng.nextInt(maxVal) + 1;
      b = _rng.nextInt(maxVal) + 1;
      ans = a + b;
      sym = '+';
    } else if (op == MathOp.sub) {
      a = _rng.nextInt(maxVal) + 2;
      b = _rng.nextInt(a - 1) + 1;
      ans = a - b;
      sym = '−';
    } else {
      final tm =
          diff == Difficulty.easy ? 5 : diff == Difficulty.med ? 10 : 12;
      a = _rng.nextInt(tm) + 1;
      b = _rng.nextInt(tm) + 1;
      ans = a * b;
      sym = '×';
    }
    if (missing == 'yes') {
      return MathQuestion(
        display: '? $sym $b = $ans',
        answer: a,
        choices: _genChoices(a),
      );
    }
    return MathQuestion(
      display: '$a $sym $b',
      answer: ans,
      choices: _genChoices(ans),
    );
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

  List<MathQuestion> _genUniqueQuestions(
    int count,
    MathOp op,
    Difficulty diff,
    String missing,
  ) {
    final seen = <String>{};
    final list = <MathQuestion>[];
    int attempts = 0;
    while (list.length < count && attempts < count * 40) {
      final q = _genQ(op, diff, missing);
      attempts++;
      if (seen.add(q.display)) list.add(q);
    }
    while (list.length < count) {
      list.add(_genQ(op, diff, missing));
    }
    return list;
  }

  // ── Start modes ──
  void _startPractice() {
    _questions = _genUniqueQuestions(_totalQ, _op, _diff, _missingMode);
    _lastMode = 'practice';
    setState(() {
      _qCur = 0;
      _score = 0;
      _streak = 0;
      _chosenIdx = null;
      _answered = false;
      _hintUsed = false;
      _hintElimIdx = -1;
      _view = MathView.quiz;
    });
    _speakQuestion();
  }

  void _startTables() {
    final multipliers = List.generate(12, (i) => i + 1)..shuffle(_rng);
    _questions = multipliers
        .take(10)
        .map(
          (b) => MathQuestion(
            display: '$_table × $b',
            answer: _table * b,
            choices: _genChoices(_table * b),
          ),
        )
        .toList();
    _lastMode = 'tables';
    setState(() {
      _qCur = 0;
      _score = 0;
      _streak = 0;
      _chosenIdx = null;
      _answered = false;
      _hintUsed = false;
      _hintElimIdx = -1;
      _view = MathView.quiz;
    });
    _speakQuestion();
  }

  void _startBlitz() {
    final ops = _blitzOps.isEmpty ? [MathOp.add] : _blitzOps.toList();
    _blitzQs = List.generate(
      200,
      (_) => _genQ(ops[_rng.nextInt(ops.length)], _blitzDiff, 'no'),
    );
    _lastMode = 'blitz';
    setState(() {
      _blitzIdx = 0;
      _blitzScore = 0;
      _blitzTotal = 0;
      _blitzTime = 60;
      _blitzAnswered = false;
      _blitzChosen = null;
      _view = MathView.blitz;
    });
  }

  void _speakQuestion() {
    if (_qCur >= _questions.length) return;
    final q = _questions[_qCur];
    final text = q.display
        .replaceAll('+', 'plus')
        .replaceAll('−', 'minus')
        .replaceAll('×', 'times')
        .replaceAll('?', 'something')
        .replaceAll('=', 'equals');
    _tts.speak(
      _missingMode == 'yes'
          ? '$text — what is the missing number?'
          : '$text equals what?',
    );
  }

  Future<void> _checkAnswer(int choiceIdx) async {
    if (_answered) return;
    final q = _questions[_qCur];
    final choices = q.choices;
    final correct = choiceIdx >= 0 && choices[choiceIdx] == q.answer;
    setState(() {
      _chosenIdx = choiceIdx;
      _answered = true;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
    if (correct) {
      _sfx.play(SoundType.correct);
      if (_streak >= 5) await awardWithToast(context, _bs, 'math_streak5');
    } else {
      _sfx.play(SoundType.wrong);
    }
    await _tts.speak(
      correct
          ? 'Correct!'
          : choiceIdx < 0
              ? "Time's up!"
              : 'The answer was ${q.answer}',
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _view != MathView.quiz) return;
    if (_qCur + 1 >= _questions.length) {
      await _finishQuiz();
    } else {
      setState(() {
        _qCur++;
        _chosenIdx = null;
        _answered = false;
        _hintUsed = false;
        _hintElimIdx = -1;
      });
      _speakQuestion();
    }
  }

  Future<void> _finishQuiz() async {
    final pct = (_score / _questions.length * 100).round();
    _lb.add(
      MathLeaderboardEntry(
        name: _playerName.isEmpty ? 'Player' : _playerName,
        score: _score,
        total: _questions.length,
      ),
    );
    _lb.sort((a, b) => b.score - a.score);
    if (_lb.length > 5) _lb.length = 5;
    _sfx.play(SoundType.win);
    _tts.speak('Game over! You got $_score points.');
    ProgressRepository().saveMathScore(
      score: _score,
      total: _questions.length,
    );
    setState(() {
      _view = MathView.result;
      _showResultConfetti = pct >= 60;
    });
    await AppState.addStars(10);
    if (!mounted) return;
    await awardWithToast(context, _bs, 'math_first');
    if (pct == 100 && mounted) {
      await awardWithToast(context, _bs, 'math_perfect', stars: 50);
    }
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
      setState(() {
        _blitzIdx++;
        _blitzAnswered = false;
        _blitzChosen = null;
      });
    });
  }

  Future<void> _finishBlitz() async {
    _tts.speak("Time's up! You scored $_blitzScore points!");
    final best = await ProgressRepository().saveBlitzScore(_blitzScore);
    if (mounted) setState(() => _blitzBest = best);
    setState(() {
      _view = MathView.result;
      _showResultConfetti = _blitzScore >= 10;
    });
    await AppState.addStars(10);
    if (!mounted) return;
    if (_blitzScore >= 10) await awardWithToast(context, _bs, 'math_blitz10');
    if (_blitzScore >= 25 && mounted) {
      await awardWithToast(context, _bs, 'math_blitz25', stars: 50);
    }
  }

  Future<void> _checkExplorerBadge() async {
    final hasAll = await ProgressRepository().hasExploredAllApps();
    if (hasAll && mounted) {
      await awardWithToast(context, _bs, 'all_apps', stars: 50);
    }
  }

  void _useHint() {
    final q = _questions[_qCur];
    final choices = q.choices;
    final wrongIdxs = choices
        .asMap()
        .entries
        .where((e) => e.value != q.answer)
        .map((e) => e.key)
        .toList()
      ..shuffle(_rng);
    if (wrongIdxs.isNotEmpty) {
      setState(() {
        _hintUsed = true;
        _hintElimIdx = wrongIdxs.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_view) {
      case MathView.modeSelect:
        screen = MathModeSelectView(
          onGoHome: widget.onGoHome != null
              ? () {
                  _tts.stop();
                  widget.onGoHome?.call();
                }
              : null,
          onSelectMode: (mode) {
            setState(() {
              _mode = mode;
              _view = MathView.settings;
            });
          },
        );
        break;
      case MathView.settings:
        screen = MathSettingsView(
          mode: _mode,
          op: _op,
          onOpChanged: (op) => setState(() => _op = op),
          diff: _diff,
          onDiffChanged: (diff) => setState(() => _diff = diff),
          totalQ: _totalQ,
          onTotalQChanged: (q) => setState(() => _totalQ = q),
          missingMode: _missingMode,
          onMissingModeChanged: (m) => setState(() => _missingMode = m),
          table: _table,
          onTableChanged: (t) => setState(() => _table = t),
          blitzDiff: _blitzDiff,
          onBlitzDiffChanged: (d) => setState(() => _blitzDiff = d),
          blitzOps: _blitzOps,
          onToggleBlitzOp: (op) => setState(() {
            if (_blitzOps.contains(op)) {
              if (_blitzOps.length > 1) _blitzOps.remove(op);
            } else {
              _blitzOps.add(op);
            }
          }),
          onBack: () => setState(() => _view = MathView.modeSelect),
          onStart: () {
            if (_mode == MathMode.practice) {
              _startPractice();
            } else if (_mode == MathMode.tables) {
              _startTables();
            } else {
              _startBlitz();
            }
          },
        );
        break;
      case MathView.quiz:
        if (_qCur >= _questions.length) {
          screen = const SizedBox();
        } else {
          screen = MathQuizView(
            question: _questions[_qCur],
            qCur: _qCur,
            totalQuestions: _questions.length,
            score: _score,
            streak: _streak,
            chosenIdx: _chosenIdx,
            answered: _answered,
            hintUsed: _hintUsed,
            hintElimIdx: _hintElimIdx,
            missingMode: _missingMode,
            onAnswer: _checkAnswer,
            onUseHint: _useHint,
            onClose: () {
              _tts.stop();
              setState(() => _view = MathView.modeSelect);
            },
          );
        }
        break;
      case MathView.blitz:
        screen = MathBlitzView(
          question: _blitzQs[_blitzIdx % _blitzQs.length],
          blitzTime: _blitzTime,
          blitzScore: _blitzScore,
          blitzTotal: _blitzTotal,
          blitzAnswered: _blitzAnswered,
          blitzChosen: _blitzChosen,
          onAnswer: _checkBlitz,
          onTick: (remaining) => setState(() => _blitzTime = remaining),
          onFinish: _finishBlitz,
          onClose: () {
            _tts.stop();
            setState(() => _view = MathView.modeSelect);
          },
        );
        break;
      case MathView.result:
        screen = MathResultView(
          isBlitz: _lastMode == 'blitz',
          score: _lastMode == 'blitz' ? _blitzScore : _score,
          total: _lastMode == 'blitz' ? _blitzTotal : _questions.length,
          streak: _streak,
          blitzBest: _blitzBest,
          playerName: _playerName,
          leaderboard: _lb,
          showConfetti: _showResultConfetti,
          onModes: () {
            _tts.stop();
            setState(() => _view = MathView.modeSelect);
          },
          onRetry: () {
            _tts.stop();
            setState(() => _view = MathView.settings);
          },
        );
        break;
    }

    return Stack(
      children: [
        screen,
        Positioned(
          top: -30,
          right: -30,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/math_card.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.06,
              child: const Text('✨', style: TextStyle(fontSize: 90)),
            ),
          ),
        ),
      ],
    );
  }
}
