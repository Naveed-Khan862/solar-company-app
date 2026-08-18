import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_background.dart';
import 'glass_tilt_card.dart';

class SolarLoader extends StatefulWidget {
  final String message;
  final bool overlay;

  const SolarLoader({
    super.key,
    this.message = 'Loading...',
    this.overlay = false,
  });

  @override
  State<SolarLoader> createState() => _SolarLoaderState();
}

class _SolarLoaderState extends State<SolarLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(110, 110),
                    painter: _RaysPainter(t),
                  ),
                  Transform.scale(
                    scale: 1 + 0.06 * math.sin(t * 2 * math.pi),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C97D), Color(0xFF00A86B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00A86B)
                                .withValues(alpha: 0.5),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.solar_power,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF007A4D), Color(0xFF00B26B)],
              ).createShader(bounds),
              child: const Text(
                'Solar Company',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  style: TextStyle(
                    color: AppPalette.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  List.generate(3, (i) => t >= (i + 1) / 3 ? '.' : ' ').join(),
                  style: TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!widget.overlay) {
      return Scaffold(
        body: AppBackground(
          child: Center(child: content),
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        color: AppPalette.isDark
            ? const Color(0x990B1510)
            : const Color(0x99FFFFFF),
        child: Center(
          child: GlassTiltCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 34, vertical: 28),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final double t;

  _RaysPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2))
      ..strokeCap = StrokeCap.round;

    const count = 8;
    for (var i = 0; i < count; i++) {
      final base = t * 2 * math.pi + i * (2 * math.pi / count);
      final len = 30.0 + 6 * math.sin(t * 2 * math.pi + i * 1.7);
      final p1 = center +
          Offset(math.cos(base) * 32, math.sin(base) * 32);
      final p2 = center +
          Offset(math.cos(base) * (32 + len), math.sin(base) * (32 + len));
      paint.strokeWidth = 5.5;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) =>
      oldDelegate.t != t;
}
