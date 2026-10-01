import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0878DE),
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: dark ? colors.surface : const Color(0xFFF7FBFF),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                  child:
                      CustomPaint(painter: _WelcomeWaterPainter(dark: dark))),
            ),
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                final gutter = constraints.maxWidth < 400 ? 20.0 : 32.0;
                return SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: gutter, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48)
                            .clamp(0.0, double.infinity)),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF35B6FF),
                                    Color(0xFF086AC2)
                                  ]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.water_drop_outlined,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SIMONIKA',
                                      style: TextStyle(
                                          color: colors.onSurface,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5)),
                                  const SizedBox(height: 4),
                                  Text('SISTEM MONITORING\nDAN KENDALI AIR',
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 8,
                                          height: 1.4,
                                          letterSpacing: 1.6)),
                                ],
                              )),
                            ]),
                            const SizedBox(height: 64),
                            _MonitoringIllustration(colors: colors),
                            const SizedBox(height: 20),
                            Semantics(
                              header: true,
                              child: Text.rich(
                                TextSpan(children: [
                                  const TextSpan(text: 'Pantau air.\n'),
                                  TextSpan(
                                      text: 'Tenang setiap hari.',
                                      style: TextStyle(color: colors.primary)),
                                ]),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colors.onSurface,
                                    fontFamily: 'serif',
                                    fontFamilyFallback: const [
                                      'Georgia',
                                      'Times New Roman',
                                      'Noto Serif'
                                    ],
                                    fontSize: 36,
                                    height: 1.05,
                                    letterSpacing: -1.2,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pantau kondisi air dan kelola semua wadah Anda dengan mudah, dalam satu aplikasi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 14,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FeaturePill(
                                    icon: Icons.speed_outlined,
                                    label: 'Real-time',
                                    colors: colors),
                                _FeaturePill(
                                    icon: Icons.insights_outlined,
                                    label: 'Monitoring',
                                    colors: colors),
                                _FeaturePill(
                                    icon: Icons.tune_rounded,
                                    label: 'Kendali air',
                                    colors: colors),
                              ],
                            ),
                            const SizedBox(height: 20),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF12C4FF),
                                      Color(0xFF087CFA),
                                      Color(0xFF004CCB)
                                    ]),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                      color: colors.primary
                                          .withValues(alpha: 0.22),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8))
                                ],
                              ),
                              child: FilledButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/login'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28)),
                                ),
                                child: const Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  children: [
                                    Text('Mulai sekarang',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    Icon(Icons.arrow_forward_rounded, size: 20)
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Belum punya akun?',
                                    style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12)),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/register'),
                                  style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48)),
                                  child: const Text('Daftar sekarang',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill(
      {required this.icon, required this.label, required this.colors});
  final IconData icon;
  final String label;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: colors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MonitoringIllustration extends StatelessWidget {
  const _MonitoringIllustration({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
          child: SizedBox(
        width: 180,
        height: 160,
        child: CustomPaint(
            painter:
                _GlassTankPainter(dark: colors.brightness == Brightness.dark)),
      )),
    );
  }
}

class _GlassTankPainter extends CustomPainter {
  const _GlassTankPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(24, 6, size.width - 48, size.height - 16);
    final tank = RRect.fromRectAndRadius(rect, const Radius.circular(25));
    canvas.drawRRect(
        tank.shift(const Offset(0, 8)),
        Paint()
          ..color = const Color(0xFF008AE5).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawRRect(
        tank,
        Paint()
          ..shader = ui.Gradient.linear(
              rect.topLeft,
              rect.bottomRight,
              dark
                  ? [const Color(0xFF234966), const Color(0xFF102D45)]
                  : [
                      Colors.white,
                      const Color(0xFFC8EDFF),
                      const Color(0xFFF2FCFF)
                    ],
              dark ? [0, 1] : [0, 0.5, 1]));
    canvas.save();
    canvas.clipRRect(tank.deflate(6));
    final wave = Path()
      ..moveTo(rect.left, rect.top + 86)
      ..cubicTo(rect.left + 30, rect.top + 59, rect.right - 34, rect.top + 124,
          rect.right, rect.top + 74)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(
        wave,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, rect.top + 65), Offset(0, rect.bottom), [
            const Color(0xFF46C9FF),
            const Color(0xFF038EF0),
            const Color(0xFF60D9FF)
          ], [
            0,
            0.5,
            1
          ]));
    canvas.restore();
    canvas.drawRRect(
        tank,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: dark ? 0.35 : 0.95));
    canvas.drawRRect(
        tank.deflate(5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9BDCFF));
    final highlight = Path()
      ..moveTo(rect.left + 10, rect.bottom - 26)
      ..lineTo(rect.left + 10, rect.top + 27)
      ..quadraticBezierTo(
          rect.left + 10, rect.top + 10, rect.left + 30, rect.top + 10)
      ..lineTo(rect.right - 28, rect.top + 10);
    canvas.drawPath(
        highlight,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.85));
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(rect.right - 26, rect.top + 20 + i * 13),
          Offset(rect.right - 15, rect.top + 20 + i * 13),
          Paint()
            ..color = const Color(0xFF62BAFF)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
    final center = Offset(size.width / 2, 75);
    final drop = Path()
      ..moveTo(center.dx, center.dy - 29)
      ..cubicTo(center.dx - 8, center.dy - 12, center.dx - 24, center.dy,
          center.dx - 18, center.dy + 13)
      ..cubicTo(center.dx - 11, center.dy + 29, center.dx + 11, center.dy + 29,
          center.dx + 18, center.dy + 13)
      ..cubicTo(center.dx + 24, center.dy, center.dx + 8, center.dy - 12,
          center.dx, center.dy - 29)
      ..close();
    canvas.drawShadow(drop, const Color(0xFF0569B4), 5, false);
    canvas.drawPath(
        drop,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(center.dx, center.dy - 29),
              Offset(center.dx, center.dy + 25),
              [const Color(0xFF10B7FF), const Color(0xFF0061D4)]));
    canvas.save();
    canvas.translate(center.dx * 0.24, center.dy * 0.24);
    canvas.scale(0.76);
    canvas.drawPath(
        drop,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(center.dx, center.dy - 29),
              Offset(center.dx, center.dy + 25),
              [Colors.white, const Color(0xFFAEEBFF)]));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassTankPainter oldDelegate) => oldDelegate.dark != dark;
}

class _WelcomeWaterPainter extends CustomPainter {
  const _WelcomeWaterPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final alpha = dark ? 0.16 : 1.0;
    final sweep = Path()
      ..moveTo(w * 0.7, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.4)
      ..cubicTo(w * 0.65, h * 0.47, w * 0.2, h * 0.36, w * 0.47, h * 0.2)
      ..cubicTo(w * 0.7, h * 0.07, w * 0.72, 0, w * 0.7, 0)
      ..close();
    canvas.drawPath(
        sweep,
        Paint()
          ..shader = ui.Gradient.linear(Offset(w, 0), Offset(0, h * 0.5), [
            const Color(0xFFB2E3FF).withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0)
          ]));
    for (var bottom in [false, true]) {
      final y = bottom ? h - 70 : (h * 0.23).clamp(140.0, 180.0);
      for (var i = 0; i < 4; i++) {
        final shift = i * 10.0;
        final wave = Path()
          ..moveTo(0, y + shift)
          ..cubicTo(w * 0.32, y - 26 + shift, w * 0.45, y + 70 + shift,
              w * 0.72, y + shift)
          ..quadraticBezierTo(w * 0.9, y - 55 + shift, w, y - 60 + shift)
          ..lineTo(w, y - 34 + shift)
          ..cubicTo(w * 0.66, y + 18 + shift, w * 0.52, y + 88 + shift, 0,
              y + 22 + shift)
          ..close();
        canvas.drawPath(
            wave,
            Paint()
              ..shader = ui.Gradient.linear(Offset(0, y), Offset(w, y + 36), [
                const Color(0xFFD8F3FF).withValues(alpha: alpha * 0.7),
                const Color(0xFF79C9F5)
                    .withValues(alpha: alpha * (i == 1 ? 0.5 : 0.18)),
                Colors.white.withValues(alpha: alpha * 0.6)
              ], [
                0,
                0.5,
                1
              ]));
        if (i == 1)
          canvas.drawPath(
              wave,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..color = Colors.white.withValues(alpha: alpha * 0.8));
      }
    }
  }

  @override
  bool shouldRepaint(_WelcomeWaterPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
