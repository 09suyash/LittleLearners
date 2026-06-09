import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/letter_data.dart';
import '../utils/tts_service.dart';
import '../utils/badge_service.dart';

class MemoryGameScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MemoryGameScreen({super.key, required this.onBack});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final TtsService _tts = TtsService();
  final BadgeService _bs = BadgeService();
  final _rng = Random();

  // Difficulty: easy=4 pairs, med=6 pairs, hard=8 pairs
  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  int _diffIdx = 0;
  int get _pairs => [4, 6, 8][_diffIdx];

  late List<_Card> _cards;
  final List<int> _flipped = [];   // indices of currently face-up unmatched cards
  final Set<int> _matched = {};
  bool _busy = false;              // locked while mismatch animation plays
  bool _started = false;
  int _moves = 0;
  int _elapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _buildDeck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.dispose();
    super.dispose();
  }

  void _buildDeck() {
    final pool = List.of(letters)..shuffle(_rng);
    final picks = pool.take(_pairs).toList();
    // Each pick appears twice — letter card + emoji card
    _cards = [
      for (final d in picks) ...[
        _Card(id: d.letter, label: d.letter, isEmoji: false, color: d.color),
        _Card(id: d.letter, label: d.emoji,  isEmoji: true,  color: d.color),
      ]
    ]..shuffle(_rng);
    _flipped.clear();
    _matched.clear();
    _busy = false;
    _started = false;
    _moves = 0;
    _elapsed = 0;
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  void _tap(int idx) {
    if (_busy) return;
    if (_matched.contains(idx)) return;
    if (_flipped.contains(idx)) return;
    if (_flipped.length >= 2) return;

    if (!_started) {
      _started = true;
      _startTimer();
    }

    setState(() => _flipped.add(idx));
    _tts.speak(_cards[idx].isEmoji ? '' : _cards[idx].label, rate: 0.7, pitch: 1.3);

    if (_flipped.length == 2) {
      _moves++;
      final a = _flipped[0], b = _flipped[1];
      if (_cards[a].id == _cards[b].id) {
        // Match
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _matched.addAll([a, b]);
            _flipped.clear();
          });
          if (_matched.length == _cards.length) _onWin();
        });
      } else {
        // Mismatch — flip back after delay
        _busy = true;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() { _flipped.clear(); _busy = false; });
        });
      }
    }
  }

  void _onWin() {
    _timer?.cancel();
    _tts.speak('Amazing! You matched them all!');
    _bs.award('memory_first');
    if (_diffIdx == 2) _bs.award('memory_hard');
  }

  void _restart() {
    setState(() => _buildDeck());
  }

  bool get _won => _matched.length == _cards.length && _cards.isNotEmpty;

  String get _timeStr {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _buildHeader(),
          if (_won) _buildWinBanner(),
          Expanded(child: _won ? _buildWinActions() : _buildGrid()),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () { _timer?.cancel(); widget.onBack(); },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Text('←', style: TextStyle(color: Colors.white70, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🃏', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Memory Match',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        // Difficulty picker
        GestureDetector(
          onTap: () {
            if (_won || !_started) {
              setState(() {
                _diffIdx = (_diffIdx + 1) % 3;
                _buildDeck();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(36)),
            ),
            child: Text(_difficulties[_diffIdx],
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD93D))),
          ),
        ),
      ]),
    );
  }

  Widget _buildGrid() {
    // Stats row
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('🎯', 'Moves', '$_moves'),
          _statChip('⏱', 'Time', _timeStr),
          _statChip('✅', 'Matched', '${_matched.length ~/ 2}/$_pairs'),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _pairs <= 4 ? 4 : _pairs <= 6 ? 4 : 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _cards.length,
            itemBuilder: (_, i) => _buildCard(i),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _restart,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('🔄 New Game', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCard(int idx) {
    final card = _cards[idx];
    final isRevealed = _flipped.contains(idx) || _matched.contains(idx);
    final isMatched = _matched.contains(idx);

    return GestureDetector(
      onTap: () => _tap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isMatched
              ? card.color.withAlpha(40)
              : isRevealed
                  ? Colors.white.withAlpha(26)
                  : Colors.white.withAlpha(14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMatched
                ? card.color
                : isRevealed
                    ? Colors.white.withAlpha(80)
                    : Colors.white.withAlpha(26),
            width: isMatched ? 2 : 1.5,
          ),
          boxShadow: isMatched
              ? [BoxShadow(color: card.color.withAlpha(60), blurRadius: 10)]
              : null,
        ),
        child: Center(
          child: isRevealed
              ? Text(card.label,
                  style: TextStyle(
                    fontSize: card.isEmoji ? 30 : 28,
                    fontWeight: FontWeight.w900,
                    color: card.isEmoji ? null : Colors.white,
                  ))
              : Text('?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withAlpha(51),
                  )),
        ),
      ),
    );
  }

  Widget _statChip(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(89))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _buildWinBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [const BoxShadow(color: Color(0x44FFD93D), blurRadius: 20)],
      ),
      child: Column(children: [
        const Text('🎉', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 4),
        const Text('You matched them all!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text('$_moves moves • $_timeStr',
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
        const SizedBox(height: 4),
        const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
      ]),
    );
  }

  Widget _buildWinActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _restart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
            ),
            child: const Text('🔄 Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () { _timer?.cancel(); widget.onBack(); },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('🏠 Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _Card {
  final String id;
  final String label;
  final bool isEmoji;
  final Color color;
  const _Card({required this.id, required this.label, required this.isEmoji, required this.color});
}
