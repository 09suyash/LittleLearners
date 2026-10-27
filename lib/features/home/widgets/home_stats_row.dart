import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../../gamification/screens/badges_screen.dart';

class HomeStatsRow extends StatelessWidget {
  final String abcScore;
  final String mathScore;
  final String storiesRead;

  const HomeStatsRow({
    super.key,
    required this.abcScore,
    required this.mathScore,
    required this.storiesRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          _statPill(abcScore, 'ABC'),
          const SizedBox(width: 8),
          _statPill(mathScore, 'Math'),
          const SizedBox(width: 8),
          _statPill(storiesRead, 'Stories'),
        ],
      ),
    );
  }

  Widget _statPill(String num, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFFFFD93D),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(97)),
            ),
          ],
        ),
      ),
    );
  }
}

class TrophyRoomButton extends StatelessWidget {
  final int badgeCount;
  final VoidCallback onReturn;

  const TrophyRoomButton({
    super.key,
    required this.badgeCount,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final total = allBadges.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BadgesScreen()),
        ).then((_) => onReturn()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD93D).withAlpha(60)),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/trophy_card.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trophy Room',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$badgeCount / $total badges earned',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(102),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? badgeCount / total : 0,
                    minHeight: 7,
                    backgroundColor: Colors.white.withAlpha(18),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD93D)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withAlpha(64),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
