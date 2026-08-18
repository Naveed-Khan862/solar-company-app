import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppPalette.appBgTop,
                      AppPalette.appBgMid,
                      AppPalette.appBgBottom,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _OrbPainter(_controller.value)),
            ),
            Positioned.fill(
              child: SafeArea(child: widget.child),
            ),
          ],
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;

  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void orb(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final s = math.sin;
    final c = math.cos;

    orb(
      Offset(w * (0.2 + 0.08 * s(t * 2 * math.pi)),
          h * (0.15 + 0.05 * c(t * 2 * math.pi))),
      w * 0.45,
      AppPalette.orbGreen,
    );
    orb(
      Offset(w * (0.85 + 0.06 * c(t * 2 * math.pi)),
          h * (0.25 + 0.06 * s(t * 2 * math.pi))),
      w * 0.35,
      AppPalette.orbGold,
    );
    orb(
      Offset(w * (0.5 + 0.1 * s(t * 2 * math.pi)),
          h * (0.9 + 0.05 * c(t * 2 * math.pi))),
      w * 0.5,
      AppPalette.orbBlue,
    );

    final gridPaint = Paint()
      ..color = AppPalette.gridLine.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final step = 44.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.t != t;
}
