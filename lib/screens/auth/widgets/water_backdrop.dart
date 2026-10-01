import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Decorative water artwork stays crisp at every screen density.
class WaterBackdropPainter extends CustomPainter {
  const WaterBackdropPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final opacity = dark ? 0.12 : 1.0;
    final blue = const Color(0xFFBDE4FF).withValues(alpha: opacity);
    final pale = const Color(0xFFE7F5FF).withValues(alpha: opacity);
    final header = (h * 0.27).clamp(150.0, 220.0);
    final sweep = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w, 0)
      ..lineTo(w, header)
      ..cubicTo(w * 0.88, header * 0.75, w * 0.52, header * 0.75, w * 0.65,
          header * 0.38)
      ..cubicTo(w * 0.73, header * 0.1, w * 0.88, 0, w, 0)
      ..close();
    canvas.drawPath(sweep, Paint()..color = pale);
    for (var i = 0; i < 3; i++) {
      final y = header - 28 + i * 13;
      final wave = Path()
        ..moveTo(0, y)
        ..cubicTo(w * 0.28, y - 35, w * 0.62, y + 48, w, y + 10)
        ..lineTo(w, y + 28)
        ..cubicTo(w * 0.64, y + 70, w * 0.32, y - 10, 0, y + 22)
        ..close();
      canvas.drawPath(
          wave,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, y),
              Offset(w, y + 30),
              [i == 1 ? blue : pale, blue.withValues(alpha: opacity * 0.15)],
            ));
    }
    final bottom = Path()
      ..moveTo(0, h - 50)
      ..cubicTo(w * 0.36, h - 115, w * 0.58, h + 10, w, h - 80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(bottom, Paint()..color = pale);
    final bottomRipple = Path()
      ..moveTo(0, h - 18)
      ..cubicTo(w * 0.36, h - 100, w * 0.7, h + 30, w, h - 42)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        bottomRipple, Paint()..color = blue.withValues(alpha: opacity * 0.45));
    final dropHeight = (w * 0.30).clamp(85.0, 125.0);
    _drop(canvas, Offset(w - dropHeight * 0.65, header - dropHeight - 8),
        dropHeight, opacity);
    _drop(canvas, Offset(w - dropHeight * 1.12, header - 55), 15, opacity);
    _drop(canvas, Offset(w - dropHeight * 1.04, header - 92), 11, opacity);
  }

  void _drop(Canvas canvas, Offset origin, double height, double opacity) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    final width = height * 0.68;
    final path = Path()
      ..moveTo(width * 0.5, 0)
      ..cubicTo(width * 0.43, height * 0.24, 0, height * 0.51, 0, height * 0.7)
      ..cubicTo(0, height * 1.1, width, height * 1.1, width, height * 0.7)
      ..cubicTo(
          width, height * 0.51, width * 0.58, height * 0.24, width * 0.5, 0)
      ..close();
    canvas.drawShadow(path,
        const Color(0xFF389CD5).withValues(alpha: opacity * 0.4), 8, true);
    canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(width, height),
            [
              Colors.white.withValues(alpha: opacity),
              const Color(0xFFA1DDFF).withValues(alpha: opacity),
              const Color(0xFF4AABE9).withValues(alpha: opacity),
              const Color(0xFFD8F3FF).withValues(alpha: opacity)
            ],
            [0, 0.35, 0.72, 1],
          ));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: opacity * 0.8));
    final highlight = Path()
      ..moveTo(width * 0.46, height * 0.12)
      ..cubicTo(width * 0.38, height * 0.35, width * 0.12, height * 0.54,
          width * 0.15, height * 0.72);
    canvas.drawPath(
        highlight,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = height * 0.045
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: opacity * 0.9));
    canvas.restore();
  }

  @override
  bool shouldRepaint(WaterBackdropPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
