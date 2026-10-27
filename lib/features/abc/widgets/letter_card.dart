import 'package:flutter/material.dart';
import '../models/letter_data.dart';

class LetterCard extends StatelessWidget {
  final LetterData data;
  final bool isLearned;
  final VoidCallback onTap;

  const LetterCard({
    super.key,
    required this.data,
    required this.isLearned,
    required this.onTap,
  });

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [data.color, _darken(data.color)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLearned
                ? Colors.white.withAlpha(140)
                : Colors.white.withAlpha(46),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: data.color.withAlpha(107),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${data.letter}${data.letter.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(data.emoji, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (isLearned)
              Positioned(
                top: 3,
                right: 4,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '✓',
                      style: TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
