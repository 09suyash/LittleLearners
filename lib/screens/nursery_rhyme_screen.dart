import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/app_state.dart';

// ── Data ────────────────────────────────────────────────────────────────

class _TimedLine {
  final double startSec; // when this line starts in the audio
  final String text;
  const _TimedLine(this.startSec, this.text);
}

class _Rhyme {
  final String title, emoji, file; // file = path inside assets/
  final List<_TimedLine> lines;
  const _Rhyme(this.title, this.emoji, this.file, this.lines);
}

// Timestamps are approximate — adjust startSec values to match your mp3 files.
const _rhymes = [
  _Rhyme('Twinkle Twinkle', '⭐', 'audio/twinkle.mp3', [
    _TimedLine(0.0,  'Twinkle twinkle little star'),
    _TimedLine(5.0,  'How I wonder what you are'),
    _TimedLine(10.0, 'Up above the world so high'),
    _TimedLine(15.0, 'Like a diamond in the sky'),
    _TimedLine(20.0, 'Twinkle twinkle little star'),
    _TimedLine(25.0, 'How I wonder what you are'),
  ]),
  _Rhyme('BINGO', '🐕', 'audio/bingo.mp3', [
    _TimedLine(0.0,  'There was a farmer had a dog'),
    _TimedLine(5.5,  'And Bingo was his name oh'),
    _TimedLine(11.0, 'B - I - N - G - O'),
    _TimedLine(17.0, 'B - I - N - G - O'),
    _TimedLine(23.0, 'B - I - N - G - O'),
    _TimedLine(29.0, 'And Bingo was his name oh'),
  ]),
  _Rhyme('Wheels on the Bus', '🚌', 'audio/wheels.mp3', [
    _TimedLine(0.0,  'The wheels on the bus go round and round'),
    _TimedLine(6.0,  'Round and round, round and round'),
    _TimedLine(11.0, 'The wheels on the bus go round and round'),
    _TimedLine(17.0, 'All through the town'),
    _TimedLine(22.0, 'The wipers on the bus go swish swish swish'),
    _TimedLine(28.0, 'Swish swish swish, swish swish swish'),
    _TimedLine(33.0, 'The wipers on the bus go swish swish swish'),
    _TimedLine(39.0, 'All through the town'),
  ]),
  _Rhyme('Old MacDonald', '🐄', 'audio/old_macdonald.mp3', [
    _TimedLine(0.0,  'Old MacDonald had a farm'),
    _TimedLine(5.0,  'E - I - E - I - O'),
    _TimedLine(10.0, 'And on his farm he had a cow'),
    _TimedLine(15.0, 'E - I - E - I - O'),
    _TimedLine(20.0, 'With a moo moo here'),
    _TimedLine(24.0, 'And a moo moo there'),
    _TimedLine(28.0, 'Here a moo, there a moo'),
    _TimedLine(32.0, 'Everywhere a moo moo'),
    _TimedLine(36.0, 'Old MacDonald had a farm'),
    _TimedLine(41.0, 'E - I - E - I - O'),
  ]),
  _Rhyme('ABC Song', '🔤', 'audio/abc_song.mp3', [
    _TimedLine(0.0,  'A B C D E F G'),
    _TimedLine(6.0,  'H I J K L M N O P'),
    _TimedLine(12.0, 'Q R S  T U V'),
    _TimedLine(17.0, 'W X  Y and Z'),
    _TimedLine(23.0, 'Now I know my ABC'),
    _TimedLine(28.0, 'Next time won\'t you sing with me'),
  ]),
];

// ── Screen ──────────────────────────────────────────────────────────────

class NurseryRhymeScreen extends StatefulWidget {
  final VoidCallback onBack;
  const NurseryRhymeScreen({super.key, required this.onBack});

  @override
  State<NurseryRhymeScreen> createState() => _NurseryRhymeScreenState();
}

class _NurseryRhymeScreenState extends State<NurseryRhymeScreen> {
  final _bs     = BadgeService();
  final _player = AudioPlayer();
  final _scrollCtrl = ScrollController();
  final Set<int> _played = {};
  final Map<int, GlobalKey> _lineKeys = {};

  int      _rhymeIdx   = 0;
  bool     _isPlaying  = false;
  bool     _loading    = false;
  String?  _error;
  int      _currentLine = -1;
  Duration _position   = Duration.zero;
  Duration _duration   = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen(_onPosition);
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
    _player.onPlayerComplete.listen((_) => _onComplete());
  }

  @override
  void dispose() {
    _player.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Audio helpers ────────────────────────────────────────────────

  void _onPosition(Duration pos) {
    if (!mounted) return;
    final secs = pos.inMilliseconds / 1000.0;
    final lines = _rhymes[_rhymeIdx].lines;
    int active = -1;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (secs >= lines[i].startSec) { active = i; break; }
    }
    setState(() { _position = pos; if (active != _currentLine) { _currentLine = active; _scrollToLine(active); } });
  }

  Future<void> _onComplete() async {
    if (!mounted) return;
    setState(() { _isPlaying = false; _currentLine = -1; _position = Duration.zero; });
    _played.add(_rhymeIdx);
    await AppState.addStars(10);
    if (!mounted) return;
    await awardWithToast(context, _bs, 'rhyme_first');
    if (_played.length >= _rhymes.length && mounted) {
      await awardWithToast(context, _bs, 'rhyme_all', stars: 50);
    }
  }

  Future<void> _play() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _player.play(AssetSource(_rhymes[_rhymeIdx].file));
      if (mounted) setState(() { _isPlaying = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Audio file not found.\nAdd ${_rhymes[_rhymeIdx].file} to assets/audio/'; });
    }
  }

  Future<void> _pause() async {
    await _player.pause();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _resume() async {
    await _player.resume();
    if (mounted) setState(() => _isPlaying = true);
  }

  Future<void> _replay() async {
    await _player.stop();
    setState(() { _position = Duration.zero; _currentLine = -1; });
    await _play();
  }

  Future<void> _switchRhyme(int idx) async {
    await _player.stop();
    setState(() {
      _rhymeIdx    = idx;
      _isPlaying   = false;
      _currentLine = -1;
      _position    = Duration.zero;
      _duration    = Duration.zero;
      _error       = null;
      _lineKeys.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _scrollToLine(int li) {
    if (li < 0) return;
    final key = _lineKeys[li];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.35);
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rhyme = _rhymes[_rhymeIdx];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a0533), Color(0xFF2d1b69), Color(0xFF0d3b6e)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _header(),
          const SizedBox(height: 8),
          _rhymePicker(),
          const SizedBox(height: 16),
          Text(rhyme.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 6),
          Text(rhyme.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 14),
          Expanded(child: _lyricsArea()),
          if (_error != null) _errorBanner(),
          const SizedBox(height: 8),
          _progressBar(),
          const SizedBox(height: 12),
          _controls(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () async { await _player.stop(); widget.onBack(); },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🎵', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        const Expanded(child: Text('Nursery Rhymes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
      ]),
    );
  }

  Widget _rhymePicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemCount: _rhymes.length,
        itemBuilder: (_, i) {
          final sel = i == _rhymeIdx;
          return GestureDetector(
            onTap: () => _switchRhyme(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withAlpha(36) : Colors.white.withAlpha(14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? const Color(0xFFFFD93D) : Colors.white.withAlpha(30),
                  width: sel ? 2 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_rhymes[i].emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Text(_rhymes[i].title,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : Colors.white60)),
                if (_played.contains(i)) ...[
                  const SizedBox(width: 4),
                  const Text('✅', style: TextStyle(fontSize: 10)),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _lyricsArea() {
    final lines = _rhymes[_rhymeIdx].lines;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: lines.length,
      itemBuilder: (_, i) {
        _lineKeys[i] ??= GlobalKey();
        final hi = i == _currentLine;
        return Padding(
          key: _lineKeys[i],
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: hi
                ? BoxDecoration(
                    color: const Color(0xFFFFD93D).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD93D).withAlpha(80)),
                  )
                : const BoxDecoration(),
            child: Text(
              lines[i].text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: hi ? 22 : 19,
                fontWeight: hi ? FontWeight.w900 : FontWeight.w500,
                color: hi ? const Color(0xFFFFD93D) : Colors.white.withAlpha(180),
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _errorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(80)),
        ),
        child: Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _progressBar() {
    final total = _duration.inMilliseconds;
    final prog  = total > 0 ? (_position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
    String fmt(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: prog,
            minHeight: 5,
            backgroundColor: Colors.white.withAlpha(18),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD93D)),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text(fmt(_position), style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100))),
          const Spacer(),
          Text(fmt(_duration), style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100))),
        ]),
      ]),
    );
  }

  Widget _controls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Replay
      _ctrlBtn('⏮', size: 52, onTap: _replay),
      const SizedBox(width: 16),
      // Play / Pause
      GestureDetector(
        onTap: _loading ? null : (_isPlaying ? _pause : (_position > Duration.zero ? _resume : _play)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _loading
                ? Colors.white.withAlpha(30)
                : _isPlaying ? const Color(0xFFFF6B6B) : const Color(0xFFFFD93D),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isPlaying ? const Color(0xFFFF6B6B) : const Color(0xFFFFD93D)).withAlpha(80),
                blurRadius: 18, spreadRadius: 2,
              ),
            ],
          ),
          child: Center(child: _loading
              ? const SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(_isPlaying ? '⏸' : '▶',
                  style: TextStyle(fontSize: 28,
                      color: _isPlaying ? Colors.white : const Color(0xFF0d1b2a)))),
        ),
      ),
      const SizedBox(width: 16),
      // Next rhyme
      _ctrlBtn('⏭', size: 52, onTap: () => _switchRhyme((_rhymeIdx + 1) % _rhymes.length)),
    ]);
  }

  Widget _ctrlBtn(String label, {required double size, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(36)),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: size * 0.4))),
      ),
    );
  }
}
