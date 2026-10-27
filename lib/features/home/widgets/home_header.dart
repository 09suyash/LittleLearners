import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';

class HomeLevelBar extends StatelessWidget {
  const HomeLevelBar({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppState.levelProgress;
    final toNext = AppState.starsToNext;
    final isMax = toNext == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppState.levelEmoji} Lv ${AppState.level} · ${AppState.levelName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              Text(
                isMax ? '🌈 MAX LEVEL' : '$toNext ⭐ to next level',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeExpandedHeader extends StatelessWidget {
  final String childName;
  final String mascot;
  final VoidCallback onMascotTap;
  final Animation<double> floatAnim;
  final Animation<double> mascotBounceAnim;

  const HomeExpandedHeader({
    super.key,
    required this.childName,
    required this.mascot,
    required this.onMascotTap,
    required this.floatAnim,
    required this.mascotBounceAnim,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = childName.isNotEmpty;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ZOODLES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Colors.white.withAlpha(130),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onMascotTap,
              child: AnimatedBuilder(
                animation: Listenable.merge([floatAnim, mascotBounceAnim]),
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, floatAnim.value),
                  child: Transform.scale(
                    scale: mascotBounceAnim.value,
                    child: Text(
                      mascot,
                      style: const TextStyle(fontSize: 54),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (hasName)
              Text(
                'Hi, $childName! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              )
            else
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFD93D),
                    Color(0xFFFF6B6B),
                    Color(0xFF6BCB77),
                    Color(0xFF4D96FF),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Zoodles',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              hasName
                  ? 'Ready to learn and play? 🌟'
                  : '6 subjects + 11 games! Tap to start!',
              style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD93D), Color(0xFFFF9F43)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x44FFD93D), blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '${AppState.totalStars} stars',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1a0533),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const HomeLevelBar(),
          ],
        ),
      ),
    );
  }
}

class HomeCollapsedHeader extends StatelessWidget {
  final String childName;
  final String mascot;

  const HomeCollapsedHeader({
    super.key,
    required this.childName,
    required this.mascot,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = childName.isNotEmpty;
    final progress = AppState.levelProgress;
    final toNext = AppState.starsToNext;
    final isMax = toNext == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(mascot, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasName ? 'Hi, $childName! 👋' : 'Zoodles',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${AppState.levelEmoji} Lv ${AppState.level} · ${AppState.levelName}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withAlpha(140),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD93D), Color(0xFFFF9F43)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${AppState.totalStars}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1a0533),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isMax ? '🌈 MAX' : '$toNext ⭐ left',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withAlpha(90),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
