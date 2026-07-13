import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import 'memory_game_screen.dart';
import 'coloring_book_screen.dart';
import 'puzzle_screen.dart';
import 'simon_says_screen.dart';
import 'bubble_pop_screen.dart';
import 'shape_sorter_screen.dart';
import 'whack_a_mole_screen.dart';
import 'maze_runner_screen.dart';
import 'animal_feeding_screen.dart';
import 'archery_screen.dart';
import 'racing_screen.dart';

class GamesScreen extends StatefulWidget {
  final VoidCallback onBack;
  const GamesScreen({super.key, required this.onBack});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _sfx = SoundService();
  int _mazeLevel = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _mazeLevel = prefs.getInt('maze_best_level') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a1040), Color(0xFF2d1b69), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: _grid(context),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      child: Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🎮 Games',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('11 fun games to play!',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }

  Widget _grid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _gridCard(
          emoji: '🃏', name: 'Memory Match',
          imagePath: 'assets/images/memory_card.png',
          colors: [const Color(0xFF845EF7), const Color(0xFFD63ECA)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MemoryGameScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🎨', name: 'Coloring Book',
          imagePath: 'assets/images/coloring_card.png',
          colors: [const Color(0xFFFF80AB), const Color(0xFFE91E8C)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ColoringBookScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🧩', name: 'Puzzle Pieces',
          imagePath: 'assets/images/puzzle_card.png',
          colors: [const Color(0xFFFF922B), const Color(0xFFFC5C7D)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PuzzleScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🎯', name: 'Simon Says',
          colors: [const Color(0xFF6C5CE7), const Color(0xFF00CEC9)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SimonSaysScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🫧', name: 'Bubble Pop',
          colors: [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => BubblePopScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🧸', name: 'Shape Sorter',
          colors: [const Color(0xFFF6D365), const Color(0xFFFDA085)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ShapeSorterScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🔨', name: 'Whack-a-Mole',
          colors: [const Color(0xFFCB356B), const Color(0xFFBD3F32)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => WhackAMoleScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🗺️', name: 'Maze Runner',
          colors: [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
          progress: _mazeLevel > 0 ? '$_mazeLevel/6' : null,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MazeRunnerScreen(onBack: () => Navigator.pop(context)))).then((_) => _loadStats()),
        ),
        _gridCard(
          emoji: '🦖', name: 'Animal Feeding',
          colors: [const Color(0xFF16A085), const Color(0xFFF4D03F)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AnimalFeedingScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🏹', name: 'Archery',
          colors: [const Color(0xFF134E5E), const Color(0xFF71B280)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ArcheryScreen(onBack: () => Navigator.pop(context)))),
        ),
        _gridCard(
          emoji: '🏎️', name: 'Racing',
          colors: [const Color(0xFF232526), const Color(0xFFE74C3C)],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => RacingScreen(onBack: () => Navigator.pop(context)))),
        ),
      ],
    );
  }

  Widget _gridCard({
    required String emoji,
    required String name,
    required List<Color> colors,
    required VoidCallback onTap,
    String? progress,
    String? imagePath,
  }) {
    return TapScale(
      onTap: () { _sfx.play(SoundType.tap); onTap(); },
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
                offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(children: [
          if (progress != null)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(progress,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (imagePath != null)
                Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.contain)
              else
                Text(emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
