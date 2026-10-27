import 'dart:math';
import 'package:flutter/material.dart';

class _Star {
  final double x, y, size;
  final Duration duration;
  final Color color;

  static const _palette = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFFD93D),
    Color(0xFFFF9F43),
    Color(0xFF4D96FF),
    Color(0xFFc471f5),
    Color(0xFF6BCB77),
  ];

  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 5 + rng.nextDouble() * 13,
        duration = Duration(milliseconds: 1400 + rng.nextInt(3600)),
        color = _palette[rng.nextInt(_palette.length)];
}

class StarFieldBackground extends StatefulWidget {
  final int count;
  const StarFieldBackground({super.key, this.count = 50});

  @override
  State<StarFieldBackground> createState() => _StarFieldBackgroundState();
}

class _StarFieldBackgroundState extends State<StarFieldBackground> {
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _stars = List.generate(widget.count, (_) => _Star(rng));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: _stars.map((s) {
        return Positioned(
          left: s.x * size.width,
          top: s.y * size.height,
          child: _StarWidget(star: s),
        );
      }).toList(),
    );
  }
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
        child: Text(
          widget.star.size > 14 ? '★' : '✦',
          style: TextStyle(
            fontSize: widget.star.size,
            color: widget.star.color,
          ),
        ),
      ),
    );
  }
}
