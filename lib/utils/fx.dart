import 'dart:math';
import 'package:flutter/material.dart';

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
