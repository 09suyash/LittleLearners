import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/letter_data.dart';

class LetterDetailSheet extends StatelessWidget {
  final int idx;
  final TtsService tts;
  final VoidCallback onTraceUpper;
  final VoidCallback onTraceLower;
  final void Function(int) onNav;

  const LetterDetailSheet({
    super.key,
    required this.idx,
    required this.tts,
    required this.onTraceUpper,
    required this.onTraceLower,
    required this.onNav,
  });

  @override
  Widget build(BuildContext context) {
    final d = letters[idx];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1035), Color(0xFF0f0c29)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Text(
                  '${d.letter}${d.letter.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: d.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(46)),
                  ),
                  child: Text(
                    '🔊 ${d.phonetic}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(166),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Word chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 7,
              children: d.words.map((w) {
                final emoji = wordEmojis[w] ?? '';
                return GestureDetector(
                  onTap: () => tts.speak(w),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 7,
                    ),
                    margin: const EdgeInsets.only(bottom: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withAlpha(33)),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 3),
                        Text(
                          w,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Tap to hear ▶',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withAlpha(97),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Trace & audio buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTraceUpper,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          '🔤 Trace "${d.letter}" (Capital)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTraceLower,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFc471f5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          '🔡 Trace "${d.letter.toLowerCase()}" (Small)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await tts.stop();
                      await tts.speak(d.letter, rate: 0.7, pitch: 1.3);
                      await Future.delayed(const Duration(milliseconds: 300));
                      for (final w in d.words) {
                        await tts.speak(w);
                        await Future.delayed(const Duration(milliseconds: 300));
                      }
                    },
                    icon: const Text('🔊', style: TextStyle(fontSize: 15)),
                    label: const Text('Hear All Words'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Prev / Next
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onNav(-1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text('← Prev'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onNav(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text('Next →'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
