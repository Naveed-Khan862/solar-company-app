import 'dart:math' as math;

import 'package:flutter/material.dart';

class SolarGlobe extends StatefulWidget {
  final double size;

  const SolarGlobe({super.key, this.size = 140});

  @override
  State<SolarGlobe> createState() => _SolarGlobeState();
}

class _SolarGlobeState extends State<SolarGlobe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _GlobePainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  final double t;

  _GlobePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.34;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB300).withValues(alpha: 0.55),
          const Color(0xFFFF6D00).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 2.1));
    canvas.drawCircle(c, r * 2.1, glow);

    final body = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3E0),
          const Color(0xFFFFB300),
          const Color(0xFFFF6D00),
          const Color(0xFFE65100),
        ],
        stops: const [0.0, 0.45, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, body);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(c, r, rim);

    final flare = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: c.translate(-r * 0.35, -r * 0.4), radius: r * 0.7));
    canvas.drawCircle(c.translate(-r * 0.35, -r * 0.4), r * 0.7, flare);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.014;
    final rect = Rect.fromCircle(center: c, radius: r * 1.55);
    ringPaint.shader = SweepGradient(
      colors: [
        Colors.transparent,
        Colors.amberAccent.withValues(alpha: 0.9),
        Colors.orangeAccent.withValues(alpha: 0.5),
        Colors.transparent,
      ],
      transform: GradientRotation(t * 2 * math.pi),
    ).createShader(rect);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.42);
    canvas.drawArc(
      rect.shift(Offset(-c.dx, -c.dy)),
      0,
      2 * math.pi,
      false,
      ringPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) => old.t != t;
}
