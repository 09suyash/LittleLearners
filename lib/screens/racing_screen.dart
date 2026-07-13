import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/app_state.dart';

enum _GameState { vehiclePicker, modeSelect, playing, roundOver }
enum _Mode { laneSprint, wordRace, mathDash }

class _Tile {
  final int lane;
  final String label;
  final bool isTarget;
  final bool isObstacle;
  final int spawnMs;
  const _Tile({
    required this.lane,
    required this.label,
    required this.isTarget,
    this.isObstacle = false,
    required this.spawnMs,
  });
}

class RacingScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RacingScreen({super.key, required this.onBack});

  @override
  State<RacingScreen> createState() => _RacingScreenState();
}

class _RacingScreenState extends State<RacingScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final _rng = Random();

  static const _vehicles = ['🚗', '🏍️', '🚲'];
  static const _modeNames = ['Lane Sprint', 'Word Race', 'Math Dash'];
  static const _modeDescs = [
    'Collect the right letter or number',
    'Spell the target word in order',
    'Solve the math problem',
  ];
  static const _modeEmojis = ['🔤', '🔡', '➗'];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  static const _waveDurationMs = [3200, 2400, 1700];
  static const _waveGapMs = [700, 500, 350];
  static const _totalPrompts = [10, 14, 18];
  static const _roundSeconds = [42, 43, 40];
  static const _catchWindowStart = 0.80;
  static const _wordRaceMaxWaves = 20;
  static const _obstacleChance = [0.25, 0.4, 0.55];
  static const _obstacleEmojis = ['🚧', '🪨'];

  static const _easyLetters = ['A','B','C','D','E','F','G','H','K','M','S','T'];
  static const _allLetters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];
  static const _digits = ['0','1','2','3','4','5','6','7','8','9'];
  static const _words3 = ['CAT', 'DOG', 'SUN', 'BUS'];
  static const _words4 = ['FROG', 'STAR', 'FISH', 'MOON'];

  _GameState _state = _GameState.vehiclePicker;
  String _vehicle = _vehicles[0];
  _Mode? _mode;
  int _diffIdx = 0;

  int _playerLane = 1;
  List<_Tile> _wave = [];
  int _elapsedMs = 0;
  int _waveSpawnMs = 0;
  int _lastWaveEndMs = 0;
  int _waveCount = 0;
  int _score = 0;
  int _missCount = 0;
  int _obstacleHits = 0;
  bool _obstacleHitThisWave = false;
  int _lastCatchMs = -9999;
  int _lastObstacleHitMs = -9999;
  List<double> _rivalProgress = [0.0, 0.0];
  int _finishPlace = 1;
  bool _sparkle = false;
  Timer? _ticker;

  String _target = '';
  String _mathDisplay = '';
  String _targetWord = '';
  int _wordIdx = 0;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = prefs.getString('racing_vehicle');
    if (saved != null && _vehicles.contains(saved)) {
      setState(() => _vehicle = saved);
    }
  }

  Future<void> _saveVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('racing_vehicle', _vehicle);
  }

  // ── Math helpers ──
  (String, int) _genMathProblem() {
    final maxOp = [5, 8, 10][_diffIdx];
    final useSub = _diffIdx > 0 && _rng.nextBool();
    if (useSub) {
      final a = _rng.nextInt(maxOp) + 2;
      final b = _rng.nextInt(a - 1) + 1;
      return ('$a − $b = ?', a - b);
    }
    final a = _rng.nextInt(maxOp) + 1;
    final b = _rng.nextInt(maxOp) + 1;
    return ('$a + $b = ?', a + b);
  }

  List<int> _genNumChoices(int ans, int count) {
    final s = <int>{ans};
    int t = 0;
    while (s.length < count && t < 60) {
      final d = _rng.nextInt(max(4, (ans.abs() * 0.4).round()) + 1) + 1;
      final c = ans + (_rng.nextBool() ? d : -d);
      if (c >= 0 && c != ans) s.add(c);
      t++;
    }
    for (int x = 1; s.length < count; x++) {
      if (ans + x >= 0) s.add(ans + x);
    }
    return s.toList()..shuffle(_rng);
  }

  String _pickWord() {
    final pool = _diffIdx == 0 ? _words3 : _diffIdx == 2 ? _words4 : [..._words3, ..._words4];
    return pool[_rng.nextInt(pool.length)];
  }

  // ── Round lifecycle ──
  void _startRound(_Mode mode) {
    _mode = mode;
    _sfx.play(SoundType.vroom);
    if (mode == _Mode.wordRace) {
      _targetWord = _pickWord();
      _wordIdx = 0;
    }
    setState(() {
      _playerLane = 1;
      _score = 0;
      _missCount = 0;
      _obstacleHits = 0;
      _obstacleHitThisWave = false;
      _lastCatchMs = -9999;
      _lastObstacleHitMs = -9999;
      _rivalProgress = [0.0, 0.0];
      _waveCount = 0;
      _elapsedMs = 0;
      _lastWaveEndMs = 0;
      _wave = [];
      _state = _GameState.playing;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _spawnWave() {
    _waveSpawnMs = _elapsedMs;
    String targetLabel;
    List<String> otherLabels;

    if (_mode == _Mode.laneSprint) {
      final isLetter = _rng.nextBool();
      final pool = isLetter ? (_diffIdx == 0 ? _easyLetters : _allLetters) : _digits;
      targetLabel = pool[_rng.nextInt(pool.length)];
      final rest = List<String>.from(pool)..remove(targetLabel);
      rest.shuffle(_rng);
      otherLabels = rest.take(2).toList();
      _target = targetLabel;
    } else if (_mode == _Mode.wordRace) {
      targetLabel = _targetWord[_wordIdx];
      final rest = List<String>.from(_allLetters)..remove(targetLabel);
      rest.shuffle(_rng);
      otherLabels = rest.take(2).toList();
      _target = targetLabel;
    } else {
      final (display, answer) = _genMathProblem();
      _mathDisplay = display;
      targetLabel = '$answer';
      final choices = _genNumChoices(answer, 3);
      otherLabels = choices.where((c) => c != answer).map((c) => '$c').take(2).toList();
      _target = targetLabel;
    }

    final lanes = [0, 1, 2]..shuffle(_rng);
    final targetLane = lanes[0];
    final otherLaneA = lanes[1];
    final otherLaneB = lanes[2];

    _obstacleHitThisWave = false;
    int? obstacleLane;
    if (_rng.nextDouble() < _obstacleChance[_diffIdx]) {
      obstacleLane = _rng.nextBool() ? otherLaneA : otherLaneB;
    }

    _wave = [
      _Tile(lane: targetLane, label: targetLabel, isTarget: true, spawnMs: _elapsedMs),
      obstacleLane == otherLaneA
          ? _Tile(lane: otherLaneA, label: _obstacleEmojis[_rng.nextInt(_obstacleEmojis.length)], isTarget: false, isObstacle: true, spawnMs: _elapsedMs)
          : _Tile(lane: otherLaneA, label: otherLabels[0], isTarget: false, spawnMs: _elapsedMs),
      obstacleLane == otherLaneB
          ? _Tile(lane: otherLaneB, label: _obstacleEmojis[_rng.nextInt(_obstacleEmojis.length)], isTarget: false, isObstacle: true, spawnMs: _elapsedMs)
          : _Tile(lane: otherLaneB, label: otherLabels[1], isTarget: false, spawnMs: _elapsedMs),
    ];
  }

  void _onCatch() {
    _wave = [];
    _lastWaveEndMs = _elapsedMs;
    _lastCatchMs = _elapsedMs;
    _score++;
    _waveCount++;
    _sparkle = true;
    _sfx.play(_mode == _Mode.wordRace ? SoundType.chime : SoundType.correct);
    if (_mode == _Mode.wordRace) _wordIdx++;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _sparkle = false);
    });
  }

  void _onMiss() {
    _wave = [];
    _lastWaveEndMs = _elapsedMs;
    _missCount++;
    _waveCount++;
  }

  void _onObstacleHit() {
    _obstacleHitThisWave = true;
    _obstacleHits++;
    _lastObstacleHitMs = _elapsedMs;
    _sfx.play(SoundType.buzz);
  }

  void _tick() {
    if (!mounted) return;
    bool waveResolved = false;
    setState(() {
      _elapsedMs += 50;
      // Rivals advance at a semi-random pace, purely cosmetic — never affects
      // score, wave count, or badge logic.
      final paceMs = (_waveDurationMs[_diffIdx] + _waveGapMs[_diffIdx]).toDouble();
      final totalRoundMs = paceMs * (_mode == _Mode.wordRace ? _wordRaceMaxWaves : _totalPrompts[_diffIdx]);
      for (int i = 0; i < _rivalProgress.length; i++) {
        _rivalProgress[i] = (_rivalProgress[i] + 50 / totalRoundMs * (0.8 + _rng.nextDouble() * 0.4)).clamp(0.0, 1.0);
      }
      if (_wave.isEmpty) {
        if (_elapsedMs - _lastWaveEndMs >= _waveGapMs[_diffIdx]) _spawnWave();
      } else {
        final progress = (_elapsedMs - _waveSpawnMs) / _waveDurationMs[_diffIdx];
        if (progress >= _catchWindowStart && progress < 1.0) {
          final target = _wave.firstWhere((t) => t.isTarget);
          if (_playerLane == target.lane) {
            _onCatch();
            waveResolved = true;
          } else if (!_obstacleHitThisWave &&
              _wave.any((t) => t.isObstacle && t.lane == _playerLane)) {
            _onObstacleHit();
          }
        }
        if (!waveResolved && progress >= 1.0) {
          _onMiss();
          waveResolved = true;
        }
      }
    });
    if (waveResolved) _checkRoundEnd();
  }

  void _checkRoundEnd() {
    final done = _mode == _Mode.wordRace
        ? (_wordIdx >= _targetWord.length || _waveCount >= _wordRaceMaxWaves)
        : _waveCount >= _totalPrompts[_diffIdx];
    if (done) _endRound();
  }

  void _moveLane(int delta) {
    if (_state != _GameState.playing) return;
    final next = (_playerLane + delta).clamp(0, 2);
    if (next == _playerLane) return;
    setState(() => _playerLane = next);
    _sfx.play(SoundType.slide);
  }

  Future<void> _endRound() async {
    _ticker?.cancel();
    final wordComplete = _mode == _Mode.wordRace && _wordIdx >= _targetWord.length;
    final metTarget = _mode == _Mode.wordRace
        ? wordComplete
        : _score >= (_totalPrompts[_diffIdx] * 0.6).ceil();

    final playerProgress = _mode == _Mode.wordRace
        ? (_targetWord.isEmpty ? 0.0 : _wordIdx / _targetWord.length)
        : _waveCount / _totalPrompts[_diffIdx];
    final standings = [playerProgress, ..._rivalProgress]..sort((a, b) => b.compareTo(a));
    _finishPlace = standings.indexOf(playerProgress) + 1;

    _sfx.play(metTarget ? SoundType.win : SoundType.correct);
    await AppState.addStars(metTarget ? 10 : 5);
    if (!mounted) return;
    setState(() {
      _wave = [];
      _state = _GameState.roundOver;
    });
    if (metTarget) {
      await awardWithToast(context, _bs, 'race_first');
    }
    if (_diffIdx == 2 && _missCount == 0 && _obstacleHits == 0 && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'race_ace', stars: 50);
    }
  }

  bool get _metTarget {
    if (_mode == _Mode.wordRace) return _wordIdx >= _targetWord.length;
    return _score >= (_totalPrompts[_diffIdx] * 0.6).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF232526), Color(0xFF414345)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.09, child: const Text('🏎️', style: TextStyle(fontSize: 140)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: switch (_state) {
                  _GameState.vehiclePicker => _buildVehiclePicker(),
                  _GameState.modeSelect => _buildModeSelect(),
                  _GameState.playing => _buildPlaying(),
                  _GameState.roundOver => _buildRoundOver(),
                },
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.roundOver && _metTarget),
      ConfettiOverlay(trigger: _state == _GameState.roundOver && _metTarget),
      SparkleBurst(trigger: _sparkle),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            _ticker?.cancel();
            switch (_state) {
              case _GameState.vehiclePicker:
                widget.onBack();
                break;
              case _GameState.modeSelect:
                setState(() => _state = _GameState.vehiclePicker);
                break;
              case _GameState.playing:
              case _GameState.roundOver:
                setState(() => _state = _GameState.modeSelect);
                break;
            }
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🏎️', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Racing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        if (_state == _GameState.modeSelect || _state == _GameState.roundOver)
          GestureDetector(
            onTap: () => setState(() => _diffIdx = (_diffIdx + 1) % 3),
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

  Widget _buildVehiclePicker() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Pick your ride!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < _vehicles.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TapScale(
                onTap: () {
                  setState(() {
                    _vehicle = _vehicles[i];
                    _state = _GameState.modeSelect;
                  });
                  _saveVehicle();
                },
                child: Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(_vehicle == _vehicles[i] ? 40 : 18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(60)),
                  ),
                  child: Center(child: Text(_vehicles[i], style: const TextStyle(fontSize: 40))),
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _buildModeSelect() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('$_vehicle  Ready to race!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 16),
        for (int i = 0; i < _Mode.values.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TapScale(
              onTap: () => _startRound(_Mode.values[i]),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(36)),
                ),
                child: Row(children: [
                  Text(_modeEmojis[i], style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_modeNames[i],
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text(_modeDescs[i],
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160))),
                  ])),
                  Text('›', style: TextStyle(fontSize: 20, color: Colors.white.withAlpha(140))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildPlaying() {
    final mode = _mode!;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip(_modeEmojis[mode.index], 'Mode', _modeNames[mode.index]),
          _statChip('🔁', 'Progress',
              mode == _Mode.wordRace ? '$_wordIdx/${_targetWord.length}' : '$_waveCount/${_totalPrompts[_diffIdx]}'),
          _statChip('⭐', 'Score', '$_score'),
        ]),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildRaceProgressBar(),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CountdownBar(seconds: _roundSeconds[_diffIdx], onFinish: _endRound),
      ),
      const SizedBox(height: 10),
      if (mode == _Mode.wordRace)
        _buildWordProgress()
      else
        Text(mode == _Mode.mathDash ? _mathDisplay : 'Collect: $_target',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildTrack(),
        ),
      ),
      _buildVehicleRow(),
      const SizedBox(height: 10),
      _buildControls(),
      const SizedBox(height: 14),
    ]);
  }

  Widget _buildWordProgress() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < _targetWord.length; i++)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 34, height: 40,
          decoration: BoxDecoration(
            color: i < _wordIdx ? const Color(0xFF51CF66).withAlpha(150) : Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: i == _wordIdx ? const Color(0xFFFFD93D) : Colors.white.withAlpha(60),
                width: i == _wordIdx ? 3 : 1.5),
          ),
          child: Center(
              child: Text(_targetWord[i],
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white))),
        ),
    ]);
  }

  Widget _buildRaceProgressBar() {
    final playerProgress = _mode == _Mode.wordRace
        ? (_targetWord.isEmpty ? 0.0 : _wordIdx / _targetWord.length)
        : _waveCount / _totalPrompts[_diffIdx];
    return SizedBox(
      height: 28,
      child: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withAlpha(16), borderRadius: BorderRadius.circular(10)),
          ),
        ),
        _raceMarker(_rivalProgress[0], '🚙'),
        _raceMarker(_rivalProgress[1], '🚕'),
        _raceMarker(playerProgress.clamp(0.0, 1.0), _vehicle),
      ]),
    );
  }

  Widget _raceMarker(double progress, String emoji) {
    return AnimatedAlign(
      alignment: Alignment(-1.0 + 2 * progress.clamp(0.0, 1.0), 0),
      duration: const Duration(milliseconds: 200),
      child: Align(alignment: Alignment.centerLeft, child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }

  Widget _buildTrack() {
    final shaking = _elapsedMs - _lastObstacleHitMs < 150;
    final shakeDx = shaking ? sin(_elapsedMs * 0.9) * 4 : 0.0;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      return Transform.translate(
        offset: Offset(shakeDx, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: w, height: h,
            color: Colors.white.withAlpha(8),
            child: Stack(children: [
              _buildLaneDashes(w, h, 0),
              _buildLaneDashes(w, h, 1),
              for (final t in _wave) _buildTileWidget(t, w, h),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildLaneDashes(double w, double h, int dividerIdx) {
    final x = w * (dividerIdx + 1) / 3;
    const dashH = 18.0, gap = 16.0, period = dashH + gap;
    final offset = (_elapsedMs * 0.12) % period;
    final dashes = <Widget>[];
    for (double y = -period + offset; y < h; y += period) {
      dashes.add(Positioned(left: x - 1, top: y, child: Container(width: 2, height: dashH, color: Colors.white.withAlpha(30))));
    }
    return Stack(children: dashes);
  }

  Widget _buildTileWidget(_Tile t, double w, double h) {
    const size = 56.0;
    final progress = ((_elapsedMs - t.spawnMs) / _waveDurationMs[_diffIdx]).clamp(0.0, 1.0);
    final laneCenterX = w * (t.lane + 0.5) / 3;
    final y = h * progress - size / 2;
    final x = (laneCenterX - size / 2).clamp(0, max(0, w - size));
    return Positioned(
      left: x.toDouble(), top: y,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.isObstacle ? const Color(0xFFFF9F43).withAlpha(180) : const Color(0xFF4D96FF).withAlpha(160),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
            child: Text(t.label,
                style: TextStyle(fontSize: t.isObstacle ? 26 : 20, fontWeight: FontWeight.w900, color: Colors.white))),
      ),
    );
  }

  Widget _buildVehicleRow() {
    final otherLanes = [0, 1, 2].where((l) => l != _playerLane).toList();
    final burstActive = _elapsedMs - _lastCatchMs < 300;
    final burstOpacity = burstActive ? (1 - (_elapsedMs - _lastCatchMs) / 300).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: 90,
      child: Stack(children: [
        Positioned.fill(child: Center(child: Container(height: 3, color: Colors.white.withAlpha(15)))),
        AnimatedAlign(
          alignment: Alignment(-1.0 + otherLanes[0] * 1.0, 0),
          duration: const Duration(milliseconds: 220),
          child: const Text('🚙', style: TextStyle(fontSize: 32)),
        ),
        AnimatedAlign(
          alignment: Alignment(-1.0 + otherLanes[1] * 1.0, 0),
          duration: const Duration(milliseconds: 220),
          child: const Text('🚕', style: TextStyle(fontSize: 32)),
        ),
        AnimatedAlign(
          alignment: Alignment(-1.0 + _playerLane * 1.0, 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
            if (burstActive) Opacity(opacity: burstOpacity, child: const Text('✨', style: TextStyle(fontSize: 46))),
            Text(_vehicle, style: const TextStyle(fontSize: 40)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _dpadBtn(Icons.keyboard_arrow_left, () => _moveLane(-1)),
      const SizedBox(width: 64),
      _dpadBtn(Icons.keyboard_arrow_right, () => _moveLane(1)),
    ]);
  }

  Widget _dpadBtn(IconData icon, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _statChip(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  Widget _buildRoundOver() {
    final mode = _mode!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _metTarget
                ? [const Color(0xFFFFD93D), const Color(0xFFFF6B6B)]
                : [Colors.white.withAlpha(30), Colors.white.withAlpha(14)]),
            borderRadius: BorderRadius.circular(20),
            border: _metTarget ? null : Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Column(children: [
            Text(_metTarget ? '🏁' : '💫', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(_metTarget ? 'Race complete!' : 'Good effort!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              mode == _Mode.wordRace
                  ? 'Spelled $_wordIdx / ${_targetWord.length} letters'
                  : 'Score: $_score / ${_totalPrompts[_diffIdx]}',
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204)),
            ),
            const SizedBox(height: 4),
            Text(
              _finishPlace == 1 ? 'You finished 1st! 🥇' : _finishPlace == 2 ? 'You finished 2nd! 🥈' : 'You finished 3rd! 🥉',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            if (_metTarget) ...[
              const SizedBox(height: 4),
              const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startRound(mode),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
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
            onPressed: () => setState(() => _state = _GameState.modeSelect),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('🎮 Change Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onBack,
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
