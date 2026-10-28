import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zoodles/core/core.dart';
import '../models/letter_data.dart';
import '../models/letter_stroke_data.dart';

class LetterTraceScreen extends StatefulWidget {
  final int idx;
  final bool initialLowercase;
  final VoidCallback onBack;

  const LetterTraceScreen({
    super.key,
    required this.idx,
    this.initialLowercase = false,
    required this.onBack,
  });

  @override
  State<LetterTraceScreen> createState() => _LetterTraceScreenState();
}

class _LetterTraceScreenState extends State<LetterTraceScreen>
    with TickerProviderStateMixin {
  final SoundService _sfx = SoundService();
  final TtsService _tts = TtsService();

  late bool _isLowercase;
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  Color _penColor = const Color(0xFFFFD93D);
  bool _showPraise = false;
  bool _isError = false;
  String _hintText = '';
  Timer? _completionTimer;

  late final AnimationController _guide;
  late final AnimationController _shakeCtrl;

  static const _colors = [
    Color(0xFFFFD93D),
    Color(0xFFFF6B6B),
    Color(0xFF51CF66),
    Color(0xFF4D96FF),
    Color(0xFFc471f5),
  ];

  @override
  void initState() {
    super.initState();
    _isLowercase = widget.initialLowercase;
    _guide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _updateHint();
  }

  void _updateHint() {
    final step = _strokes.length + 1;
    setState(() {
      _hintText = 'Start at glowing dot $step and follow the path!';
      _isError = false;
    });
  }

  void _switchCase(bool lowercase) {
    if (_isLowercase == lowercase) return;
    _sfx.play(SoundType.tap);
    setState(() {
      _isLowercase = lowercase;
      _strokes.clear();
      _current.clear();
      _showPraise = false;
      _completionTimer?.cancel();
    });
    _updateHint();
  }

  void _clearCanvas() {
    _sfx.play(SoundType.tap);
    setState(() {
      _strokes.clear();
      _current.clear();
      _showPraise = false;
      _completionTimer?.cancel();
    });
    _updateHint();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _guide.dispose();
    _shakeCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = letters[widget.idx];
    final activeLetter =
        _isLowercase ? d.letter.toLowerCase() : d.letter.toUpperCase();

    return Container(
      color: const Color(0xFF0a0820),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(38)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Trace "$activeLetter"',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Clear button
                  GestureDetector(
                    onTap: _clearCanvas,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(36)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Case switcher (Capital / Small)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(16),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchCase(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            gradient: !_isLowercase
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD93D),
                                      Color(0xFFFF6B6B),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Center(
                            child: Text(
                              '🔤 Capital (${d.letter})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isLowercase
                                    ? Colors.white
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchCase(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            gradient: _isLowercase
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6BCB77),
                                      Color(0xFF4D96FF),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Center(
                            child: Text(
                              '🔡 Small (${d.letter.toLowerCase()})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isLowercase
                                    ? Colors.white
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        final guide = letterGuide(activeLetter, canvasSize);
                        final totalSteps = guide.length;
                        final currentStep = _strokes.length;

                        return GestureDetector(
                          onPanStart: (e) {
                            if (_showPraise || currentStep >= totalSteps) return;
                            setState(() {
                              _current = [e.localPosition];
                              _isError = false;
                            });
                          },
                          onPanUpdate: (e) {
                            if (_showPraise || currentStep >= totalSteps) return;
                            setState(() => _current.add(e.localPosition));
                          },
                          onPanEnd: (_) {
                            if (_showPraise ||
                                currentStep >= totalSteps ||
                                _current.isEmpty) {
                              return;
                            }

                            final activeMetric =
                                guide[currentStep].computeMetrics().firstOrNull;
                            if (activeMetric == null) {
                              setState(() => _current = []);
                              return;
                            }

                            final isValid = StrokeValidator.validateStroke(
                              userPoints: _current,
                              guideMetric: activeMetric,
                              tolerance: canvasSize.width * 0.16,
                            );

                            if (isValid) {
                              _sfx.play(SoundType.pop);
                              setState(() {
                                _strokes.add(List.of(_current));
                                _current = [];
                                _isError = false;
                                if (_strokes.length >= totalSteps) {
                                  _showPraise = true;
                                  _hintText =
                                      '✨ Amazing! Letter completed! ✨';
                                  _sfx.play(SoundType.win);
                                  _tts.speak(
                                    '${_isLowercase ? 'Small' : 'Capital'} ${d.letter}! ${d.primaryWord}',
                                  );
                                  _completionTimer?.cancel();
                                  _completionTimer = Timer(
                                    const Duration(milliseconds: 2200),
                                    () {
                                      if (mounted) widget.onBack();
                                    },
                                  );
                                } else {
                                  _hintText =
                                      'Great job! Now trace line ${_strokes.length + 1} 👉';
                                }
                              });
                            } else {
                              _sfx.play(SoundType.wrong);
                              _shakeCtrl.forward(from: 0.0);
                              setState(() {
                                _current = [];
                                _isError = true;
                                _hintText =
                                    '⚠️ Follow line ${currentStep + 1} from the glowing dot to the end!';
                              });
                            }
                          },
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_guide, _shakeCtrl]),
                            builder: (_, _) {
                              final shakeOffset = _isError
                                  ? sin(_shakeCtrl.value * pi * 4) * 6
                                  : 0.0;
                              return Transform.translate(
                                offset: Offset(shakeOffset, 0),
                                child: CustomPaint(
                                  painter: LetterTracePainter(
                                    letter: activeLetter,
                                    strokes: _strokes,
                                    current: _current,
                                    penColor: _penColor,
                                    guideProgress: _guide.value,
                                    isError: _isError,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(13),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: _isError
                                            ? const Color(0xFFFF6B6B).withAlpha(180)
                                            : Colors.white.withAlpha(31),
                                        width: _isError ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Step instruction / hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _showPraise
                      ? const Color(0xFFFFD93D)
                      : _isError
                          ? const Color(0xFFFF6B6B)
                          : Colors.white.withAlpha(200),
                ),
                child: Text(_hintText, textAlign: TextAlign.center),
              ),
            ),
            // Color picker
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._colors.map(
                    (c) => GestureDetector(
                      onTap: () => setState(() => _penColor = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _penColor == c
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LetterTracePainter extends CustomPainter {
  final String letter;
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color penColor;
  final double guideProgress; // 0.0–1.0
  final bool isError;

  LetterTracePainter({
    required this.letter,
    required this.strokes,
    required this.current,
    required this.penColor,
    required this.guideProgress,
    this.isError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isLower =
        letter == letter.toLowerCase() && letter != letter.toUpperCase();

    // 1. Ghost letter in background
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.width * (isLower ? 0.70 : 0.65),
          color: Colors.white.withAlpha(20),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );

    // 2. Guide metrics & active index
    final guide = letterGuide(letter, size);
    final metrics = [for (final p in guide) ...p.computeMetrics().take(1)];
    final activeIndex = strokes.length;

    if (metrics.isNotEmpty && activeIndex < metrics.length) {
      _paintGuideLines(canvas, metrics, activeIndex);
    }

    // 3. User completed strokes
    final paint = Paint()
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      paint.color = penColor;
      _drawStroke(canvas, s, paint);
    }

    // 4. Current in-progress stroke
    if (current.isNotEmpty) {
      paint.color = isError ? const Color(0xFFFF6B6B) : penColor;
      _drawStroke(canvas, current, paint);
    }

    // 5. Active and future step badges
    if (metrics.isNotEmpty && activeIndex < metrics.length) {
      for (int i = 0; i < metrics.length; i++) {
        if (i < activeIndex) continue;
        final isActive = (i == activeIndex);
        _paintBadge(canvas, metrics[i], i, isActive);
      }
    }
  }

  void _paintGuideLines(
    Canvas canvas,
    List<PathMetric> metrics,
    int activeIndex,
  ) {
    final totalStrokes = metrics.length;
    final activeMetric = metrics[activeIndex];

    // Faint dotted path for upcoming non-active strokes
    final backgroundDotPaint = Paint()
      ..color = Colors.white.withAlpha(28)
      ..style = PaintingStyle.fill;
    for (int i = activeIndex + 1; i < totalStrokes; i++) {
      final m = metrics[i];
      double pos = 0;
      while (pos <= m.length) {
        final t = m.getTangentForOffset(pos);
        if (t != null) canvas.drawCircle(t.position, 2.5, backgroundDotPaint);
        pos += 10;
      }
    }

    // Bright dotted path for current active stroke
    final activeDotPaint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..style = PaintingStyle.fill;
    double pos = 0;
    while (pos <= activeMetric.length) {
      final t = activeMetric.getTangentForOffset(pos);
      if (t != null) canvas.drawCircle(t.position, 3.5, activeDotPaint);
      pos += 9;
    }

    // Animated glowing dot moving along the current active stroke
    final target = guideProgress * activeMetric.length;
    final t = activeMetric.getTangentForOffset(target);
    if (t != null) {
      canvas.drawCircle(
        t.position,
        18,
        Paint()
          ..color = const Color(0xFFFFD93D).withAlpha(45)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        t.position,
        11,
        Paint()
          ..color = const Color(0xFFFFD93D).withAlpha(110)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        t.position,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintBadge(
    Canvas canvas,
    PathMetric metric,
    int index,
    bool isActive,
  ) {
    final badgeTangent = metric.getTangentForOffset(0);
    if (badgeTangent == null) return;

    final center = badgeTangent.position;
    final radius = isActive ? 13.0 : 9.0;
    final bgColor = isActive
        ? (isError ? const Color(0xFFFF6B6B) : const Color(0xFFFFD93D))
        : Colors.white.withAlpha(40);
    final textColor = isActive ? const Color(0xFF1a0533) : Colors.white70;

    if (isActive) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = bgColor.withAlpha(60)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1a0533).withAlpha(isActive ? 200 : 80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final numTp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: textColor,
          fontSize: isActive ? 12 : 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numTp.paint(
      canvas,
      Offset(center.dx - numTp.width / 2, center.dy - numTp.height / 2),
    );
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      canvas.drawCircle(
        pts.first,
        paint.strokeWidth / 2,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LetterTracePainter old) => true;
}
