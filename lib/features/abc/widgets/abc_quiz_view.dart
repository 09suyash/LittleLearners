import 'package:flutter/material.dart';
import '../models/quiz_question.dart';

class AbcQuizView extends StatefulWidget {
  final List<QuizQuestion> questions;
  final int current;
  final int score;
  final int? chosenIdx;
  final bool answered;
  final void Function(int) onAnswer;
  final VoidCallback onClose;

  const AbcQuizView({
    super.key,
    required this.questions,
    required this.current,
    required this.score,
    required this.chosenIdx,
    required this.answered,
    required this.onAnswer,
    required this.onClose,
  });

  @override
  State<AbcQuizView> createState() => _AbcQuizViewState();
}

class _AbcQuizViewState extends State<AbcQuizView>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  static const _totalSecs = 12.0;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSecs.toInt()),
    )..forward();
    _timerCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.answered) {
        widget.onAnswer(-1);
      }
    });
  }

  @override
  void didUpdateWidget(AbcQuizView old) {
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
              child: Row(
                children: [
                  Text(
                    '⭐ ${widget.score}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFD93D),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Q ${widget.current + 1} / ${widget.questions.length}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(23),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '✕',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                      valueColor: AlwaysStoppedAnimation(
                        pct > 0.25
                            ? const Color(0xFF51CF66)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Question card
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Column(
                  children: [
                    Text(q.emoji, style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 9),
                    Text(
                      'What letter does this word start with?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(128),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      q.word,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
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
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
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
                  color:
                      (widget.chosenIdx != null &&
                              widget.chosenIdx! >= 0 &&
                              q.choices[widget.chosenIdx!] == q.answer)
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
