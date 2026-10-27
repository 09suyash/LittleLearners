import 'dart:math';
import 'package:flutter/material.dart';
import '../models/animal_data.dart';
import 'package:zoodles/core/core.dart';

enum _GameState { idle, question, finished }

class AnimalSoundQuizScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AnimalSoundQuizScreen({super.key, required this.onBack});

  @override
  State<AnimalSoundQuizScreen> createState() => _AnimalSoundQuizScreenState();
}

class _AnimalSoundQuizScreenState extends State<AnimalSoundQuizScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final TtsService _tts = TtsService();
  final _rng = Random();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _choiceCounts = [4, 4, 6];
  static const _sameCategory = [false, true, true];
  static const _totalQuestions = 10;
  int _diffIdx = 0;

  _GameState _state = _GameState.idle;
  late List<AnimalData> _quiz;
  late List<AnimalData> _choices;
  int _qIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIdx;
  int _bestScore = -1;
  int _bestTotal = _totalQuestions;
  bool _soundBubble = false;
  bool _sparkle = false;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final stats = await ProgressRepository().getAnimalSoundStats(defaultTotal: _totalQuestions);
    if (!mounted) return;
    setState(() {
      _bestScore = stats.best;
      _bestTotal = stats.total;
    });
  }

  Future<void> _saveBest() async {
    if (_score <= _bestScore) return;
    await ProgressRepository().saveAnimalSoundStats(score: _score, total: _totalQuestions);
    _bestScore = _score;
    _bestTotal = _totalQuestions;
  }

  void _startQuiz() {
    _quiz = (List.of(animals)..shuffle(_rng)).take(_totalQuestions).toList();
    _qIndex = 0;
    _score = 0;
    setState(() => _state = _GameState.question);
    _loadQuestion();
  }

  void _loadQuestion() {
    final correct = _quiz[_qIndex];
    final distractorPool = animals.where((a) => a.name != correct.name).toList();
    List<AnimalData> preferred = _sameCategory[_diffIdx]
        ? distractorPool.where((a) => a.category == correct.category).toList()
        : distractorPool.where((a) => a.category != correct.category).toList();
    preferred.shuffle(_rng);
    final need = _choiceCounts[_diffIdx] - 1;
    final chosen = <AnimalData>[];
    chosen.addAll(preferred.take(need));
    if (chosen.length < need) {
      final rest = distractorPool.where((a) => !chosen.contains(a)).toList()..shuffle(_rng);
      chosen.addAll(rest.take(need - chosen.length));
    }
    setState(() {
      _choices = [correct, ...chosen]..shuffle(_rng);
      _answered = false;
      _selectedIdx = null;
    });
    _speakCurrent();
  }

  void _speakCurrent() {
    _sfx.play(SoundType.critter);
    setState(() => _soundBubble = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _soundBubble = false);
    });
    _tts.speak(_quiz[_qIndex].sound, rate: 0.45, pitch: 1.0);
  }

  void _onAnswer(int? choiceIdx) {
    if (_answered) return;
    final correct = choiceIdx != null && _choices[choiceIdx].name == _quiz[_qIndex].name;
    setState(() {
      _answered = true;
      _selectedIdx = choiceIdx;
      if (correct) {
        _score++;
        _sparkle = true;
      }
    });
    _sfx.play(correct ? SoundType.correct : SoundType.wrong);
    if (correct) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _sparkle = false);
      });
    }
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_qIndex + 1 >= _quiz.length) {
      _finish();
    } else {
      setState(() => _qIndex++);
      _loadQuestion();
    }
  }

  Future<void> _finish() async {
    await _saveBest();
    final perfect = _score == _totalQuestions;
    _sfx.play(perfect ? SoundType.win : SoundType.correct);
    await AppState.addStars(10);
    if (!mounted) return;
    setState(() => _state = _GameState.finished);
    await awardWithToast(context, _bs, 'animal_first');
    if (perfect && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'animal_perfect', stars: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF134E1B), Color(0xFF1e5631), Color(0xFF2d6a4f)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.09, child: const Text('🐾', style: TextStyle(fontSize: 140)))),
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
      MascotCorner(celebrating: _state == _GameState.finished && _score == _totalQuestions),
      ConfettiOverlay(trigger: _state == _GameState.finished && _score == _totalQuestions),
      SparkleBurst(trigger: _sparkle),
    ]);
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 180) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  _tts.stop();
                  if (_state == _GameState.question) {
                    setState(() => _state = _GameState.idle);
                  } else {
                    widget.onBack();
                  }
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            GestureDetector(
              onTap: () {
                _tts.stop();
                if (_state == _GameState.question) {
                  setState(() => _state = _GameState.idle);
                } else {
                  widget.onBack();
                }
              },
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('🐾', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('Animal Sound Quiz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            if (_state == _GameState.question)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(36)),
                ),
                child: Text(_difficulties[_diffIdx],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD93D))),
              ),
          ]),
        );
      },
    );
  }

  Widget _buildStartPrompt() {
    final levels = [
      {
        'title': 'Easy',
        'subtitle': '4 animals • Distinct sounds',
        'badge': '🐣 Beginner',
        'icon': '🐣',
        'colors': [const Color(0xFF43A047), const Color(0xFF66BB6A)],
        'shadow': const Color(0x4443A047),
      },
      {
        'title': 'Medium',
        'subtitle': '4 animals • Same animal group',
        'badge': '🦊 Tricky',
        'icon': '🦊',
        'colors': [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
        'shadow': const Color(0x44FF9800),
      },
      {
        'title': 'Hard',
        'subtitle': '6 animals • 6s Speed Timer ⏱️',
        'badge': '🦁 Expert',
        'icon': '🦁',
        'colors': [const Color(0xFFE53935), const Color(0xFFFF7043)],
        'shadow': const Color(0x44E53935),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(28)),
            ),
            child: Row(
              children: [
                const Text('🔊', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Level',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a level to start listening and guessing!',
                        style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < levels.length; i++) ...[
            _buildLevelCard(
              index: i,
              title: levels[i]['title'] as String,
              subtitle: levels[i]['subtitle'] as String,
              badge: levels[i]['badge'] as String,
              icon: levels[i]['icon'] as String,
              colors: levels[i]['colors'] as List<Color>,
              shadow: levels[i]['shadow'] as Color,
            ),
            if (i < levels.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required int index,
    required String title,
    required String subtitle,
    required String badge,
    required String icon,
    required List<Color> colors,
    required Color shadow,
  }) {
    return TapScale(
      onTap: () {
        _sfx.play(SoundType.tap);
        setState(() => _diffIdx = index);
        _startQuiz();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(45),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('❓', 'Question', '${_qIndex + 1} / $_totalQuestions'),
          _statChip('⭐', 'Score', '$_score'),
        ]),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _speakCurrent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(40)),
          ),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🔊', style: TextStyle(fontSize: 34)),
            SizedBox(height: 4),
            Text('Tap to hear again', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 44,
        child: Center(
          child: AnimatedScale(
            scale: _soundBubble ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.elasticOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF9F43)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🎵 ${_quiz[_qIndex].sound.toUpperCase()}!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1a0533))),
            ),
          ),
        ),
      ),
      if (_diffIdx == 2) ...[
        const SizedBox(height: 14),
        SizedBox(
          width: 220,
          child: CountdownBar(
            key: ValueKey('animal_timer_$_qIndex'),
            seconds: 6,
            onFinish: () => _onAnswer(null),
          ),
        ),
      ],
      const SizedBox(height: 18),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
            ),
            itemCount: _choices.length,
            itemBuilder: (_, i) => _buildChoiceCard(i),
          ),
        ),
      ),
    ]);
  }

  Widget _buildChoiceCard(int i) {
    final animal = _choices[i];
    final isCorrectAnswer = animal.name == _quiz[_qIndex].name;
    Color bg = Colors.white.withAlpha(20);
    Color border = Colors.white.withAlpha(40);
    if (_answered) {
      if (isCorrectAnswer) {
        bg = const Color(0xFF51CF66).withAlpha(90);
        border = const Color(0xFF51CF66);
      } else if (_selectedIdx == i) {
        bg = const Color(0xFFFF6B6B).withAlpha(90);
        border = const Color(0xFFFF6B6B);
      }
    }
    return TapScale(
      onTap: _answered ? null : () => _onAnswer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
        ),
        child: Center(child: Text(animal.emoji, style: const TextStyle(fontSize: 42))),
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
    final pct = _totalQuestions > 0 ? (_score / _totalQuestions * 100).round() : 0;
    final stars = pct >= 80 ? '⭐⭐⭐' : pct >= 50 ? '⭐⭐' : (pct > 0 ? '⭐' : '☆☆☆');
    final emoji = pct >= 80 ? '🏆' : pct >= 50 ? '🎉' : (pct > 0 ? '👍' : '💪');

    return SingleChildScrollView(
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
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text('Score: $_score / $_totalQuestions',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Level: ${_difficulties[_diffIdx]}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(230))),
            const SizedBox(height: 2),
            Text('Best: $_bestScore / $_bestTotal',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
            const SizedBox(height: 4),
            Text(stars, style: const TextStyle(fontSize: 24, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF56AB2F),
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
          child: ElevatedButton(
            onPressed: () {
              setState(() => _state = _GameState.idle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2d6a4f),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white30),
              ),
              elevation: 3,
            ),
            child: const Text('🎮 Choose Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
