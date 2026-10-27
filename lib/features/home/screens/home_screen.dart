import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zoodles/core/core.dart';
import '../../games/screens/word_builder_screen.dart';
import '../../games/screens/counting_screen.dart';
import '../../games/screens/animal_sound_quiz_screen.dart';
import '../../games/screens/games_screen.dart';
import '../../parent_dashboard/screens/parent_dashboard_screen.dart';
import '../../gamification/screens/daily_challenge_screen.dart';
import '../widgets/star_field_background.dart';
import '../widgets/home_stats_row.dart';
import '../widgets/home_header.dart';
import '../widgets/activity_card.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onTabSelected;
  final ValueNotifier<int> tabNotifier;
  const HomeScreen({
    super.key,
    required this.onTabSelected,
    required this.tabNotifier,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;
  late AnimationController _mascotBounceCtrl;
  late Animation<double> _mascotBounceAnim;

  int _mascotIdx = 0;
  static const _mascots = [
    '🦉',
    '🎓',
    '🤩',
    '🐸',
    '⭐',
    '🦄',
    '🐨',
    '🚀',
    '🌈',
    '🎉',
  ];

  String _childName = '';
  String abcScore = '—';
  String mathScore = '—';
  String storiesRead = '—';
  bool _dcDone = false;
  int _dcStreak = 0;
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: 0,
      end: -7,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _mascotBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _mascotBounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _mascotBounceCtrl, curve: Curves.easeInOut),
    );

    AppState.mascot = _mascots[_mascotIdx];
    widget.tabNotifier.addListener(_onTabChange);
    _loadStats();
    _loadChildName();
  }

  void _onTabChange() {
    if (widget.tabNotifier.value == 0) _loadStats();
  }

  Future<void> _loadChildName() async {
    final name = await ProgressRepository().getChildName();
    if (!mounted) return;
    setState(() => _childName = name);
    if (name.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNameDialog());
    }
  }

  Future<void> _loadStats() async {
    final overview = await ProgressRepository().getOverview();
    final dcDone = await DailyChallengeService().isCompletedToday();
    final dcStreak = await DailyChallengeService().getStreak();
    await BadgeService().load();
    await AppState.loadStars();
    if (!mounted) return;
    setState(() {
      abcScore = overview.abcLearned > 0 ? '${overview.abcLearned}/26' : '—';
      mathScore = overview.mathBest >= 0
          ? '${overview.mathBest}/${overview.mathBestTotal}'
          : '—';
      storiesRead = overview.storiesRead > 0 ? '${overview.storiesRead}' : '—';
      _dcDone = dcDone;
      _dcStreak = dcStreak;
      _badgeCount = BadgeService().earned.length;
    });
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Reset Progress?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will clear all scores, learned letters and completed stories.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ProgressRepository().resetAll();
    _loadStats();
  }

  @override
  void dispose() {
    widget.tabNotifier.removeListener(_onTabChange);
    _floatCtrl.dispose();
    _mascotBounceCtrl.dispose();
    super.dispose();
  }

  void _showNameDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: const Color(0xFF1a1040),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              const Text(
                "What's your name?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "We'll use it to make the app feel special!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(150),
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: "Enter child's name…",
                  hintStyle: TextStyle(
                    color: Colors.white.withAlpha(80),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(20),
                  counterStyle: TextStyle(color: Colors.white.withAlpha(60)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    await ProgressRepository().setChildName(name);
                    if (!mounted) return;
                    setState(() => _childName = name);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD93D),
                    foregroundColor: const Color(0xFF1a0533),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Let's Go! 🚀",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMascotTap() {
    final next = (_mascotIdx + 1) % _mascots.length;
    setState(() => _mascotIdx = next);
    AppState.mascot = _mascots[next];
    _mascotBounceCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const collapsedToolbar = 74.0;
    final collapsedHeight = topPad + collapsedToolbar;
    const expandedBarHeight = 335.0;

    return Stack(
      children: [
        const StarFieldBackground(count: 65),
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedBarHeight,
              collapsedHeight: collapsedToolbar,
              toolbarHeight: collapsedToolbar,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxExtent = expandedBarHeight + topPad;
                  final minExtent = collapsedHeight;
                  final t =
                      ((maxExtent - constraints.maxHeight) /
                              (maxExtent - minExtent))
                          .clamp(0.0, 1.0);

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: t,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0d0221).withAlpha(230),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withAlpha(
                                    (20 * t).round(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: (1.0 - t * 2.5).clamp(0.0, 1.0),
                          child: SafeArea(
                            bottom: false,
                            child: HomeExpandedHeader(
                              childName: _childName,
                              mascot: _mascots[_mascotIdx],
                              onMascotTap: _onMascotTap,
                              floatAnim: _floatAnim,
                              mascotBounceAnim: _mascotBounceAnim,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
                          child: HomeCollapsedHeader(
                            childName: _childName,
                            mascot: _mascots[_mascotIdx],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: DailyChallengeCard(
                isDone: _dcDone,
                streak: _dcStreak,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyChallengeScreen(
                      onBack: () => Navigator.pop(context),
                      onCompleted: () {
                        Navigator.pop(context);
                        _loadStats();
                      },
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeStatsRow(
                abcScore: abcScore,
                mathScore: mathScore,
                storiesRead: storiesRead,
              ),
            ),
            SliverToBoxAdapter(
              child: TrophyRoomButton(
                badgeCount: _badgeCount,
                onReturn: _loadStats,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(child: _buildActivityGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _buildGamesButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _buildParentZoneButton()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 6),
                child: Text(
                  '🌟 Made with love for young learners • v1.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(46),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _confirmReset,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Reset Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(38),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityGrid() {
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
          ActivityGridCard(
            emoji: '🔤',
            name: 'ABC & Phonics',
            imagePath: 'assets/images/abc_card.png',
            colors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            progress: abcScore,
            onTap: () => widget.onTabSelected(1),
          ),
          ActivityGridCard(
            emoji: '🔢',
            name: 'Math Quiz',
            imagePath: 'assets/images/math_card.png',
            colors: const [Color(0xFFFFD93D), Color(0xFFFF922B)],
            progress: mathScore,
            onTap: () => widget.onTabSelected(2),
          ),
          ActivityGridCard(
            emoji: '📚',
            name: 'Moral Stories',
            imagePath: 'assets/images/stories_card.png',
            colors: const [Color(0xFFc4855a), Color(0xFF7B3F00)],
            progress: storiesRead != '—' ? '$storiesRead read' : null,
            onTap: () => widget.onTabSelected(3),
          ),
          ActivityGridCard(
            emoji: '🔡',
            name: 'Word Builder',
            imagePath: 'assets/images/word_card.png',
            colors: const [Color(0xFF20C997), Color(0xFF12B886)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WordBuilderScreen(onBack: () => Navigator.pop(context)),
              ),
            ).then((_) => _loadStats()),
          ),
          ActivityGridCard(
            emoji: '🔢',
            name: 'Counting Fun',
            imagePath: 'assets/images/counting_card.png',
            colors: const [Color(0xFF4D96FF), Color(0xFF228BE6)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CountingScreen(onBack: () => Navigator.pop(context)),
              ),
            ).then((_) => _loadStats()),
          ),
          ActivityGridCard(
            emoji: '🐾',
            name: 'Animal Sounds',
            colors: const [Color(0xFF56AB2F), Color(0xFFA8E063)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AnimalSoundQuizScreen(onBack: () => Navigator.pop(context)),
              ),
            ).then((_) => _loadStats()),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GamesScreen(onBack: () => Navigator.pop(context)),
          ),
        ).then((_) => _loadStats()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFD63ECA)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x446C5CE7), blurRadius: 16),
            ],
          ),
          child: Row(
            children: [
              const Text('🎮', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Games',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '11 fun games to play!',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentZoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ParentDashboardScreen(onBack: () => Navigator.pop(context)),
          ),
        ).then((_) => _loadStats()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(22)),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/parent_card.svg',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parent Dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'View learning progress & manage settings',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(80),
                      ),
                    ),
                  ],
                ),
              ),
              const Text('🔒', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withAlpha(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
