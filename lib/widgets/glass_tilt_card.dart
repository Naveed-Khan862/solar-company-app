import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassTiltCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GlassTiltCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppPalette.surface.withValues(alpha: 0.88),
        border: Border.all(
          color: AppPalette.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.shadow.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glow;
  final Alignment glowAlign;
  final EdgeInsetsGeometry padding;

  const GlowCard({
    super.key,
    required this.child,
    this.glow = const Color(0xFF00C97D),
    this.glowAlign = Alignment.topLeft,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GlowPainter(glowAlign, glow),
              ),
            ),
            Positioned.fill(
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppPalette.surface.withValues(alpha: 0.92),
                  border: Border.all(
                    color: AppPalette.cardBorder,
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Alignment alignment;
  final Color color;

  _GlowPainter(this.alignment, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final dx = (alignment.x + 1) / 2;
    final dy = (alignment.y + 1) / 2;
    final center = Offset(size.width * dx, size.height * dy);
    final radius = size.width * 0.75;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.alignment != alignment || old.color != color;
}
