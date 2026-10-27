import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';

class DailyChallengeCard extends StatelessWidget {
  final bool isDone;
  final int streak;
  final VoidCallback onTap;

  const DailyChallengeCard({
    super.key,
    required this.isDone,
    required this.streak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDone
                  ? [const Color(0xFF1a3a2a), const Color(0xFF1a2a1a)]
                  : [const Color(0xFF2a1a3a), const Color(0xFF1a1040)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF51CF66).withAlpha(120)
                  : const Color(0xFFFFD93D).withAlpha(120),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(isDone ? '✅' : '⚡', style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDone ? 'Daily Challenge Done!' : '⚡ Daily Challenge',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDone
                            ? const Color(0xFF51CF66)
                            : const Color(0xFFFFD93D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDone
                          ? 'Come back tomorrow for a new one'
                          : 'A new puzzle every day — tap to play!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(115),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withAlpha(80),
                    ),
                  ),
                  child: Text(
                    '🔥 $streak',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                )
              else
                Text(
                  '›',
                  style: TextStyle(
                    fontSize: 22,
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

class ActivityGridCard extends StatelessWidget {
  final String emoji;
  final String name;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? progress;
  final String? imagePath;

  const ActivityGridCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.colors,
    required this.onTap,
    this.progress,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final sfx = SoundService();
    return TapScale(
      onTap: () {
        sfx.play(SoundType.tap);
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha(110),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (progress != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    progress!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    )
                  else
                    Text(emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
