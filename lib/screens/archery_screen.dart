import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/sound_service.dart';
import '../utils/tts_service.dart';
import '../utils/app_state.dart';

class _ArrowPathResult {
  final List<Offset> points;
  final int? hitTargetIdx;
  final double totalLength;
  final List<double> segmentLengths;

  _ArrowPathResult({
    required this.points,
    required this.hitTargetIdx,
    required this.totalLength,
    required this.segmentLengths,
  });
}

enum _GameState { idle, question, finished }

class ArcheryScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ArcheryScreen({super.key, required this.onBack});

  @override
  State<ArcheryScreen> createState() => _ArcheryScreenState();
}

class _ArcheryScreenState extends State<ArcheryScreen> {
  final BadgeService _bs = BadgeService();
  final SoundService _sfx = SoundService();
  final TtsService _tts = TtsService();
  final _rng = Random();

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _targetCounts = [4, 4, 6];
  static const _totalQ = 10;
  static const _typeIcons = ['🔤', '🔢', '➗'];
  static const _allLetters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];
  static const _digits = ['0','1','2','3','4','5','6','7','8','9'];

  static const _maxPull = 130.0;
  static const _hitRadius = 44.0;
  static const _minPullToFire = 10.0;

  int _diffIdx = 0;
  _GameState _state = _GameState.idle;
  int _qIndex = 0;
  int _score = 0;
  int _bestScore = -1;
  int _bestTotal = _totalQ;

  int _qType = 0; // 0=letter, 1=number, 2=math
  late String _prompt;
  late List<String> _targets;
  late List<Offset> _targetPositions; // fractional 0..1
  late int _correctIdx;
  bool _answered = false;
  int? _selectedIdx;
  String? _shotFeedback;
  bool _sparkle = false;

  double _areaW = 300, _areaH = 300;
  bool _dragging = false;
  Offset _pullVector = Offset.zero;

  bool _arrowFlying = false;
  List<Offset> _arrowPath = [];
  List<double> _segmentLengths = [];
  double _totalPathLength = 0.0;
  int _arrowDurationMs = 300;
  int? _pendingHitIdx;

  Offset get _bowPos => Offset(_areaW / 2, _areaH - 36);

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bestScore = prefs.getInt('archery_best') ?? -1;
      _bestTotal = prefs.getInt('archery_best_total') ?? _totalQ;
    });
  }

  Future<void> _saveBest() async {
    if (_score <= _bestScore) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('archery_best', _score);
    await prefs.setInt('archery_best_total', _totalQ);
    _bestScore = _score;
    _bestTotal = _totalQ;
  }

  void _startQuiz() {
    _qIndex = 0;
    _score = 0;
    setState(() => _state = _GameState.question);
    _loadQuestion();
  }

  (String, int) _genMathQ() {
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

  List<Offset> _placeTargetPositions(int count) {
    final positions = <Offset>[];
    int attempts = 0;
    while (positions.length < count && attempts < 500) {
      final p = Offset(0.12 + _rng.nextDouble() * 0.76, 0.08 + _rng.nextDouble() * 0.42);
      if (positions.every((q) => (q - p).distance > 0.20)) positions.add(p);
      attempts++;
    }
    while (positions.length < count) {
      positions.add(Offset(0.12 + _rng.nextDouble() * 0.76, 0.08 + _rng.nextDouble() * 0.42));
    }
    return positions;
  }

  void _loadQuestion() {
    final count = _targetCounts[_diffIdx];
    final type = _rng.nextInt(3);
    String prompt;
    List<String> targets;
    int correctIdx;

    if (type == 0) {
      final letter = _allLetters[_rng.nextInt(_allLetters.length)];
      final distractors = (List.of(_allLetters)..remove(letter)..shuffle(_rng)).take(count - 1).toList();
      targets = [letter, ...distractors]..shuffle(_rng);
      correctIdx = targets.indexOf(letter);
      prompt = 'Find the letter';
      _tts.speak('Find the letter $letter');
    } else if (type == 1) {
      final digit = _digits[_rng.nextInt(_digits.length)];
      final distractors = (List.of(_digits)..remove(digit)..shuffle(_rng)).take(count - 1).toList();
      targets = [digit, ...distractors]..shuffle(_rng);
      correctIdx = targets.indexOf(digit);
      prompt = 'Find the number';
      _tts.speak('Find the number $digit');
    } else {
      final (display, answer) = _genMathQ();
      final choices = _genNumChoices(answer, count);
      targets = choices.map((c) => '$c').toList();
      correctIdx = targets.indexOf('$answer');
      prompt = display;
      _tts.speak(display
          .replaceAll('+', 'plus').replaceAll('−', 'minus')
          .replaceAll('=', 'equals').replaceAll('?', 'what'));
    }

    setState(() {
      _qType = type;
      _prompt = prompt;
      _targets = targets;
      _targetPositions = _placeTargetPositions(targets.length);
      _correctIdx = correctIdx;
      _answered = false;
      _selectedIdx = null;
      _shotFeedback = null;
      _arrowFlying = false;
      _pullVector = Offset.zero;
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (_answered || _arrowFlying) return;
    setState(() {
      _dragging = true;
      _pullVector = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    setState(() {
      var v = d.localPosition - _bowPos;
      if (v.distance > _maxPull) v = Offset.fromDirection(v.direction, _maxPull);
      _pullVector = v;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    if (_pullVector.distance < _minPullToFire) {
      setState(() => _pullVector = Offset.zero);
      return;
    }
    _fire();
  }

  _ArrowPathResult _calculatePath(Offset startPos, Offset initialDir) {
    final points = <Offset>[startPos];
    final segmentLengths = <double>[];
    double totalLength = 0.0;

    Offset currPos = startPos;
    Offset dir = initialDir;
    int? hitIdx;

    for (int bounce = 0; bounce <= 4; bounce++) {
      // 1. Target circle hits along current segment
      double closestTargetT = double.infinity;
      int? candidateTargetIdx;

      for (int i = 0; i < _targetPositions.length; i++) {
        final targetPx = Offset(_targetPositions[i].dx * _areaW, _targetPositions[i].dy * _areaH);
        final toTarget = targetPx - currPos;
        final proj = toTarget.dx * dir.dx + toTarget.dy * dir.dy;
        if (proj <= 0) continue;

        final closestOnRay = currPos + dir * proj;
        final perp = (targetPx - closestOnRay).distance;
        if (perp <= _hitRadius) {
          final radical = max(0.0, _hitRadius * _hitRadius - perp * perp);
          final hitDist = proj - sqrt(radical);
          final t = hitDist > 0.1 ? hitDist : proj;
          if (t < closestTargetT && t > 0.1) {
            closestTargetT = t;
            candidateTargetIdx = i;
          }
        }
      }

      // 2. Wall boundary hits (left x=0, right x=_areaW, top y=0, bottom y=_areaH)
      double closestWallT = double.infinity;
      int wallHitType = 0; // 1=left, 2=right, 3=top, 4=bottom

      if (dir.dx < -1e-5) {
        final t = (0.0 - currPos.dx) / dir.dx;
        final hitY = currPos.dy + t * dir.dy;
        if (t > 0.1 && hitY >= 0 && hitY <= _areaH) {
          if (t < closestWallT) {
            closestWallT = t;
            wallHitType = 1;
          }
        }
      }

      if (dir.dx > 1e-5) {
        final t = (_areaW - currPos.dx) / dir.dx;
        final hitY = currPos.dy + t * dir.dy;
        if (t > 0.1 && hitY >= 0 && hitY <= _areaH) {
          if (t < closestWallT) {
            closestWallT = t;
            wallHitType = 2;
          }
        }
      }

      if (dir.dy < -1e-5) {
        final t = (0.0 - currPos.dy) / dir.dy;
        final hitX = currPos.dx + t * dir.dx;
        if (t > 0.1 && hitX >= 0 && hitX <= _areaW) {
          if (t < closestWallT) {
            closestWallT = t;
            wallHitType = 3;
          }
        }
      }

      if (dir.dy > 1e-5) {
        final t = (_areaH - currPos.dy) / dir.dy;
        final hitX = currPos.dx + t * dir.dx;
        if (t > 0.1 && hitX >= 0 && hitX <= _areaW) {
          if (t < closestWallT) {
            closestWallT = t;
            wallHitType = 4;
          }
        }
      }

      // 3. Resolve nearest collision
      if (candidateTargetIdx != null && closestTargetT <= closestWallT) {
        final hitPos = currPos + dir * closestTargetT;
        points.add(hitPos);
        final segLen = (hitPos - currPos).distance;
        segmentLengths.add(segLen);
        totalLength += segLen;
        hitIdx = candidateTargetIdx;
        break;
      } else if (closestWallT < double.infinity && wallHitType != 0) {
        final wallHitPos = currPos + dir * closestWallT;
        points.add(wallHitPos);
        final segLen = (wallHitPos - currPos).distance;
        segmentLengths.add(segLen);
        totalLength += segLen;
        currPos = wallHitPos;

        if (wallHitType == 1 || wallHitType == 2) {
          dir = Offset(-dir.dx, dir.dy);
        } else {
          dir = Offset(dir.dx, -dir.dy);
        }
      } else {
        final maxTravel = sqrt(_areaW * _areaW + _areaH * _areaH);
        final endPos = currPos + dir * maxTravel;
        points.add(endPos);
        final segLen = (endPos - currPos).distance;
        segmentLengths.add(segLen);
        totalLength += segLen;
        break;
      }
    }

    return _ArrowPathResult(
      points: points,
      hitTargetIdx: hitIdx,
      totalLength: totalLength,
      segmentLengths: segmentLengths,
    );
  }

  void _fire() {
    final fireDir = Offset.fromDirection(_pullVector.direction);
    final res = _calculatePath(_bowPos, fireDir);

    setState(() {
      _answered = true;
      _pullVector = Offset.zero;
      _arrowPath = res.points;
      _segmentLengths = res.segmentLengths;
      _totalPathLength = res.totalLength;
      _arrowDurationMs = (res.totalLength / 1400 * 1000).clamp(200, 750).round();
      _arrowFlying = true;
      _pendingHitIdx = res.hitTargetIdx;
    });
  }

  void _onArrowLanded() {
    final correct = _pendingHitIdx != null && _pendingHitIdx == _correctIdx;
    final cleanMiss = _pendingHitIdx == null;
    setState(() {
      _arrowFlying = false;
      _selectedIdx = _pendingHitIdx;
      if (correct) {
        _score++;
        _sparkle = true;
      }
      _shotFeedback = correct ? '🎯 Bullseye!' : (cleanMiss ? '💨 Miss!' : '❌ Wrong Target');
    });
    _sfx.play(correct ? SoundType.correct : SoundType.wrong);
    if (correct) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _sparkle = false);
      });
    }
    Future.delayed(const Duration(milliseconds: 700), _advance);
  }

  void _onTimeoutMiss() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIdx = null;
      _shotFeedback = '⏰ Too slow!';
    });
    _sfx.play(SoundType.wrong);
    Future.delayed(const Duration(milliseconds: 700), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_qIndex + 1 >= _totalQ) {
      _finish();
    } else {
      setState(() => _qIndex++);
      _loadQuestion();
    }
  }

  Future<void> _finish() async {
    await _saveBest();
    final perfect = _score == _totalQ;
    _sfx.play(perfect ? SoundType.win : SoundType.correct);
    await AppState.addStars(10);
    if (!mounted) return;
    setState(() => _state = _GameState.finished);
    await awardWithToast(context, _bs, 'archery_first');
    if (perfect && mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) await awardWithToast(context, _bs, 'archery_perfect', stars: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0f3d3e), Color(0xFF134E5E), Color(0xFF1a5c3a)],
          ),
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
              child: Opacity(opacity: 0.09, child: const Text('🏹', style: TextStyle(fontSize: 140)))),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: _state == _GameState.finished
                    ? _buildFinishedBanner()
                    : _state == _GameState.idle
                        ? _buildStartPrompt()
                        : _buildQuestion(),
              ),
            ]),
          ),
        ]),
      ),
      MascotCorner(celebrating: _state == _GameState.finished && _score == _totalQ),
      ConfettiOverlay(trigger: _state == _GameState.finished && _score == _totalQ),
      SparkleBurst(trigger: _sparkle),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () { _tts.stop(); widget.onBack(); },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🏹', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('Archery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        GestureDetector(
          onTap: () {
            if (_state != _GameState.question) {
              setState(() => _diffIdx = (_diffIdx + 1) % 3);
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

  Widget _buildStartPrompt() {
    return Center(
      child: TapScale(
        onTap: _startQuiz,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF134E5E), Color(0xFF71B280)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x44134E5E), blurRadius: 18)],
          ),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🏹', style: TextStyle(fontSize: 44)),
            SizedBox(height: 8),
            Text('Tap to Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(height: 4),
            Text('Drag toward a target, then let go to shoot!',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statChip('❓', 'Question', '${_qIndex + 1} / $_totalQ'),
          _statChip('⭐', 'Score', '$_score'),
        ]),
      ),
      const SizedBox(height: 8),
      Text('${_typeIcons[_qType]}  $_prompt',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 6),
      SizedBox(
        height: 22,
        child: AnimatedOpacity(
          opacity: _shotFeedback != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Text(_shotFeedback ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFFFD93D))),
        ),
      ),
      if (_diffIdx == 2) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: CountdownBar(
            key: ValueKey('archery_timer_$_qIndex'),
            seconds: 6,
            onFinish: _onTimeoutMiss,
          ),
        ),
      ],
      const SizedBox(height: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildRange(),
        ),
      ),
    ]);
  }

  (Offset, double) _getPosAndAngleAtPathProgress(double progress) {
    if (_arrowPath.isEmpty) return (Offset.zero, 0.0);
    if (_arrowPath.length == 1 || _totalPathLength <= 0) return (_arrowPath.first, 0.0);

    final targetDist = progress * _totalPathLength;
    double accumulated = 0.0;

    for (int i = 0; i < _segmentLengths.length; i++) {
      final segLen = _segmentLengths[i];
      if (accumulated + segLen >= targetDist || i == _segmentLengths.length - 1) {
        final segProgress = segLen > 0 ? (targetDist - accumulated) / segLen : 1.0;
        final clampedSegProg = segProgress.clamp(0.0, 1.0);
        final p1 = _arrowPath[i];
        final p2 = _arrowPath[i + 1];
        final currentPos = Offset.lerp(p1, p2, clampedSegProg)!;
        final angle = (p2 - p1).direction + pi / 2;
        return (currentPos, angle);
      }
      accumulated += segLen;
    }
    final pLast = _arrowPath.last;
    final pPrev = _arrowPath[_arrowPath.length - 2];
    return (pLast, (pLast - pPrev).direction + pi / 2);
  }

  Widget _buildRange() {
    return LayoutBuilder(builder: (context, c) {
      _areaW = c.maxWidth;
      _areaH = c.maxHeight;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: _areaW, height: _areaH,
          color: Colors.white.withAlpha(8),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Stack(children: [
              for (int i = 0; i < _targets.length; i++) _buildTargetAt(i),
              if (_dragging)
                CustomPaint(
                  size: Size(_areaW, _areaH),
                  painter: _AimPainter(
                    _calculatePath(_bowPos, Offset.fromDirection(_pullVector.direction)).points,
                  ),
                ),
              _buildBow(),
              if (_arrowFlying && _arrowPath.isNotEmpty)
                TweenAnimationBuilder<double>(
                  key: ValueKey('arrow_$_qIndex'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: _arrowDurationMs),
                  curve: Curves.easeOut,
                  onEnd: _onArrowLanded,
                  builder: (context, progress, child) {
                    final (pos, angle) = _getPosAndAngleAtPathProgress(progress);
                    return Positioned(
                      left: pos.dx - 12,
                      top: pos.dy - 12,
                      child: Transform.rotate(
                        angle: angle,
                        child: const Text('➶', style: TextStyle(fontSize: 26)),
                      ),
                    );
                  },
                ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildBow() {
    return Positioned(
      left: _bowPos.dx - 22, top: _bowPos.dy - 22,
      child: Transform.rotate(
        angle: _dragging ? _pullVector.direction + pi / 2 : 0,
        child: const Text('🏹', style: TextStyle(fontSize: 44)),
      ),
    );
  }

  Widget _buildTargetAt(int i) {
    final pos = _targetPositions[i];
    final isCorrectTarget = i == _correctIdx;
    Color ring = Colors.white.withAlpha(60);
    if (_answered && !_arrowFlying) {
      if (isCorrectTarget) {
        ring = const Color(0xFF51CF66);
      } else if (_selectedIdx == i) {
        ring = const Color(0xFFFF6B6B);
      }
    }
    const size = 78.0;
    return Positioned(
      left: pos.dx * _areaW - size / 2,
      top: pos.dy * _areaH - size / 2,
      child: Stack(alignment: Alignment.center, children: [
        Container(width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: ring, width: 4))),
        Container(width: 54, height: 54,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF6B6B))),
        Container(width: 28, height: 28,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
        Text(_targets[i],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1a0533))),
      ]),
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

  Widget _buildFinishedBanner() {
    final perfect = _score == _totalQ;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x44FFD93D), blurRadius: 20)],
          ),
          child: Column(children: [
            Text(perfect ? '🏆' : '🎉', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text('Score: $_score / $_totalQ',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Best: $_bestScore / $_bestTotal',
                style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
            const SizedBox(height: 4),
            const Text('⭐⭐⭐', style: TextStyle(fontSize: 24, letterSpacing: 4)),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF134E5E),
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
            onPressed: () { _tts.stop(); widget.onBack(); },
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

class _AimPainter extends CustomPainter {
  final List<Offset> pathPoints;
  const _AimPainter(this.pathPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.length < 2) return;
    final dotPaint = Paint()..color = Colors.white.withAlpha(160);
    final bounceRingPaint = Paint()
      ..color = const Color(0xFFFFD93D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < pathPoints.length - 1; i++) {
      final p1 = pathPoints[i];
      final p2 = pathPoints[i + 1];
      final segVector = p2 - p1;
      final segLen = segVector.distance;
      if (segLen <= 0) continue;
      final dir = segVector / segLen;

      final startOffset = (i == 0) ? 26.0 : 6.0;
      for (double t = startOffset; t < segLen - 6.0; t += 18.0) {
        canvas.drawCircle(p1 + dir * t, 2.8, dotPaint);
      }

      if (i > 0) {
        canvas.drawCircle(p1, 5.0, bounceRingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AimPainter old) => old.pathPoints != pathPoints;
}
