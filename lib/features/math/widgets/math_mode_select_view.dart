import 'package:flutter/material.dart';
import '../models/math_models.dart';

class MathModeSelectView extends StatelessWidget {
  final VoidCallback? onGoHome;
  final void Function(MathMode mode) onSelectMode;

  const MathModeSelectView({
    super.key,
    this.onGoHome,
    required this.onSelectMode,
  });

  Widget _modeCard({
    required String icon,
    required String name,
    required String desc,
    required MathMode mode,
    required bool featured,
  }) {
    return GestureDetector(
      onTap: () => onSelectMode(mode),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(featured ? 20 : 14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: featured
                ? const Color(0xFFFFD93D)
                : Colors.white.withAlpha(26),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: featured
                          ? const Color(0xFFFFD93D)
                          : Colors.white,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(107),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(77)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 60,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  if (onGoHome != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: onGoHome,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white.withAlpha(115),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (onGoHome != null) const SizedBox(height: 14),
                  Image.asset(
                    'assets/images/math_card.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                    ).createShader(b),
                    child: const Text(
                      'Math Quiz Pro',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Choose your challenge mode',
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _modeCard(
                    icon: '🎯',
                    name: 'Practice',
                    desc:
                        'Add · Subtract · Multiply · Missing Numbers · Hints',
                    mode: MathMode.practice,
                    featured: false,
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    icon: '📊',
                    name: 'Times Tables',
                    desc: 'Master any table from 2× to 12×',
                    mode: MathMode.tables,
                    featured: false,
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    icon: '⚡',
                    name: '⚡ Blitz! 60s',
                    desc: '60 seconds — answer as many as you can!',
                    mode: MathMode.blitz,
                    featured: true,
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
