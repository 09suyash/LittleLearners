import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/math_models.dart';

class BlitzTimer extends StatefulWidget {
  final void Function(int) onTick;
  final VoidCallback onFinish;
  const BlitzTimer({super.key, required this.onTick, required this.onFinish});

  @override
  State<BlitzTimer> createState() => _BlitzTimerState();
}

class _BlitzTimerState extends State<BlitzTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..forward();
    _ctrl.addListener(() => widget.onTick(60 - (_ctrl.value * 60).round()));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinish();
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

class MathBlitzView extends StatelessWidget {
  final MathQuestion question;
  final int blitzTime;
  final int blitzScore;
  final int blitzTotal;
  final bool blitzAnswered;
  final int? blitzChosen;
  final void Function(int) onAnswer;
  final void Function(int) onTick;
  final VoidCallback onFinish;
  final VoidCallback onClose;

  const MathBlitzView({
    super.key,
    required this.question,
    required this.blitzTime,
    required this.blitzScore,
    required this.blitzTotal,
    required this.blitzAnswered,
    required this.blitzChosen,
    required this.onAnswer,
    required this.onTick,
    required this.onFinish,
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
                  BlitzTimer(
                    key: const ValueKey('blitz_timer'),
                    onTick: onTick,
                    onFinish: onFinish,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$blitzTime',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '⭐ $blitzScore',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD93D),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'answered',
                            style: TextStyle(
                              color: Colors.white.withAlpha(77),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$blitzTotal',
                            style: TextStyle(
                              color: Colors.white.withAlpha(153),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      '${question.display} = ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                    children: List.generate(choices.length, (i) {
                      final val = choices[i];
                      final isCorrect = val == question.answer;
                      final isChosen = blitzChosen == i;
                      Color bg = Colors.white.withAlpha(18);
                      Color border = Colors.white.withAlpha(26);
                      if (blitzAnswered) {
                        if (isCorrect) {
                          bg = const Color(0xFF51CF66).withAlpha(51);
                          border = const Color(0xFF51CF66);
                        } else if (isChosen) {
                          bg = const Color(0xFFFF6B6B).withAlpha(51);
                          border = const Color(0xFFFF6B6B);
                        }
                      }
                      return TapScale(
                        onTap: blitzAnswered ? null : () => onAnswer(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: border, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '$val',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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
