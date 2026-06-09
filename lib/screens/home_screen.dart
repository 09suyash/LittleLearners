import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/daily_challenge_service.dart';
import 'memory_game_screen.dart';
import 'word_builder_screen.dart';
import 'counting_screen.dart';
import 'coloring_book_screen.dart';
import 'puzzle_screen.dart';
// import 'nursery_rhyme_screen.dart'; // re-enable when audio files are ready
import 'parent_dashboard_screen.dart';
import 'daily_challenge_screen.dart';
import 'badges_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onTabSelected;
  final ValueNotifier<int> tabNotifier;
  const HomeScreen({super.key, required this.onTabSelected, required this.tabNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;
  late AnimationController _mascotBounceCtrl;
  late Animation<double> _mascotBounceAnim;
  int _mascotIdx = 0;
  static const _mascots = ['🎓', '🦉', '🤩', '🐸', '⭐', '🦄', '🎉', '🌈', '🐨', '🚀'];
  String abcScore = '—';
  String mathScore = '—';
  String storiesRead = '—';
  bool _dcDone = false;
  int  _dcStreak = 0;
  int  _badgeCount = 0;

  final _rng = Random();
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(50, (_) => _Star(_rng));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _mascotBounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _mascotBounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _mascotBounceCtrl, curve: Curves.easeInOut));
    widget.tabNotifier.addListener(_onTabChange);
    _loadStats();
  }

  void _onTabChange() {
    if (widget.tabNotifier.value == 0) _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs   = await SharedPreferences.getInstance();
    final dcDone  = await DailyChallengeService().isCompletedToday();
    final dcStreak = await DailyChallengeService().getStreak();
    await BadgeService().load();
    if (!mounted) return;
    setState(() {
      final learned = prefs.getInt('abc_learned') ?? 0;
      abcScore = learned > 0 ? '$learned/26' : '—';
      final math = prefs.getInt('math_best') ?? -1;
      final mathTotal = prefs.getInt('math_best_total') ?? 10;
      mathScore = math >= 0 ? '$math/$mathTotal' : '—';
      final stories = prefs.getStringList('stories_done')?.length ?? 0;
      storiesRead = stories > 0 ? '$stories' : '—';
      _dcDone    = dcDone;
      _dcStreak  = dcStreak;
      _badgeCount = BadgeService().earned.length;
    });
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Reset Progress?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('This will clear all scores, learned letters and completed stories.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await BadgeService().clear();
    await DailyChallengeService().clear();
    _loadStats();
  }

  @override
  void dispose() {
    widget.tabNotifier.removeListener(_onTabChange);
    _floatCtrl.dispose();
    _mascotBounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Star background
        ..._stars.map((s) {
          final size = MediaQuery.of(context).size;
          return Positioned(
            left: s.x * size.width,
            top: s.y * size.height,
            child: _StarWidget(star: s),
          );
        }),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _header(),
                _dailyChallengeCard(),
                _statsRow(),
                _trophyRoomButton(),
                _appCards(),
                const SizedBox(height: 14),
                _parentZoneButton(),
                const SizedBox(height: 16),
                Text(
                  '🌟 Made with love for young learners • v1.0',
                  style: TextStyle(color: Colors.white.withAlpha(46), fontSize: 11),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _confirmReset,
                  child: Text(
                    'Reset Progress',
                    style: TextStyle(color: Colors.white.withAlpha(38), fontSize: 11, decoration: TextDecoration.underline, decorationColor: Colors.white.withAlpha(38)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _mascotIdx = (_mascotIdx + 1) % _mascots.length);
              _mascotBounceCtrl.forward(from: 0);
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatAnim, _mascotBounceAnim]),
              builder: (context2, child2) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Transform.scale(
                  scale: _mascotBounceAnim.value,
                  child: Text(_mascots[_mascotIdx], style: const TextStyle(fontSize: 48)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B), Color(0xFF6BCB77), Color(0xFF4D96FF)],
            ).createShader(bounds),
            child: const Text(
              'Little Learners',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '3 fun apps · Tap to start learning!',
            style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          _statPill(abcScore, 'ABC Score'),
          const SizedBox(width: 8),
          _statPill(mathScore, 'Math Score'),
          const SizedBox(width: 8),
          _statPill(storiesRead, 'Stories Read'),
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
            Text(num,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFFFFD93D),
                )),
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(97))),
          ],
        ),
      ),
    );
  }

  Widget _appCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          _appCard(
            icon: '🔤', name: 'ABC & Phonics Pro',
            desc: 'Learn all 26 letters with sounds, tracing canvas & quiz mode',
            tags: ['🔊 Voice', '✏️ Trace', '🧠 Quiz', 'Ages 2–6'],
            accentColor: const Color(0xFFFF6B6B),
            tabIndex: 1,
          ),
          const SizedBox(height: 11),
          _appCard(
            icon: '🔢', name: 'Math Quiz Pro',
            desc: 'Practice, Times Tables & 60-second Blitz with badges & hints',
            tags: ['🎯 Practice', '📊 Tables', '⚡ Blitz', 'Ages 4–10'],
            accentColor: const Color(0xFFFFD93D),
            tabIndex: 2,
          ),
          const SizedBox(height: 11),
          _appCard(
            icon: '📚', name: 'Moral Stories',
            desc: '8 classic stories in Hindi & English with full voice narration',
            tags: ['🔊 Hindi', '🇬🇧 English', '8 Stories', 'Ages 3–10'],
            accentColor: const Color(0xFFc4855a),
            tabIndex: 3,
          ),
          const SizedBox(height: 11),
          _memoryCard(),
          const SizedBox(height: 11),
          _wordBuilderCard(),
          const SizedBox(height: 11),
          _countingCard(),
          const SizedBox(height: 11),
          _coloringBookCard(),
          const SizedBox(height: 11),
          _puzzleCard(),
          // _nurseryRhymeCard(), // hidden until audio files are added
        ],
      ),
    );
  }

  Widget _appCard({
    required String icon,
    required String name,
    required String desc,
    required List<String> tags,
    required Color accentColor,
    required int tabIndex,
  }) {
    return GestureDetector(
      onTap: () => widget.onTabSelected(tabIndex),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(33)),
        ),
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withAlpha(26)),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 2),
                        Text(desc,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(122),
                              height: 1.4,
                            )),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(t,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withAlpha(140),
                                )),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyChallengeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DailyChallengeScreen(
            onBack: () => Navigator.pop(context),
            onCompleted: () { Navigator.pop(context); _loadStats(); },
          )),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _dcDone
                  ? [const Color(0xFF1a3a2a), const Color(0xFF1a2a1a)]
                  : [const Color(0xFF2a1a3a), const Color(0xFF1a1040)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _dcDone ? const Color(0xFF51CF66).withAlpha(120) : const Color(0xFFFFD93D).withAlpha(120),
              width: 1.5,
            ),
          ),
          child: Row(children: [
            Text(_dcDone ? '✅' : '⚡', style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _dcDone ? 'Daily Challenge Done!' : '⚡ Daily Challenge',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900,
                  color: _dcDone ? const Color(0xFF51CF66) : const Color(0xFFFFD93D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dcDone ? 'Come back tomorrow for a new one' : 'A new puzzle every day — tap to play!',
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(115)),
              ),
            ])),
            const SizedBox(width: 8),
            if (_dcStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(80)),
                ),
                child: Text('🔥 $_dcStreak', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B))),
              )
            else
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
          ]),
        ),
      ),
    );
  }

  Widget _trophyRoomButton() {
    final total = allBadges.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BadgesScreen()),
        ).then((_) => _loadStats()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD93D).withAlpha(60)),
          ),
          child: Row(children: [
            const Text('🏅', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Trophy Room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('$_badgeCount / $total badges earned',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(102))),
            ])),
            // Mini badge progress bar
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total > 0 ? _badgeCount / total : 0,
                  minHeight: 7,
                  backgroundColor: Colors.white.withAlpha(18),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD93D)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('›', style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(64))),
          ]),
        ),
      ),
    );
  }

  Widget _wordBuilderCard() {
    const accentColor = Color(0xFF20C997);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordBuilderScreen(onBack: () => Navigator.pop(context)),
        ),
      ).then((_) => _loadStats()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(33)),
        ),
        child: Stack(children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: const Center(child: Text('🔡', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Word Builder',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Tap letter tiles to spell 3–4 letter words — 10 words per session',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(122), height: 1.4)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    for (final t in ['🔡 Spelling', '🔊 Voice', '🎉 Badges', 'Ages 4–7'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(140))),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _countingCard() {
    const accentColor = Color(0xFF74C0FC);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CountingScreen(onBack: () => Navigator.pop(context)),
        ),
      ).then((_) => _loadStats()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(33)),
        ),
        child: Stack(children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: const Center(child: Text('🔢', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Counting Fun',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Count emoji objects and tap the right number — Easy (1–5) or Hard (1–10)',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(122), height: 1.4)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    for (final t in ['🔢 Counting', '🔊 Voice', '😊 Easy/Hard', 'Ages 2–5'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(140))),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
            ]),
          ),
        ]),
      ),
    );
  }

  // _nurseryRhymeCard() removed — re-add from nursery_rhyme_screen.dart when mp3 files are ready

  Widget _puzzleCard() {
    const accentColor = Color(0xFFFF922B);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PuzzleScreen(onBack: () => Navigator.pop(context)),
        ),
      ).then((_) => _loadStats()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(33)),
        ),
        child: Stack(children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: const Center(child: Text('🧩', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Puzzle Pieces',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Slide tiles to solve 4 emoji scenes — Farm, Ocean, Space & Jungle',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(122), height: 1.4)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    for (final t in ['🧩 Slide', '4 Scenes', '⚡ Badges', 'Ages 4–10'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(140))),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _coloringBookCard() {
    const accentColor = Color(0xFFFF80AB);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ColoringBookScreen(onBack: () => Navigator.pop(context)),
        ),
      ).then((_) => _loadStats()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(33)),
        ),
        child: Stack(children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: const Center(child: Text('🎨', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Coloring Book',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Tap regions to color 5 scenes — sun, cat, house, flower & fish',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(122), height: 1.4)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    for (final t in ['🎨 5 Scenes', '12 Colors', '🖼 Complete', 'Ages 2–5'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(140))),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _parentZoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentDashboardScreen(onBack: () => Navigator.pop(context)),
          ),
        ).then((_) => _loadStats()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(22)),
          ),
          child: Row(children: [
            const Text('👨‍👩‍👧', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Parent Dashboard',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70)),
              Text('View learning progress & manage settings',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(80))),
            ])),
            const Text('🔒', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text('›', style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(50))),
          ]),
        ),
      ),
    );
  }

  Widget _memoryCard() {
    const accentColor = Color(0xFF845EF7);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemoryGameScreen(onBack: () => Navigator.pop(context)),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(33)),
        ),
        child: Stack(children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: const Center(child: Text('🃏', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Memory Match',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Flip cards and match letter + emoji pairs — 3 difficulty levels',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(122), height: 1.4)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    for (final t in ['🃏 Easy–Hard', '🔤 Letters', '⏱ Timed', 'Ages 2–8'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: Colors.white.withAlpha(140),
                            )),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Star {
  final double x, y, size;
  final Duration duration;
  final Duration delay;
  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 1 + rng.nextDouble() * 2,
        duration = Duration(milliseconds: 2000 + rng.nextInt(4000)),
        delay = Duration(milliseconds: rng.nextInt(4000));
}

class _StarWidget extends StatefulWidget {
  final _Star star;
  const _StarWidget({required this.star});

  @override
  State<_StarWidget> createState() => _StarWidgetState();
}

class _StarWidgetState extends State<_StarWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.star.duration)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.08, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.star.size,
          height: widget.star.size,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
