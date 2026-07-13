import 'dart:math';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'badge_service.dart';

// Press-to-scale animation wrapper. Pass onTap=null to disable animation.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleTo;
  const TapScale({super.key, required this.child, this.onTap, this.scaleTo = 0.88});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: widget.scaleTo).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap!();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// Colorful confetti burst overlay. Set trigger=true to fire the animation.
class ConfettiOverlay extends StatefulWidget {
  final bool trigger;
  const ConfettiOverlay({super.key, required this.trigger});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(70, (_) => _Particle(_rng));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    if (widget.trigger) _ctrl.forward();
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) {
      _particles = List.generate(70, (_) => _Particle(_rng));
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final Color color;
  final double size;
  final double rotSpeed;
  final double wobble;
  final double phase;

  static const _colors = [
    Color(0xFFFFD93D), Color(0xFFFF6B6B), Color(0xFF6BCB77),
    Color(0xFF4D96FF), Color(0xFFc471f5), Color(0xFFFF9F43),
    Color(0xFF00CEC9), Color(0xFFfd79a8),
  ];

  _Particle(Random rng)
      : x = rng.nextDouble(),
        startY = -0.05 - rng.nextDouble() * 0.25,
        speed = 0.55 + rng.nextDouble() * 0.75,
        color = _colors[rng.nextInt(_colors.length)],
        size = 6 + rng.nextDouble() * 8,
        rotSpeed = (rng.nextDouble() - 0.5) * 10,
        wobble = rng.nextDouble() * 0.04 + 0.01,
        phase = rng.nextDouble() * 6.28;
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final t = progress * p.speed;
      if (t > 1.3) continue;
      final y = (p.startY + t) * size.height;
      if (y > size.height) continue;
      final x = p.x * size.width + sin(progress * 5 + p.phase) * p.wobble * size.width;
      final opacity = (progress < 0.08
              ? progress / 0.08
              : progress > 0.75
                  ? (1.0 - progress) / 0.25
                  : 1.0)
          .clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotSpeed);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => progress != old.progress;
}

// ── Sparkle burst ────────────────────────────────────────────────────────────
// Quick celebratory sparkle burst for a single correct answer/catch/match —
// lighter and faster than ConfettiOverlay, which is reserved for whole-round
// completion. Fires on the rising edge of `trigger`, same idiom as
// ConfettiOverlay. Drop it centered in a Stack over the spot you want it.
class SparkleBurst extends StatefulWidget {
  final bool trigger;
  const SparkleBurst({super.key, required this.trigger});

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = Random();
  List<double> _angles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    if (widget.trigger) _fire();
  }

  @override
  void didUpdateWidget(SparkleBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) _fire();
  }

  void _fire() {
    _angles = List.generate(8, (i) => (i / 8) * 2 * pi + _rng.nextDouble() * 0.35);
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          if (_ctrl.value <= 0 || _angles.isEmpty) return const SizedBox.shrink();
          final t = _ctrl.value;
          final dist = 62 * t;
          final opacity = (1 - t).clamp(0.0, 1.0);
          final scale = 0.6 + 0.6 * (1 - t);
          return Stack(alignment: Alignment.center, children: [
            for (final a in _angles)
              Transform.translate(
                offset: Offset(cos(a), sin(a)) * dist,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: const Text('✨', style: TextStyle(fontSize: 20))),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

// ── Badge toast ────────────────────────────────────────────────────────────
// Shows a slide-up card when a badge is newly earned.
void showBadgeToast(BuildContext context, BadgeDef badge) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BadgeToast(badge: badge, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

/// Awards [id], shows toast + adds [stars] if newly earned.
Future<void> awardWithToast(
  BuildContext context,
  BadgeService bs,
  String id, {
  int stars = 25,
}) async {
  final isNew = await bs.award(id);
  if (!isNew) return;
  await AppState.addStars(stars);
  BadgeDef? badge;
  for (final b in allBadges) {
    if (b.id == id) { badge = b; break; }
  }
  if (badge != null && context.mounted) showBadgeToast(context, badge);
}

class _BadgeToast extends StatefulWidget {
  final BadgeDef badge;
  final VoidCallback onDone;
  const _BadgeToast({required this.badge, required this.onDone});

  @override
  State<_BadgeToast> createState() => _BadgeToastState();
}

class _BadgeToastState extends State<_BadgeToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(begin: const Offset(0, 2.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.45)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2700), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 88;
    return Positioned(
      bottom: bottom,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9F43), Color(0xFFFFD93D)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x55FFD93D), blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: Row(children: [
                Text(widget.badge.emoji,
                    style: const TextStyle(fontSize: 38)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏅 Badge Earned!',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7D3C00))),
                        Text(widget.badge.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1a0533))),
                        Text(widget.badge.desc,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xAA1a0533))),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Countdown bar ────────────────────────────────────────────────────────────
// Shrinking progress bar that flips green→red at 25% remaining.
// Pass a new `key` (e.g. ValueKey(roundIndex)) to restart it from full.
class CountdownBar extends StatefulWidget {
  final int seconds;
  final void Function(int secondsLeft)? onTick;
  final VoidCallback onFinish;
  const CountdownBar({super.key, required this.seconds, this.onTick, required this.onFinish});

  @override
  State<CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<CountdownBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))
      ..forward();
    _ctrl.addListener(() {
      widget.onTick?.call((widget.seconds - _ctrl.value * widget.seconds).ceil());
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final pct = 1.0 - _ctrl.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white.withAlpha(18),
            valueColor: AlwaysStoppedAnimation(
                pct > 0.25 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B)),
          ),
        );
      },
    );
  }
}

// ── Mascot corner companion ─────────────────────────────────────────────────
// Drop inside any game screen's Stack. Set celebrating=true on win.
class MascotCorner extends StatefulWidget {
  final bool celebrating;
  const MascotCorner({super.key, this.celebrating = false});

  @override
  State<MascotCorner> createState() => _MascotCornerState();
}

class _MascotCornerState extends State<MascotCorner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(MascotCorner old) {
    super.didUpdateWidget(old);
    // Speed up bounce on celebrate
    _ctrl.duration = widget.celebrating
        ? const Duration(milliseconds: 280)
        : const Duration(milliseconds: 900);
    if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      right: 14,
      bottom: 96 + bottomInset,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _float,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _float.value),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.celebrating)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(40), blurRadius: 6)
                    ],
                  ),
                  child: const Text('Woohoo! 🎉',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1a0533))),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.celebrating ? '🤩' : AppState.mascot,
                  key: ValueKey(widget.celebrating),
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
