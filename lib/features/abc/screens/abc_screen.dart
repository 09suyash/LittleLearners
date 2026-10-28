import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/letter_data.dart';
import '../models/quiz_question.dart';
import '../widgets/letter_card.dart';
import '../widgets/letter_detail_sheet.dart';
import '../widgets/letter_trace_canvas.dart';
import '../widgets/abc_quiz_view.dart';
import '../widgets/abc_result_view.dart';

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
  List<QuizQuestion> _quizQs = [];
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
    final list = await ProgressRepository().getAbcLearnedLetters();
    final best = await ProgressRepository().getAbcQuizBest();
    if (!mounted) return;
    setState(() {
      for (final l in list) {
        final idx = letters.indexWhere((d) => d.letter == l);
        if (idx >= 0) _learned.add(idx);
      }
      _quizBest = best;
    });
  }

  Future<void> _savePrefs() async {
    await ProgressRepository().saveAbcProgress(
      learnedLetters: _learned.map((i) => letters[i].letter).toList(),
      quizBest: _quizBest,
    );
    // Badge checks
    if (_learned.isNotEmpty && mounted) {
      await awardWithToast(context, _bs, 'abc_first', stars: 10);
    }
    if (_learned.length >= 13 && mounted) {
      await awardWithToast(context, _bs, 'abc_half', stars: 25);
    }
    if (_learned.length >= 26 && mounted) {
      await awardWithToast(context, _bs, 'abc_all', stars: 50);
    }
    _checkExplorerBadge();
  }

  @override
  void dispose() {
    _tts.stop();
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
      builder: (_) => LetterDetailSheet(
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
      final wrongs = letters.where((x) => x.letter != d.letter).toList()
        ..shuffle(rng);
      final choices = [d, wrongs[0], wrongs[1], wrongs[2]]..shuffle(rng);
      return QuizQuestion(
        answer: d.letter,
        emoji: d.emoji,
        word: d.primaryWord,
        choices: choices.map((c) => c.letter).toList(),
      );
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
    final correct = choiceIdx >= 0 &&
        _quizQs[_qCur].choices[choiceIdx] == _quizQs[_qCur].answer;
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
    final hasAll = await ProgressRepository().hasExploredAllApps();
    if (_learned.isNotEmpty && hasAll && mounted) {
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
    if (mounted && _qScore >= 5) await awardWithToast(context, _bs, 'abc_quiz5');
    if (mounted && _qScore >= 10) {
      await awardWithToast(context, _bs, 'abc_quiz10', stars: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_view) {
      case AbcView.trace:
        screen = LetterTraceScreen(
          idx: _selectedIdx ?? 0,
          initialLowercase: _traceLowercase,
          onBack: () {
            _tts.stop();
            setState(() => _view = AbcView.grid);
          },
        );
        break;
      case AbcView.quiz:
        screen = AbcQuizView(
          questions: _quizQs,
          current: _qCur,
          score: _qScore,
          chosenIdx: _chosenIdx,
          answered: _qAnswered,
          onAnswer: _answerQuiz,
          onClose: () {
            _tts.stop();
            setState(() => _view = AbcView.grid);
          },
        );
        break;
      case AbcView.result:
        screen = AbcResultView(
          score: _qScore,
          best: _quizBest,
          learned: _learned.length,
          onHome: () {
            _tts.stop();
            setState(() => _view = AbcView.grid);
          },
          onRetry: () {
            _tts.stop();
            _startQuiz();
          },
        );
        break;
      case AbcView.grid:
        screen = _buildGrid();
        break;
    }
    return PopScope(
      canPop: _view == AbcView.grid,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _view != AbcView.grid) {
          _tts.stop();
          setState(() => _view = AbcView.grid);
        }
      },
      child: Stack(
        children: [
          screen,
        Positioned(
          top: -30,
          right: -30,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/abc_card.png',
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
    ),
  );
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
                  Row(
                    children: [
                      if (widget.onGoHome != null)
                        GestureDetector(
                          onTap: () {
                            _tts.stop();
                            widget.onGoHome?.call();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/abc_card.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [
                            Color(0xFFFFD93D),
                            Color(0xFFFF6B6B),
                            Color(0xFF6BCB77),
                            Color(0xFF4D96FF),
                            Color(0xFFc471f5),
                          ],
                        ).createShader(b),
                        child: const Text(
                          'ABC & Phonics Pro',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap · Hear · Trace · Quiz — Learn all 26 letters!',
                    style: TextStyle(
                      color: Colors.white.withAlpha(115),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  _statCard('${_learned.length}/26', 'Letters Learned'),
                  const SizedBox(width: 8),
                  _statCard(
                    _quizBest != null ? '$_quizBest/10' : '—',
                    'Quiz Best',
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    '⭐${_learned.length >= 26 ? 3 : _learned.length >= 13 ? 2 : _learned.length >= 5 ? 1 : 0}',
                    'Stars Earned',
                  ),
                ],
              ),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _learned.length == 26
                        ? '🎉 All 26 letters learned!'
                        : _learned.length >= 13
                            ? '${26 - _learned.length} more to go!'
                            : 'Tap letters to start learning!',
                    style: TextStyle(
                      color: Colors.white.withAlpha(82),
                      fontSize: 11,
                    ),
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
                itemBuilder: (_, i) => LetterCard(
                  data: letters[i],
                  isLearned: _learned.contains(i),
                  onTap: () => _openLetter(i),
                ),
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
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD93D),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(102)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
              )
            : null,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : Colors.white60,
        ),
      ),
    );
  }
}
