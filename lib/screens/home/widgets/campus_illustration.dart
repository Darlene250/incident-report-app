import 'package:flutter/material.dart';

/// Flat campus illustration (one building, two trees) drawn with a painter so no
/// image assets are needed on any platform.
class CampusIllustration extends StatelessWidget {
  const CampusIllustration({super.key, this.width = 96, this.height = 88});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CampusPainter()),
    );
  }
}

class _CampusPainter extends CustomPainter {
  static const Color _building = Color(0xFFF7D9EC);
  static const Color _roof = Color(0xFFD6BFFF);
  static const Color _accent = Color(0xFFC7A6F6);
  static const Color _trunk = Color(0xFF9B6B4E);
  static const Color _leaf = Color(0xFF4FC58A);
  static const Color _leafLight = Color(0xFF7EDCA8);
  static const Color _leafDark = Color(0xFF3FB77B);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()..isAntiAlias = true;

    // Soft glow behind the scene.
    paint.color = Colors.white.withValues(alpha: 0.16);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.48, h * 0.9), width: w * 0.86, height: h * 0.18),
      paint,
    );

    // Building body.
    paint.color = _building;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.36, w * 0.54, h * 0.54),
        Radius.circular(w * 0.035),
      ),
      paint,
    );

    // Roof.
    paint.color = _roof;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.27, w * 0.62, h * 0.11),
        Radius.circular(w * 0.03),
      ),
      paint,
    );

    // Windows.
    paint.color = Colors.white.withValues(alpha: 0.88);
    for (final double left in <double>[0.27, 0.59]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * left, h * 0.46, w * 0.12, h * 0.13),
          Radius.circular(w * 0.02),
        ),
        paint,
      );
    }

    // Door.
    paint.color = _accent;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.42, h * 0.68, w * 0.10, h * 0.22),
        topLeft: Radius.circular(w * 0.05),
        topRight: Radius.circular(w * 0.05),
      ),
      paint,
    );

    _paintTree(
      canvas,
      paint,
      baseX: w * 0.09,
      groundY: h * 0.92,
      trunkWidth: w * 0.035,
      trunkHeight: h * 0.22,
      canopyRadius: w * 0.13,
      canopy: _leaf,
      highlight: _leafLight,
    );
    _paintTree(
      canvas,
      paint,
      baseX: w * 0.88,
      groundY: h * 0.92,
      trunkWidth: w * 0.032,
      trunkHeight: h * 0.18,
      canopyRadius: w * 0.115,
      canopy: _leafDark,
      highlight: _leafLight,
    );
  }

  void _paintTree(
    Canvas canvas,
    Paint paint, {
    required double baseX,
    required double groundY,
    required double trunkWidth,
    required double trunkHeight,
    required double canopyRadius,
    required Color canopy,
    required Color highlight,
  }) {
    paint.color = _trunk;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(baseX - trunkWidth / 2, groundY - trunkHeight, trunkWidth, trunkHeight),
        Radius.circular(trunkWidth / 2),
      ),
      paint,
    );

    final Offset crown = Offset(baseX, groundY - trunkHeight - canopyRadius * 0.45);
    paint.color = canopy;
    canvas.drawCircle(crown, canopyRadius, paint);
    canvas.drawCircle(crown.translate(-canopyRadius * 0.6, canopyRadius * 0.4), canopyRadius * 0.7, paint);
    canvas.drawCircle(crown.translate(canopyRadius * 0.6, canopyRadius * 0.38), canopyRadius * 0.66, paint);

    paint.color = highlight.withValues(alpha: 0.85);
    canvas.drawCircle(crown.translate(-canopyRadius * 0.3, -canopyRadius * 0.3), canopyRadius * 0.42, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
