import 'package:flutter/material.dart';
import '../utils/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _bs = BadgeService();

  @override
  void initState() {
    super.initState();
    _bs.load().then((_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earned = _bs.earned;
    final earnedCount = earned.length;
    final total = allBadges.length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0f0c29), Color(0xFF1a1040), Color(0xFF24243e)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.12, child: Image.asset('assets/images/trophy_card.png', width: 160, height: 160, fit: BoxFit.contain))),
        Positioned(bottom: 80, left: -10,
            child: Opacity(opacity: 0.05, child: const Text('🌟', style: TextStyle(fontSize: 100)))),
        Positioned(bottom: -10, right: -10,
            child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
        SafeArea(
        child: Column(children: [
          // Back button row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back, color: Colors.white70, size: 24),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(children: [
              Image.asset('assets/images/trophy_card.png', width: 80, height: 80, fit: BoxFit.contain),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                ).createShader(b),
                child: const Text('Trophy Room',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text('$earnedCount / $total badges earned',
                  style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13)),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? earnedCount / total : 0,
                  minHeight: 10,
                  backgroundColor: Colors.white.withAlpha(18),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD93D)),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
          // Badge grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: allBadges.length,
              itemBuilder: (_, i) => _BadgeTile(
                badge: allBadges[i],
                earned: earned.contains(allBadges[i].id),
              ),
            ),
          ),
        ]),
      ),
      ]),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDef badge;
  final bool earned;
  const _BadgeTile({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: earned ? Colors.white.withAlpha(22) : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: earned ? const Color(0xFFFFD93D).withAlpha(120) : Colors.white.withAlpha(18),
          width: earned ? 1.5 : 1,
        ),
        boxShadow: earned
            ? [BoxShadow(color: const Color(0xFFFFD93D).withAlpha(30), blurRadius: 12)]
            : null,
      ),
      child: Stack(children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Emoji — dim if locked
              Opacity(
                opacity: earned ? 1.0 : 0.2,
                child: Text(badge.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(height: 6),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: earned ? Colors.white : Colors.white.withAlpha(51),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                badge.desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 9,
                  color: earned ? Colors.white.withAlpha(102) : Colors.white.withAlpha(30),
                  height: 1.3,
                ),
              ),
            ]),
          ),
        ),
        // Lock icon overlay for locked badges
        if (!earned)
          const Positioned(
            top: 8, right: 8,
            child: Text('🔒', style: TextStyle(fontSize: 12)),
          ),
        // Gold star for earned
        if (earned)
          const Positioned(
            top: 7, right: 7,
            child: Text('✨', style: TextStyle(fontSize: 11)),
          ),
      ]),
    );
  }
}
