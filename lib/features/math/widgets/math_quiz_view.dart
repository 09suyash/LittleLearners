import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/math_models.dart';

class TimerBar extends StatefulWidget {
  final VoidCallback onTimeout;
  const TimerBar({super.key, required this.onTimeout});

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..forward();
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
            valueColor: AlwaysStoppedAnimation(
              pct > 0.25 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B),
            ),
          ),
        );
      },
    );
  }
}

class MathQuizView extends StatelessWidget {
  final MathQuestion question;
  final int qCur;
  final int totalQuestions;
  final int score;
  final int streak;
  final int? chosenIdx;
  final bool answered;
  final bool hintUsed;
  final int hintElimIdx;
  final String missingMode;
  final void Function(int) onAnswer;
  final VoidCallback onUseHint;
  final VoidCallback onClose;

  const MathQuizView({
    super.key,
    required this.question,
    required this.qCur,
    required this.totalQuestions,
    required this.score,
    required this.streak,
    required this.chosenIdx,
    required this.answered,
    required this.hintUsed,
    required this.hintElimIdx,
    required this.missingMode,
    required this.onAnswer,
    required this.onUseHint,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final choices = question.choices;
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
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✕',
                            style: TextStyle(fontSize: 14, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⭐ $score',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD93D),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Q ${qCur + 1}/$totalQuestions',
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 13,
                        ),
                      ),
                      if (streak >= 3) ...[
                        const SizedBox(width: 8),
                        Text(
                          '🔥 $streak',
                          style: const TextStyle(
                            color: Color(0xFF51CF66),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  TimerBar(
                    key: ValueKey('timer_$qCur'),
                    onTimeout: () => onAnswer(-1),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      missingMode == 'yes'
                          ? question.display
                          : '${question.display} = ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: (hintUsed || answered) ? null : onUseHint,
                      icon: const Text('💡', style: TextStyle(fontSize: 14)),
                      label: Text(
                        hintUsed ? 'Used' : 'Hint (1 use)',
                        style: TextStyle(
                          color: hintUsed
                              ? Colors.white38
                              : const Color(0xFFFFD93D),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                    children: List.generate(choices.length, (i) {
                      final val = choices[i];
                      final isCorrect = val == question.answer;
                      final isChosen = chosenIdx == i;
                      final isElim = hintElimIdx == i;
                      Color bg = Colors.white.withAlpha(14);
                      Color border = Colors.white.withAlpha(23);
                      if (answered) {
                        if (isCorrect) {
                          bg = const Color(0xFF51CF66).withAlpha(46);
                          border = const Color(0xFF51CF66);
                        } else if (isChosen) {
                          bg = const Color(0xFFFF6B6B).withAlpha(46);
                          border = const Color(0xFFFF6B6B);
                        }
                      }
                      return TapScale(
                        onTap: (answered || isElim) ? null : () => onAnswer(i),
                        child: Opacity(
                          opacity: isElim ? 0.22 : 1.0,
                          child: AnimatedScale(
                            scale: (answered && isCorrect) ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: border, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '$val',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  if (answered)
                    Text(
                      chosenIdx == -1
                          ? "⏰ Time's up! Answer was ${question.answer}"
                          : choices[chosenIdx!] == question.answer
                              ? (streak >= 3
                                  ? '✅ Correct! 🔥 $streak streak!'
                                  : '✅ Correct! Brilliant!')
                              : '❌ Answer was ${question.answer}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: (chosenIdx != null &&
                                chosenIdx! >= 0 &&
                                choices[chosenIdx!] == question.answer)
                            ? const Color(0xFF51CF66)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
