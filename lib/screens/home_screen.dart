import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/daily_challenge_service.dart';
import '../utils/app_state.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import 'memory_game_screen.dart';
import 'word_builder_screen.dart';
import 'counting_screen.dart';
import 'coloring_book_screen.dart';
import 'puzzle_screen.dart';
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
  static const _mascots = ['🦉', '🎓', '🤩', '🐸', '⭐', '🦄', '🐨', '🚀', '🌈', '🎉'];

  String _childName = '';
  String abcScore   = '—';
  String mathScore  = '—';
  String storiesRead = '—';
  bool _dcDone  = false;
  int  _dcStreak = 0;
  int  _badgeCount = 0;

  final _rng = Random();
  final _sfx = SoundService();
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(65, (_) => _Star(_rng));

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -7)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _mascotBounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _mascotBounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _mascotBounceCtrl, curve: Curves.easeInOut));

    AppState.mascot = _mascots[_mascotIdx];
    widget.tabNotifier.addListener(_onTabChange);
    _loadStats();
    _loadChildName();
  }

  void _onTabChange() {
    if (widget.tabNotifier.value == 0) _loadStats();
  }

  Future<void> _loadChildName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('child_name') ?? '';
    if (!mounted) return;
    setState(() => _childName = name);
    AppState.childName = name;
    if (name.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNameDialog());
    }
  }

  Future<void> _loadStats() async {
    final prefs     = await SharedPreferences.getInstance();
    final dcDone    = await DailyChallengeService().isCompletedToday();
    final dcStreak  = await DailyChallengeService().getStreak();
    await BadgeService().load();
    await AppState.loadStars();
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
        title: const Text('Reset Progress?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
            'This will clear all scores, learned letters and completed stories.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800)),
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

  // ── Name dialog ────────────────────────────────────────────────────────────

  void _showNameDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: const Color(0xFF1a1040),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('👋', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            const Text("What's your name?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 6),
            Text("We'll use it to make the app feel special!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(150))),
            const SizedBox(height: 22),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: "Enter child's name…",
                hintStyle: TextStyle(color: Colors.white.withAlpha(80), fontSize: 14),
                filled: true,
                fillColor: Colors.white.withAlpha(20),
                counterStyle: TextStyle(color: Colors.white.withAlpha(60)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: StatefulBuilder(builder: (ctx, setSt) {
                return ElevatedButton(
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('child_name', name);
                    if (!mounted) return;
                    setState(() { _childName = name; AppState.childName = name; });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD93D),
                    foregroundColor: const Color(0xFF1a0533),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Let's Go! 🚀",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Twinkling star background
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
          child: Column(children: [
            _header(),
            _dailyChallengeCard(),
            _statsRow(),
            _trophyRoomButton(),
            const SizedBox(height: 4),
            _activityGrid(),
            const SizedBox(height: 14),
            _parentZoneButton(),
            const SizedBox(height: 16),
            Text('🌟 Made with love for young learners • v1.0',
                style: TextStyle(color: Colors.white.withAlpha(46), fontSize: 11)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _confirmReset,
              child: Text('Reset Progress',
                  style: TextStyle(
                      color: Colors.white.withAlpha(38),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withAlpha(38))),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ]);
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header() {
    final hasName = _childName.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
      child: Column(children: [
        GestureDetector(
          onTap: () {
            final next = (_mascotIdx + 1) % _mascots.length;
            setState(() => _mascotIdx = next);
            AppState.mascot = _mascots[next];
            _mascotBounceCtrl.forward(from: 0);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_floatAnim, _mascotBounceAnim]),
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: Transform.scale(
                scale: _mascotBounceAnim.value,
                child: Text(_mascots[_mascotIdx],
                    style: const TextStyle(fontSize: 60)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (hasName)
          Text('Hi, $_childName! 👋',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))
        else
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [
              Color(0xFFFFD93D), Color(0xFFFF6B6B),
              Color(0xFF6BCB77), Color(0xFF4D96FF),
            ]).createShader(bounds),
            child: const Text('Little Learners',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        const SizedBox(height: 4),
        Text(
          hasName ? 'Ready to learn and play? 🌟' : '8 fun activities · Tap to start!',
          style: TextStyle(color: Colors.white.withAlpha(115), fontSize: 13),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFD93D), Color(0xFFFF9F43)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x44FFD93D), blurRadius: 10)
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text('${AppState.totalStars} stars',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1a0533))),
          ]),
        ),
      ]),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(children: [
        _statPill(abcScore, 'ABC'),
        const SizedBox(width: 8),
        _statPill(mathScore, 'Math'),
        const SizedBox(width: 8),
        _statPill(storiesRead, 'Stories'),
      ]),
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
        child: Column(children: [
          Text(num,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFFFD93D))),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(97))),
        ]),
      ),
    );
  }

  // ── Trophy room ────────────────────────────────────────────────────────────

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
              const Text('Trophy Room',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('$_badgeCount / $total badges earned',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(102))),
            ])),
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

  // ── Daily challenge ────────────────────────────────────────────────────────

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
            gradient: LinearGradient(colors: _dcDone
                ? [const Color(0xFF1a3a2a), const Color(0xFF1a2a1a)]
                : [const Color(0xFF2a1a3a), const Color(0xFF1a1040)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _dcDone
                  ? const Color(0xFF51CF66).withAlpha(120)
                  : const Color(0xFFFFD93D).withAlpha(120),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _dcDone ? const Color(0xFF51CF66) : const Color(0xFFFFD93D)),
              ),
              const SizedBox(height: 2),
              Text(
                _dcDone
                    ? 'Come back tomorrow for a new one'
                    : 'A new puzzle every day — tap to play!',
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
                child: Text('🔥 $_dcStreak',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF6B6B))),
              )
            else
              Text('›', style: TextStyle(fontSize: 22, color: Colors.white.withAlpha(64))),
          ]),
        ),
      ),
    );
  }

  // ── Activity grid ──────────────────────────────────────────────────────────

  Widget _activityGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          _gridCard(
            emoji: '🔤', name: 'ABC & Phonics',
            colors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
            progress: abcScore,
            onTap: () => widget.onTabSelected(1),
          ),
          _gridCard(
            emoji: '🔢', name: 'Math Quiz',
            colors: [const Color(0xFFFFD93D), const Color(0xFFFF922B)],
            progress: mathScore,
            onTap: () => widget.onTabSelected(2),
          ),
          _gridCard(
            emoji: '📚', name: 'Moral Stories',
            colors: [const Color(0xFFc4855a), const Color(0xFF7B3F00)],
            progress: storiesRead != '—' ? '$storiesRead read' : null,
            onTap: () => widget.onTabSelected(3),
          ),
          _gridCard(
            emoji: '🃏', name: 'Memory Match',
            colors: [const Color(0xFF845EF7), const Color(0xFFD63ECA)],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MemoryGameScreen(onBack: () => Navigator.pop(context)))),
          ),
          _gridCard(
            emoji: '🔡', name: 'Word Builder',
            colors: [const Color(0xFF20C997), const Color(0xFF12B886)],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => WordBuilderScreen(onBack: () => Navigator.pop(context)))).then((_) => _loadStats()),
          ),
          _gridCard(
            emoji: '🔢', name: 'Counting Fun',
            colors: [const Color(0xFF4D96FF), const Color(0xFF228BE6)],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CountingScreen(onBack: () => Navigator.pop(context)))).then((_) => _loadStats()),
          ),
          _gridCard(
            emoji: '🎨', name: 'Coloring Book',
            colors: [const Color(0xFFFF80AB), const Color(0xFFE91E8C)],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ColoringBookScreen(onBack: () => Navigator.pop(context)))).then((_) => _loadStats()),
          ),
          _gridCard(
            emoji: '🧩', name: 'Puzzle Pieces',
            colors: [const Color(0xFFFF922B), const Color(0xFFFC5C7D)],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PuzzleScreen(onBack: () => Navigator.pop(context)))).then((_) => _loadStats()),
          ),
        ],
      ),
    );
  }

  Widget _gridCard({
    required String emoji,
    required String name,
    required List<Color> colors,
    required VoidCallback onTap,
    String? progress,
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
          // Progress badge
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

  // ── Parent zone ────────────────────────────────────────────────────────────

  Widget _parentZoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ParentDashboardScreen(onBack: () => Navigator.pop(context))),
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
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70)),
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
}

// ── Star background ─────────────────────────────────────────────────────────

class _Star {
  final double x, y, size;
  final Duration duration;
  final Color color;

  static const _palette = [
    Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF),
    Color(0xFFFFD93D), Color(0xFFFF9F43),
    Color(0xFF4D96FF), Color(0xFFc471f5), Color(0xFF6BCB77),
  ];

  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 5 + rng.nextDouble() * 13,
        duration = Duration(milliseconds: 1400 + rng.nextInt(3600)),
        color = _palette[rng.nextInt(_palette.length)];
}

class _StarWidget extends StatefulWidget {
  final _Star star;
  const _StarWidget({required this.star});

  @override
  State<_StarWidget> createState() => _StarWidgetState();
}

class _StarWidgetState extends State<_StarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.star.duration)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.15, end: 1.0).animate(_ctrl);
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
      builder: (_, w) => Opacity(
        opacity: _anim.value,
        child: Text(widget.star.size > 14 ? '★' : '✦',
            style: TextStyle(
                fontSize: widget.star.size,
                color: widget.star.color)),
      ),
    );
  }
}
