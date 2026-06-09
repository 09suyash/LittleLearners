import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/daily_challenge_service.dart';

// ── Screen ─────────────────────────────────────────────────────────────
class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ParentDashboardScreen({super.key, required this.onBack});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  // PIN state
  bool   _unlocked  = false;
  String? _savedPin;           // null = not set yet
  String _input     = '';
  String? _firstPin;           // used during set/confirm flow
  bool   _confirming = false;  // true = confirming new PIN
  bool   _pinError  = false;
  bool   _changing  = false;   // true = change-PIN flow from dashboard

  // Stats
  int _abcLearned   = 0;
  int _mathBest     = -1;
  int _mathTotal    = 10;
  int _blitzBest    = 0;
  int _storiesDone  = 0;
  int _dcStreak     = 0;
  int _badgeCount   = 0;
  Set<String> _earned = {};

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  // ── PIN helpers ─────────────────────────────────────────────────

  Future<void> _loadPin() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _savedPin = p.getString('parent_pin'));
  }

  void _digit(String d) {
    if (_input.length >= 4) return;
    setState(() { _input += d; _pinError = false; });
    if (_input.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _submit);
    }
  }

  void _back() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _submit() async {
    final p = await SharedPreferences.getInstance();

    if (_savedPin == null || _changing) {
      // ── Setting / changing PIN ──
      if (!_confirming) {
        setState(() { _firstPin = _input; _input = ''; _confirming = true; });
      } else {
        if (_input == _firstPin) {
          await p.setString('parent_pin', _input);
          setState(() {
            _savedPin    = _input;
            _changing    = false;
            _confirming  = false;
            _firstPin    = null;
            _input       = '';
            if (!_unlocked) { _unlocked = true; _loadStats(); }
          });
        } else {
          setState(() { _pinError = true; _input = ''; _confirming = false; _firstPin = null; });
        }
      }
    } else {
      // ── Verifying existing PIN ──
      if (_input == _savedPin) {
        setState(() { _unlocked = true; _input = ''; });
        _loadStats();
      } else {
        setState(() { _pinError = true; _input = ''; });
      }
    }
  }

  Future<void> _loadStats() async {
    final p = await SharedPreferences.getInstance();
    await BadgeService().load();
    final streak = await DailyChallengeService().getStreak();
    if (!mounted) return;
    setState(() {
      _abcLearned  = p.getInt('abc_learned') ?? 0;
      _mathBest    = p.getInt('math_best') ?? -1;
      _mathTotal   = p.getInt('math_best_total') ?? 10;
      _blitzBest   = p.getInt('blitz_best') ?? 0;
      _storiesDone = p.getStringList('stories_done')?.length ?? 0;
      _dcStreak    = streak;
      _earned      = BadgeService().earned;
      _badgeCount  = _earned.length;
    });
  }

  Future<void> _removePin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Remove PIN?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Anyone will be able to open the Parent Dashboard.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok != true) return;
    final p = await SharedPreferences.getInstance();
    await p.remove('parent_pin');
    setState(() => _savedPin = null);
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF2d1b69)],
        ),
      ),
      child: SafeArea(
        child: _unlocked && !_changing ? _buildDashboard() : _buildPinScreen(),
      ),
    );
  }

  // ── PIN Screen ────────────────────────────────────────────────────

  Widget _buildPinScreen() {
    String title, sub;
    if (_savedPin == null || _changing) {
      title = _confirming ? 'Confirm PIN' : 'Create a PIN';
      sub   = _confirming ? 'Enter the same PIN again' : 'Choose a 4-digit PIN for parents';
    } else {
      title = 'Parent Zone 🔒';
      sub   = 'Enter your 4-digit PIN';
    }

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(children: [
          GestureDetector(
            onTap: () {
              if (_changing) { setState(() { _changing = false; _confirming = false; _firstPin = null; _input = ''; }); }
              else { widget.onBack(); }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
              child: const Text('←', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          const Text('Parent Dashboard',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
        ]),
      ),
      const Spacer(),
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 8),
      Text(sub, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(140))),
      const SizedBox(height: 32),
      // Dots
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
        final filled = i < _input.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18, height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pinError
                ? const Color(0xFFFF6B6B)
                : filled ? const Color(0xFFFFD93D) : Colors.white.withAlpha(40),
            border: Border.all(
              color: _pinError ? const Color(0xFFFF6B6B) : Colors.white.withAlpha(80),
              width: 2,
            ),
          ),
        );
      })),
      if (_pinError) ...[
        const SizedBox(height: 10),
        Text(_confirming ? 'PINs don\'t match. Try again.' : 'Incorrect PIN.',
            style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.w700)),
      ],
      const SizedBox(height: 40),
      // Keypad
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Column(children: [
          _keyRow(['1','2','3']),
          const SizedBox(height: 12),
          _keyRow(['4','5','6']),
          const SizedBox(height: 12),
          _keyRow(['7','8','9']),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 72),
            const SizedBox(width: 12),
            _keyBtn('0'),
            const SizedBox(width: 12),
            _keyBtn('⌫', onTap: _back, accent: true),
          ]),
        ]),
      ),
      const Spacer(),
    ]);
  }

  Widget _keyRow(List<String> keys) {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: keys.expand((k) => [_keyBtn(k), const SizedBox(width: 12)]).toList()..removeLast());
  }

  Widget _keyBtn(String label, {VoidCallback? onTap, bool accent = false}) {
    return GestureDetector(
      onTap: onTap ?? () => _digit(label),
      child: Container(
        width: 72, height: 60,
        decoration: BoxDecoration(
          color: accent ? Colors.white.withAlpha(10) : Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(36)),
        ),
        child: Center(child: Text(label,
            style: TextStyle(
              fontSize: label.length == 1 ? 22 : 18,
              fontWeight: FontWeight.w700,
              color: accent ? Colors.white60 : Colors.white,
            ))),
      ),
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────

  Widget _buildDashboard() {
    return Column(children: [
      _dashHeader(),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        child: Column(children: [
          _section('📚 Learning Progress', [
            _statCard('🔤', 'ABC', '$_abcLearned / 26\nLetters learned', _abcLearned / 26),
            _statCard('🔢', 'Math Quiz',
                _mathBest >= 0 ? '$_mathBest / $_mathTotal\nBest score' : 'Not played yet', _mathBest >= 0 ? _mathBest / _mathTotal : 0),
            _statCard('📚', 'Stories', '$_storiesDone / 8\nCompleted', _storiesDone / 8),
          ]),
          _section('⚡ Daily Challenge', [
            _statCard('🔥', 'Streak', '$_dcStreak days', _dcStreak > 0 ? 1.0 : 0),
            _statCard('⚡', 'Blitz Best', _blitzBest > 0 ? '$_blitzBest pts' : 'Not played', _blitzBest > 0 ? 1.0 : 0),
            _statCard('🏅', 'Badges', '$_badgeCount / ${allBadges.length}', _badgeCount / allBadges.length),
          ]),
          _section('🎮 Mini-games Tried', [
            _badgeCard('🃏', 'Memory',    'memory_first', 'memory_hard', 'Hard mode'),
            _badgeCard('🔡', 'Words',     'word_first',   'word_10',     'All 10'),
            _badgeCard('🔢', 'Counting',  'count_first',  'count_perfect', 'Perfect'),
            _badgeCard('🎨', 'Coloring',  'color_first',  'color_scene', 'Scene done'),
            _badgeCard('🧩', 'Puzzle',    'puzzle_first', 'puzzle_fast', 'Speed solver'),
            _badgeCard('🎵', 'Rhymes',    'rhyme_first',  'rhyme_all',   'All 5'),
          ]),
          const SizedBox(height: 16),
          _pinActions(),
        ]),
      )),
    ]);
  }

  Widget _dashHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Text('←', style: TextStyle(color: Colors.white70, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('👨‍👩‍👧', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        const Expanded(child: Text('Parent Dashboard',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white))),
        GestureDetector(
          onTap: () => setState(() { _unlocked = false; _input = ''; }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: const Text('🔒 Lock', style: TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title, List<Widget> cards) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
        child: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                color: Colors.white70, letterSpacing: 0.5)),
      ),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
        children: cards,
      ),
    ]);
  }

  Widget _statCard(String emoji, String label, String value, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value.split('\n')[0],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        if (value.contains('\n'))
          Text(value.split('\n')[1],
              style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(100))),
        const Spacer(),
        if (progress > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withAlpha(18),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD93D)),
            ),
          ),
      ]),
    );
  }

  Widget _badgeCard(String emoji, String label, String badge1, String badge2, String badge2Label) {
    final tried     = _earned.contains(badge1);
    final mastered  = _earned.contains(badge2);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(tried ? 20 : 10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mastered ? const Color(0xFFFFD93D).withAlpha(100) : Colors.white.withAlpha(18),
          width: mastered ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Text(tried ? '✅' : '○', style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(120))),
        ]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(tried ? (mastered ? '⚡ $badge2Label' : 'Played') : 'Not yet',
            style: TextStyle(
              fontSize: 9,
              color: mastered ? const Color(0xFFFFD93D) : Colors.white.withAlpha(100),
              fontWeight: mastered ? FontWeight.w700 : FontWeight.normal,
            )),
      ]),
    );
  }

  Widget _pinActions() {
    return Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: () => setState(() { _changing = true; _confirming = false; _firstPin = null; _input = ''; _pinError = false; }),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('🔑 Change PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      )),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton(
        onPressed: _removePin,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF6B6B),
          side: const BorderSide(color: Color(0xFFFF6B6B), width: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('🗑 Remove PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      )),
    ]);
  }
}
