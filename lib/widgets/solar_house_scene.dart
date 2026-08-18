import 'dart:math' as math;

import 'package:flutter/material.dart';

class SolarHouseScene extends StatefulWidget {
  final Widget? child;

  const SolarHouseScene({super.key, this.child});

  @override
  State<SolarHouseScene> createState() => _SolarHouseSceneState();
}

class _SolarHouseSceneState extends State<SolarHouseScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ScenePainter(_controller.value)),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  final double t;

  _ScenePainter(this.t);

  static const _skyTop = Color(0xFFD3EAF9);
  static const _skyBottom = Color(0xFFFBF6E7);
  static const _groundTop = Color(0xFFAEDDBE);
  static const _groundBottom = Color(0xFF7CC293);
  static const _sunCore = Color(0xFFFFD54F);
  static const _panelDark = Color(0xFF1B3A5C);
  static const _panelLine = Color(0xFF4A7BA5);
  static const _houseBody = Color(0xFFFFFFFF);
  static const _houseBorder = Color(0xFFD9E7EF);
  static const _door = Color(0xFF7CCF9D);
  static const _windowGlow = Color(0xFFFFE9A8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    _paintSun(canvas, w, h);
    _paintClouds(canvas, w, h);
    _paintGround(canvas, w, h);
    _paintHouse(canvas, w, h);
  }

  void _paintSun(Canvas canvas, double w, double h) {
    final c = Offset(w * 0.8, h * 0.13);
    final r = w * 0.075;
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _sunCore.withValues(alpha: 0.5 + pulse * 0.25),
          _sunCore.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 2.6));
    canvas.drawCircle(c, r * 2.6, glow);

    final rayPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.55 + pulse * 0.2)
      ..strokeWidth = w * 0.004
      ..strokeCap = StrokeCap.round;
    final rayAngle = t * 2 * math.pi;
    for (var i = 0; i < 12; i++) {
      final a = rayAngle + i * (2 * math.pi / 12);
      final r1 = r * 1.35;
      final r2 = r * 1.85 + pulse * r * 0.1;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r1,
        c + Offset(math.cos(a), math.sin(a)) * r2,
        rayPaint,
      );
    }

    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3C4),
          _sunCore,
          const Color(0xFFFFB300),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, core);
  }

  void _paintClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      final speed = 0.35 + i * 0.12;
      final span = 1.45;
      var x = ((t * speed + i * 0.42) % span) * (w + w * 0.8) - w * 0.4;
      if (i == 1) x = -x + w * 1.2;
      final y = h * (0.2 + i * 0.09);
      final s = w * (0.07 + i * 0.008);
      _cloud(canvas, x, y, s, cloudPaint);
    }
  }

  void _cloud(Canvas canvas, double x, double y, double s, Paint p) {
    canvas.drawCircle(Offset(x, y), s * 0.9, p);
    canvas.drawCircle(Offset(x - s, y + s * 0.3), s * 0.65, p);
    canvas.drawCircle(Offset(x + s, y + s * 0.3), s * 0.65, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - s * 1.1, y, s * 2.2, s * 0.55),
        const Radius.circular(30),
      ),
      p,
    );
  }

  void _paintGround(Canvas canvas, double w, double h) {
    final groundTop = h * 0.78;
    final ground = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_groundTop, _groundBottom],
      ).createShader(Rect.fromLTWH(0, groundTop, w, h - groundTop));
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, groundTop + w * 0.06)
      ..quadraticBezierTo(w * 0.3, groundTop - w * 0.05, w * 0.55, groundTop + w * 0.02)
      ..quadraticBezierTo(w * 0.8, groundTop + w * 0.06, w, groundTop - w * 0.01)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, ground);
  }

  void _paintHouse(Canvas canvas, double w, double h) {
    final groundY = h * 0.84;
    final houseW = w * 0.44;
    final houseH = h * 0.16;
    final left = (w - houseW) / 2;
    final top = groundY - houseH;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, houseW, houseH),
      const Radius.circular(10),
    );
    final body = Paint()..color = _houseBody;
    canvas.drawRRect(bodyRect, body);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.003
      ..color = _houseBorder;
    canvas.drawRRect(bodyRect, border);

    _paintDoor(canvas, left, top, houseW, houseH);
    _paintWindow(canvas, left, top, houseW, houseH);
    _paintPanels(canvas, left, top, houseW);
  }

  void _paintDoor(Canvas canvas, double left, double top, double houseW, double houseH) {
    final doorW = houseW * 0.16;
    final doorH = houseH * 0.62;
    final dx = left + houseW * 0.16;
    final dy = top + houseH - doorH;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, doorW, doorH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = _door);
    canvas.drawCircle(
      Offset(dx + doorW - doorW * 0.28, dy + doorH * 0.5),
      houseW * 0.008,
      Paint()..color = const Color(0xFF2E7D32),
    );
  }

  void _paintWindow(Canvas canvas, double left, double top, double houseW, double houseH) {
    final winW = houseW * 0.2;
    final winH = houseH * 0.44;
    final wx = left + houseW * 0.62;
    final wy = top + houseH * 0.18;
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wx, wy, winW, winH),
      const Radius.circular(8),
    );
    final glass = Paint()
      ..shader = LinearGradient(
        colors: [
          _windowGlow.withValues(alpha: 0.75 + pulse * 0.25),
          const Color(0xFFFFD87A).withValues(alpha: 0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, glass);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = houseW * 0.008
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(rect, frame);
    canvas.drawLine(
      Offset(wx + winW / 2, wy),
      Offset(wx + winW / 2, wy + winH),
      frame,
    );
  }

  void _paintPanels(Canvas canvas, double left, double top, double houseW) {
    final pW = houseW * 0.82;
    final pH = houseW * 0.16;
    final px = left + (houseW - pW) / 2;
    final py = top - pH * 0.85;

    canvas.save();
    canvas.translate(px + pW / 2, py + pH / 2);
    canvas.rotate(-0.09);
    final panelRect = Rect.fromCenter(center: Offset.zero, width: pW, height: pH);

    final base = Paint()
      ..shader = LinearGradient(
        colors: [_panelDark, const Color(0xFF2A4E77)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(panelRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      base,
    );

    final line = Paint()
      ..color = _panelLine.withValues(alpha: 0.85)
      ..strokeWidth = pW * 0.006;
    final cols = 3;
    final rows = 2;
    for (var i = 1; i < cols; i++) {
      canvas.drawLine(
        Offset(-pW / 2 + i * pW / cols, -pH / 2),
        Offset(-pW / 2 + i * pW / cols, pH / 2),
        line,
      );
    }
    for (var i = 1; i < rows; i++) {
      canvas.drawLine(
        Offset(-pW / 2, -pH / 2 + i * pH / rows),
        Offset(pW / 2, -pH / 2 + i * pH / rows),
        line,
      );
    }

    final shineT = (t * 1.5) % 1.2 - 0.1;
    final sx = -pW / 2 + shineT * pW * 1.15;
    final shine = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(sx - pW * 0.12, -pH / 2, pW * 0.24, pH));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(panelRect, const Radius.circular(8)));
    canvas.drawRect(Rect.fromLTWH(sx - pW * 0.12, -pH / 2, pW * 0.24, pH), shine);
    canvas.restore();

    canvas.restore();

    _paintSparkles(canvas, px + pW / 2, py - pH * 0.2, houseW);
  }

  void _paintSparkles(Canvas canvas, double cx, double baseY, double houseW) {
    final sparkle = Paint()..color = const Color(0xFFFFD54F);
    for (var i = 0; i < 5; i++) {
      final cycle = (t * 0.8 + i * 0.19) % 1.0;
      final y = baseY - cycle * houseW * 0.35;
      final x = cx + math.sin((t * 2 + i * 2.4)) * houseW * 0.28;
      final alpha = math.sin(cycle * math.pi).clamp(0.0, 1.0);
      sparkle.color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.9);
      final r = houseW * 0.012 * (1.2 - cycle * 0.4);
      canvas.drawCircle(Offset(x, y), r, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.t != t;
}
