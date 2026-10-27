import 'package:flutter/material.dart';

class AbcResultView extends StatelessWidget {
  final int score;
  final int? best;
  final int learned;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  const AbcResultView({
    super.key,
    required this.score,
    required this.best,
    required this.learned,
    required this.onHome,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / 10 * 100).round();
    final trophy = pct >= 90
        ? '🏆'
        : pct >= 70
            ? '🎉'
            : pct >= 50
                ? '👍'
                : '😊';
    final title = pct >= 90
        ? 'Outstanding!'
        : pct >= 70
            ? 'Great Job!'
            : pct >= 50
                ? 'Good Try!'
                : 'Keep Practicing!';
    final stars = pct >= 80
        ? '⭐⭐⭐'
        : pct >= 50
            ? '⭐⭐'
            : (score > 0 ? '⭐' : '☆☆☆');
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
                  child: Column(
                    children: [
                      Text(trophy, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 7),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$score/10 correct in the letter quiz!',
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                        ).createShader(b),
                        child: Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        stars,
                        style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 4,
                        ),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: badges
                              .map(
                                (b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(38),
                                    ),
                                  ),
                                  child: Text(
                                    b,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white60,
                          side: const BorderSide(color: Colors.white12),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('🔄 Try Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
