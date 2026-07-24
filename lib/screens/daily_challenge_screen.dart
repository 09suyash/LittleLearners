import 'package:flutter/material.dart';
import '../utils/daily_challenge_service.dart';
import '../utils/tts_service.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/app_state.dart';

class DailyChallengeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onCompleted;
  const DailyChallengeScreen({super.key, required this.onBack, required this.onCompleted});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  final _dcs = DailyChallengeService();
  final _tts = TtsService();
  final _bs  = BadgeService();

  late DailyChallenge _challenge;
  int? _chosenIdx;
  bool _answered = false;
  bool _alreadyDone = false;
  int  _streak = 0;

  late AnimationController _celebCtrl;
  late Animation<double>   _celebAnim;

  @override
  void initState() {
    super.initState();
    _challenge = _dcs.generateChallenge();
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _celebAnim = CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut);
    _load();
  }

  Future<void> _load() async {
    final done   = await _dcs.isCompletedToday();
    final streak = await _dcs.getStreak();
    if (mounted) setState(() { _alreadyDone = done; _streak = streak; });
    if (!done) _tts.speak(_challenge.question);
  }

  @override
  void dispose() {
    _tts.stop();
    _celebCtrl.dispose();
    super.dispose();
  }

  Future<void> _answer(int idx) async {
    if (_answered || _alreadyDone) return;
    final correct = _challenge.choices[idx] == _challenge.answer;
    setState(() { _chosenIdx = idx; _answered = true; });

    if (correct) {
      final ttsFuture = _tts.speak('Correct! Amazing!');
      await _dcs.markCompleted();
      final streak = await _dcs.getStreak();
      if (mounted) setState(() => _streak = streak);
      await AppState.addStars(10);
      if (!mounted) return;
      await awardWithToast(context, _bs, 'daily_done');
      if (streak >= 3 && mounted) await awardWithToast(context, _bs, 'daily_streak3');
      if (streak >= 7 && mounted) await awardWithToast(context, _bs, 'daily_streak7', stars: 50);
      _celebCtrl.forward(from: 0);
      await ttsFuture;
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) widget.onCompleted();
    } else {
      await _tts.speak('Try again tomorrow! The answer was ${_challenge.answer}');
      await _dcs.markCompleted();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0f0c29), Color(0xFF1a1040), Color(0xFF24243e)],
          ),
        ),
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
                child: _alreadyDone ? _buildAlreadyDone() : _buildChallenge(),
              ),
            ),
          ),
        ),
      ),
      if (_answered && _chosenIdx != null &&
          _challenge.choices[_chosenIdx!] == _challenge.answer)
        ConfettiOverlay(trigger: _answered),
    ]);
  }

  Widget _buildChallenge() {
    return Column(children: [
      // Header
      Row(children: [
        GestureDetector(
          onTap: () { _tts.stop(); widget.onBack(); },
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('⚡ Daily Challenge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('Come back tomorrow for a new one!',
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(89))),
          ]),
        ),
        if (_streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(80)),
            ),
            child: Text('🔥 $_streak', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B))),
          ),
      ]),
      const SizedBox(height: 22),

      // Challenge type badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _typeColor(_challenge.type).withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _typeColor(_challenge.type).withAlpha(120)),
        ),
        child: Text(_typeLabel(_challenge.type),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _typeColor(_challenge.type))),
      ),
      const SizedBox(height: 18),

      // Question card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          _challenge.question,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.4),
        ),
      ),
      const SizedBox(height: 20),

      // Answer choices
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: List.generate(_challenge.choices.length, (i) {
          final val = _challenge.choices[i];
          final isCorrect = val == _challenge.answer;
          final isChosen  = _chosenIdx == i;
          Color bg     = Colors.white.withAlpha(14);
          Color border = Colors.white.withAlpha(26);
          if (_answered) {
            if (isCorrect)      { bg = const Color(0xFF51CF66).withAlpha(46); border = const Color(0xFF51CF66); }
            else if (isChosen)  { bg = const Color(0xFFFF6B6B).withAlpha(46); border = const Color(0xFFFF6B6B); }
          }
          return TapScale(
            onTap: _answered ? null : () => _answer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 2),
              ),
              child: Center(
                child: Text(val,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          );
        }),
      ),

      if (_answered) ...[
        const SizedBox(height: 14),
        ScaleTransition(
          scale: _celebAnim,
          child: Text(
            _chosenIdx != null && _challenge.choices[_chosenIdx!] == _challenge.answer
                ? '🎉 Correct! See you tomorrow!'
                : '❌ The answer was ${_challenge.answer}. Try again tomorrow!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: (_chosenIdx != null && _challenge.choices[_chosenIdx!] == _challenge.answer)
                  ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildAlreadyDone() {
    return Column(children: [
      Row(children: [
        GestureDetector(
          onTap: () { _tts.stop(); widget.onBack(); },
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
      ]),
      const SizedBox(height: 24),
      const Text('✅', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 10),
      const Text("Today's challenge done!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 6),
      Text('Come back tomorrow for a new one',
          style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13)),
      const SizedBox(height: 18),
      if (_streak > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withAlpha(22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(80)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$_streak day streak!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B))),
              Text('Keep it going tomorrow!',
                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(115))),
            ]),
          ]),
        ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () { _tts.stop(); widget.onBack(); },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD93D),
            foregroundColor: const Color(0xFF0d1b2a),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('🏠 Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    ]);
  }

  Color _typeColor(ChallengeType t) {
    switch (t) {
      case ChallengeType.math:   return const Color(0xFFFFD93D);
      case ChallengeType.letter: return const Color(0xFF51CF66);
      case ChallengeType.trivia: return const Color(0xFF4D96FF);
    }
  }

  String _typeLabel(ChallengeType t) {
    switch (t) {
      case ChallengeType.math:   return '🔢 Math Challenge';
      case ChallengeType.letter: return '🔤 Letter Challenge';
      case ChallengeType.trivia: return '🌟 Trivia Challenge';
    }
  }
}
