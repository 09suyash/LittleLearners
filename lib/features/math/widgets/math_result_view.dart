import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/math_models.dart';

class MathResultView extends StatelessWidget {
  final bool isBlitz;
  final int score;
  final int total;
  final int streak;
  final int blitzBest;
  final String playerName;
  final List<MathLeaderboardEntry> leaderboard;
  final bool showConfetti;
  final VoidCallback onModes;
  final VoidCallback onRetry;

  const MathResultView({
    super.key,
    required this.isBlitz,
    required this.score,
    required this.total,
    required this.streak,
    required this.blitzBest,
    required this.playerName,
    required this.leaderboard,
    required this.showConfetti,
    required this.onModes,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final emoji = isBlitz
        ? (score >= 25
            ? '🏆'
            : score >= 15
                ? '🎉'
                : score >= 8
                    ? '👍'
                    : '😊')
        : (pct >= 90
            ? '🏆'
            : pct >= 70
                ? '🎉'
                : pct >= 50
                    ? '👍'
                    : '😊');
    final title = isBlitz
        ? (score >= 25
            ? 'Blitz Champion!'
            : score >= 15
                ? 'Speed Demon!'
                : score >= 8
                    ? 'Nice Blitz!'
                    : 'Good Effort!')
        : (pct >= 90
            ? 'Outstanding!'
            : pct >= 70
                ? 'Great Job!'
                : pct >= 50
                    ? 'Good Try!'
                    : 'Keep Going!');
    final stars = isBlitz
        ? (score >= 25
            ? '⭐⭐⭐'
            : score >= 15
                ? '⭐⭐'
                : (score > 0 ? '⭐' : '☆☆☆'))
        : (pct >= 80
            ? '⭐⭐⭐'
            : pct >= 50
                ? '⭐⭐'
                : (pct > 0 ? '⭐' : '☆☆☆'));

    final badges = <String>[
      if (!isBlitz && pct == 100) '💯 Perfect Score!',
      if (!isBlitz && streak >= 5) '🔥 Streak Master',
      if (!isBlitz && pct >= 90) '🎯 Sharpshooter',
      if (isBlitz && score >= 30) '⚡ Lightning Fast',
      if (isBlitz && score >= 20) '🏆 Blitz Champion',
    ];

    final displayName = playerName.isEmpty ? 'Player' : playerName;

    return Stack(
      children: [
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
                  child: Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 52)),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isBlitz
                            ? '$displayName • $score correct in 60 seconds!'
                            : '$displayName • $score/$total correct',
                        style: TextStyle(
                          color: Colors.white.withAlpha(115),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stars,
                        style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 4,
                        ),
                      ),
                      if (isBlitz && blitzBest > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '🏅 Personal Best: $blitzBest',
                          style: TextStyle(
                            color: Colors.white.withAlpha(140),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                        ).createShader(b),
                        child: Text(
                          isBlitz ? '$score ✓' : '$pct%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '🏅 Badges Earned',
                          style: TextStyle(
                            color: Colors.white.withAlpha(89),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: badges
                              .map(
                                (b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(36),
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
                      if (!isBlitz && leaderboard.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          '🏆 Leaderboard',
                          style: TextStyle(
                            color: Colors.white.withAlpha(89),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        ...leaderboard.take(5).toList().asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        ['🥇', '🥈', '🥉'][e.key < 3 ? e.key : 2],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          e.value.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${e.value.score}/${e.value.total}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD93D),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onModes,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white60,
                                side: const BorderSide(color: Colors.white12),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('🏠 Modes'),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onRetry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
          ),
        ),
        ConfettiOverlay(trigger: showConfetti),
      ],
    );
  }
}
