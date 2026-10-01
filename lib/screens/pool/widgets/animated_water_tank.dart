import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWaterTank extends StatefulWidget {
  const AnimatedWaterTank(
      {super.key,
      required this.level,
      required this.colors,
      this.inletActive = false,
      this.outletActive = false,
      this.thresholds = const {}});
  final double? level;
  final ColorScheme colors;
  final bool inletActive;
  final bool outletActive;
  final Map<String, double> thresholds;

  @override
  State<AnimatedWaterTank> createState() => _AnimatedWaterTankState();
}

class _AnimatedWaterTankState extends State<AnimatedWaterTank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waves =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(AnimatedWaterTank oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  void _updateMotion() {
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.level == null ||
        !TickerMode.valuesOf(context).enabled) {
      _waves.stop();
    } else if (!_waves.isAnimating) {
      _waves.repeat();
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 260,
          height: 280,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: ((widget.level ?? 0) / 100).clamp(0.0, 1.0)),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            builder: (context, fill, _) => CustomPaint(
                painter: _TankPainter(
                    fill: fill,
                    waves: _waves,
                    colors: widget.colors,
                    inletActive: widget.inletActive,
                    outletActive: widget.outletActive,
                    thresholds: widget.thresholds)),
          ),
        ),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  _TankPainter(
      {required this.fill,
      required this.waves,
      required this.colors,
      required this.inletActive,
      required this.outletActive,
      required this.thresholds})
      : super(repaint: waves);
  final double fill;
  final Animation<double> waves;
  final ColorScheme colors;
  final bool inletActive;
  final bool outletActive;
  final Map<String, double> thresholds;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(44, 20, size.width - 88, size.height - 40);
    final tank = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(tank, Paint()..color = colors.surfaceContainerLow);
    canvas.save();
    canvas.clipRRect(tank.deflate(5));
    if (fill > 0) {
      for (var layer = 0; layer < 2; layer++) {
        final y = rect.bottom - rect.height * fill;
        final amplitude = math.min(6.0, rect.height * math.min(fill, 1 - fill));
        final phase = waves.value * math.pi * 2 + layer * math.pi * 0.65;
        final path = Path()..moveTo(rect.left, rect.bottom);
        for (var x = 0.0; x <= rect.width; x += 2) {
          path.lineTo(rect.left + x,
              y + math.sin(x / rect.width * math.pi * 2 + phase) * amplitude);
        }
        path
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(
            path,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: layer == 0
                    ? [
                        const Color(0xFF6ED7FF).withValues(alpha: 0.65),
                        const Color(0xFF48AFFF).withValues(alpha: 0.45)
                      ]
                    : const [
                        Color(0xFF25BAF6),
                        Color(0xFF087ADD),
                        Color(0xFF095BB5)
                      ],
              ).createShader(rect));
      }
    }
    if (inletActive && fill > 0) {
      for (var i = 0; i < 7; i++) {
        final progress = (waves.value + i / 7) % 1;
        final y = rect.bottom - progress * rect.height * fill;
        canvas.drawCircle(
            Offset(
                rect.left + 24 + math.sin(i + progress * math.pi * 2) * 9, y),
            2 + i % 3.0,
            Paint()
              ..color = Colors.white.withValues(alpha: (1 - progress) * 0.4));
      }
    }
    canvas.restore();
    for (var i = 0; i <= 4; i++) {
      final y = rect.bottom - rect.height * i / 4;
      final label = TextPainter(
          text: TextSpan(
              text: '${i * 25}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant)),
          textDirection: TextDirection.ltr)
        ..layout();
      label.paint(canvas, Offset(rect.left - 30, y - label.height / 2));
      canvas.drawLine(
          Offset(rect.left - 8, y),
          Offset(rect.left - 3, y),
          Paint()
            ..color = colors.outlineVariant
            ..strokeWidth = 1);
    }
    final markerColors = [
      colors.error,
      colors.primary,
      const Color(0xFF0B9C8B)
    ];
    var markerIndex = 0;
    for (final entry in thresholds.entries) {
      final y = rect.bottom - rect.height * entry.value.clamp(0.0, 100.0) / 100;
      final color = markerColors[markerIndex++ % markerColors.length];
      for (var x = rect.left + 8; x < rect.right - 8; x += 10) {
        canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 5, rect.right - 8), y),
            Paint()
              ..color = color.withValues(alpha: 0.75)
              ..strokeWidth = 1.3);
      }
      canvas.drawCircle(Offset(rect.right + 6, y), 3, Paint()..color = color);
    }
    _pipe(
        canvas,
        Path()
          ..moveTo(rect.left - 30, rect.top + 30)
          ..lineTo(rect.left - 14, rect.top + 30)
          ..lineTo(rect.left - 14, rect.top + 52)
          ..lineTo(rect.left + 4, rect.top + 52),
        inletActive,
        colors.primary);
    _pipe(
        canvas,
        Path()
          ..moveTo(rect.right - 4, rect.bottom - 22)
          ..lineTo(rect.right + 14, rect.bottom - 22)
          ..lineTo(rect.right + 14, rect.bottom - 2)
          ..lineTo(rect.right + 32, rect.bottom - 2),
        outletActive,
        const Color(0xFF0B9C8B));
    canvas.drawRRect(
        tank,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colors.primary.withValues(alpha: 0.3));
    canvas.drawRRect(
        tank.deflate(5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colors.surfaceContainerLowest.withValues(alpha: 0.8));
    for (var i = 1; i < 10; i++) {
      final y = rect.bottom - rect.height * i / 10;
      canvas.drawLine(
          Offset(rect.right - 19, y),
          Offset(rect.right - (i == 5 ? 36 : 28), y),
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = colors.onSurface.withValues(alpha: 0.35));
    }
    canvas.drawLine(
        Offset(rect.left + 14, rect.top + 30),
        Offset(rect.left + 14, rect.bottom - 25),
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.5));
  }

  void _pipe(Canvas canvas, Path path, bool active, Color color) {
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = colors.outlineVariant);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = active
              ? color.withValues(alpha: 0.4)
              : colors.surfaceContainerHighest);
    if (active) {
      for (final metric in path.computeMetrics()) {
        for (var i = 0; i < 3; i++) {
          final point = metric
              .getTangentForOffset(((waves.value + i / 3) % 1) * metric.length)
              ?.position;
          if (point != null)
            canvas.drawCircle(point, 2, Paint()..color = color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TankPainter old) =>
      old.fill != fill ||
      old.colors != colors ||
      old.inletActive != inletActive ||
      old.outletActive != outletActive ||
      old.thresholds != thresholds;
}
