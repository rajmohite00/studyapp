import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Rank Icon Factory ─────────────────────────────────────────────────────────
// Returns the correct CustomPainter for each rank tier (0-6).
CustomPainter rankIconPainter(int tierIndex, List<Color> gradient) {
  switch (tierIndex) {
    case 0: return _BronzeShieldPainter(gradient);
    case 1: return _SilverShieldStarPainter(gradient);
    case 2: return _GoldCrownPainter(gradient);
    case 3: return _PlatinumCrystalPainter(gradient);
    case 4: return _DiamondFacetPainter(gradient);
    case 5: return _MasterWingCrownPainter(gradient);
    case 6: return _GrandmasterTrophyPainter(gradient);
    default: return _BronzeShieldPainter(gradient);
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────
Paint _fill(List<Color> colors, Rect bounds) => Paint()
  ..shader = LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).createShader(bounds)
  ..style = PaintingStyle.fill;

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

// ── 0. Bronze Shield (plain kite-shield) ──────────────────────────────────────
class _BronzeShieldPainter extends CustomPainter {
  final List<Color> colors;
  const _BronzeShieldPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    final path = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.9, h * 0.2)
      ..lineTo(w * 0.9, h * 0.6)
      ..quadraticBezierTo(w * 0.9, h * 0.85, w * 0.5, h * 0.97)
      ..quadraticBezierTo(w * 0.1, h * 0.85, w * 0.1, h * 0.6)
      ..lineTo(w * 0.1, h * 0.2)
      ..close();

    canvas.drawPath(path, _fill(colors, r));
    canvas.drawPath(path, _stroke(Colors.white.withOpacity(0.5), w * 0.05));

    // Vertical center line
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.88),
        _stroke(Colors.white.withOpacity(0.35), w * 0.04));
    // Horizontal bar
    canvas.drawLine(Offset(w * 0.18, h * 0.42), Offset(w * 0.82, h * 0.42),
        _stroke(Colors.white.withOpacity(0.35), w * 0.04));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── 1. Silver Shield + Star ───────────────────────────────────────────────────
class _SilverShieldStarPainter extends CustomPainter {
  final List<Color> colors;
  const _SilverShieldStarPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    final shield = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.18)
      ..lineTo(w * 0.92, h * 0.58)
      ..quadraticBezierTo(w * 0.92, h * 0.86, w * 0.5, h * 0.97)
      ..quadraticBezierTo(w * 0.08, h * 0.86, w * 0.08, h * 0.58)
      ..lineTo(w * 0.08, h * 0.18)
      ..close();

    canvas.drawPath(shield, _fill(colors, r));
    canvas.drawPath(shield, _stroke(Colors.white.withOpacity(0.55), w * 0.045));

    // Star in centre
    _drawStar(canvas, Offset(w * 0.5, h * 0.52), w * 0.28, w * 0.13, 5,
        Colors.white.withOpacity(0.9), w * 0.025);
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, double innerR,
      int points, Color color, double strokeW) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── 2. Gold Crown ─────────────────────────────────────────────────────────────
class _GoldCrownPainter extends CustomPainter {
  final List<Color> colors;
  const _GoldCrownPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    // Crown body
    final crown = Path()
      ..moveTo(w * 0.08, h * 0.78)
      ..lineTo(w * 0.08, h * 0.42)
      ..lineTo(w * 0.28, h * 0.62)
      ..lineTo(w * 0.5, h * 0.18)
      ..lineTo(w * 0.72, h * 0.62)
      ..lineTo(w * 0.92, h * 0.42)
      ..lineTo(w * 0.92, h * 0.78)
      ..close();

    canvas.drawPath(crown, _fill(colors, r));
    canvas.drawPath(crown, _stroke(Colors.white.withOpacity(0.5), w * 0.04));

    // Base band
    final band = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.84, h * 0.12),
        Radius.circular(w * 0.04));
    canvas.drawRRect(band, _fill([colors.last, colors.first], r));
    canvas.drawRRect(band, _stroke(Colors.white.withOpacity(0.4), w * 0.03));

    // Jewels
    for (final dx in [0.18, 0.5, 0.82]) {
      canvas.drawCircle(Offset(w * dx, h * 0.80), w * 0.055,
          Paint()..color = Colors.white.withOpacity(0.9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── 3. Platinum Crystal (Octahedron silhouette) ───────────────────────────────
class _PlatinumCrystalPainter extends CustomPainter {
  final List<Color> colors;
  const _PlatinumCrystalPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    final top = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.85, h * 0.40)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.15, h * 0.40)
      ..close();

    final bottom = Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..lineTo(w * 0.85, h * 0.60)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.15, h * 0.60)
      ..close();

    canvas.drawPath(bottom,
        Paint()..shader = LinearGradient(colors: [colors.last, colors.first.withOpacity(0.6)])
            .createShader(r)
          ..style = PaintingStyle.fill);
    canvas.drawPath(top, _fill(colors, r));

    canvas.drawPath(top, _stroke(Colors.white.withOpacity(0.55), w * 0.038));
    canvas.drawPath(bottom, _stroke(Colors.white.withOpacity(0.35), w * 0.038));

    // Horizontal equator line
    canvas.drawLine(Offset(w * 0.15, h * 0.50), Offset(w * 0.85, h * 0.50),
        _stroke(Colors.white.withOpacity(0.4), w * 0.035));

    // Left & right facet lines from top
    canvas.drawLine(Offset(w * 0.50, h * 0.05), Offset(w * 0.15, h * 0.50),
        _stroke(Colors.white.withOpacity(0.25), w * 0.025));
    canvas.drawLine(Offset(w * 0.50, h * 0.05), Offset(w * 0.85, h * 0.50),
        _stroke(Colors.white.withOpacity(0.25), w * 0.025));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── 4. Diamond with Facets ────────────────────────────────────────────────────
class _DiamondFacetPainter extends CustomPainter {
  final List<Color> colors;
  const _DiamondFacetPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    // Outer diamond
    final diamond = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.96, h * 0.38)
      ..lineTo(w * 0.5, h * 0.96)
      ..lineTo(w * 0.04, h * 0.38)
      ..close();

    canvas.drawPath(diamond, _fill(colors, r));
    canvas.drawPath(diamond, _stroke(Colors.white.withOpacity(0.55), w * 0.04));

    // Top facet
    final topFacet = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.96, h * 0.38)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.04, h * 0.38)
      ..close();
    canvas.drawPath(topFacet,
        Paint()..color = Colors.white.withOpacity(0.18)..style = PaintingStyle.fill);

    // Facet lines
    for (final tx in [0.28, 0.72]) {
      canvas.drawLine(Offset(w * tx, h * 0.38), Offset(w * 0.5, h * 0.96),
          _stroke(Colors.white.withOpacity(0.22), w * 0.03));
    }
    canvas.drawLine(Offset(w * 0.5, h * 0.04), Offset(w * 0.5, h * 0.42),
        _stroke(Colors.white.withOpacity(0.35), w * 0.03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── 5. Master: Winged Crown ───────────────────────────────────────────────────
class _MasterWingCrownPainter extends CustomPainter {
  final List<Color> colors;
  const _MasterWingCrownPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    // Left wing
    final leftWing = Path()
      ..moveTo(w * 0.30, h * 0.55)
      ..cubicTo(w * 0.10, h * 0.50, w * 0.04, h * 0.30, w * 0.08, h * 0.20)
      ..cubicTo(w * 0.14, h * 0.36, w * 0.22, h * 0.42, w * 0.30, h * 0.55)
      ..close();

    // Right wing (mirrored)
    final rightWing = Path()
      ..moveTo(w * 0.70, h * 0.55)
      ..cubicTo(w * 0.90, h * 0.50, w * 0.96, h * 0.30, w * 0.92, h * 0.20)
      ..cubicTo(w * 0.86, h * 0.36, w * 0.78, h * 0.42, w * 0.70, h * 0.55)
      ..close();

    final wingPaint = Paint()
      ..shader = LinearGradient(colors: colors.reversed.toList())
          .createShader(r)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftWing, wingPaint);
    canvas.drawPath(rightWing, wingPaint);

    // Crown body
    final crown = Path()
      ..moveTo(w * 0.24, h * 0.82)
      ..lineTo(w * 0.24, h * 0.50)
      ..lineTo(w * 0.38, h * 0.65)
      ..lineTo(w * 0.50, h * 0.30)
      ..lineTo(w * 0.62, h * 0.65)
      ..lineTo(w * 0.76, h * 0.50)
      ..lineTo(w * 0.76, h * 0.82)
      ..close();

    canvas.drawPath(crown, _fill(colors, r));
    canvas.drawPath(crown, _stroke(Colors.white.withOpacity(0.5), w * 0.04));

    // Base
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.24, h * 0.79, w * 0.52, h * 0.10),
            Radius.circular(w * 0.03)),
        _fill([colors.last, colors.first], r));

    // Top jewel
    canvas.drawCircle(Offset(w * 0.5, h * 0.30), w * 0.055,
        Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── 6. Grandmaster Trophy ─────────────────────────────────────────────────────
class _GrandmasterTrophyPainter extends CustomPainter {
  final List<Color> colors;
  const _GrandmasterTrophyPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(0, 0, w, h);

    // Cup body
    final cup = Path()
      ..moveTo(w * 0.20, h * 0.10)
      ..lineTo(w * 0.80, h * 0.10)
      ..lineTo(w * 0.72, h * 0.55)
      ..quadraticBezierTo(w * 0.64, h * 0.68, w * 0.50, h * 0.70)
      ..quadraticBezierTo(w * 0.36, h * 0.68, w * 0.28, h * 0.55)
      ..close();

    canvas.drawPath(cup, _fill(colors, r));
    canvas.drawPath(cup, _stroke(Colors.white.withOpacity(0.55), w * 0.04));

    // Left handle
    final leftHandle = Path()
      ..moveTo(w * 0.20, h * 0.18)
      ..cubicTo(w * 0.02, h * 0.18, w * 0.02, h * 0.44, w * 0.20, h * 0.44);
    canvas.drawPath(leftHandle,
        Paint()..color = colors.first..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07..strokeCap = StrokeCap.round);
    canvas.drawPath(leftHandle, _stroke(Colors.white.withOpacity(0.4), w * 0.03));

    // Right handle
    final rightHandle = Path()
      ..moveTo(w * 0.80, h * 0.18)
      ..cubicTo(w * 0.98, h * 0.18, w * 0.98, h * 0.44, w * 0.80, h * 0.44);
    canvas.drawPath(rightHandle,
        Paint()..color = colors.first..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07..strokeCap = StrokeCap.round);
    canvas.drawPath(rightHandle, _stroke(Colors.white.withOpacity(0.4), w * 0.03));

    // Stem
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.43, h * 0.68, w * 0.14, h * 0.16),
            Radius.circular(w * 0.02)),
        _fill(colors, r));

    // Base
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.18, h * 0.82, w * 0.64, h * 0.12),
            Radius.circular(w * 0.04)),
        _fill([colors.last, colors.first], r));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.18, h * 0.82, w * 0.64, h * 0.12),
            Radius.circular(w * 0.04)),
        _stroke(Colors.white.withOpacity(0.35), w * 0.03));

    // Star in cup
    _drawStar(canvas, Offset(w * 0.5, h * 0.38), w * 0.20, w * 0.09, 5,
        Colors.white.withOpacity(0.9));
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, double innerR,
      int points, Color color) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
