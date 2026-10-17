import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Brand palette for the welcome experience.
class _Palette {
  _Palette(bool dark)
      : bg = dark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFD),
        surface = dark ? const Color(0xFF131C2E) : Colors.white,
        ink = dark ? const Color(0xFFF2F6FB) : const Color(0xFF0E1A2B),
        muted = dark ? const Color(0xFF9AA8BA) : const Color(0xFF5B6B80),
        hairline = dark ? const Color(0x1FFFFFFF) : const Color(0xFFE6ECF3);

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color hairline;

  static const brand = Color(0xFF0A6CF0);
  static const brandLight = Color(0xFF3FB4FF);
  static const brandDeep = Color(0xFF0750C4);
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.entryAnimationDuration = const Duration(seconds: 3),
  });

  final Duration entryAnimationDuration;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: widget.entryAnimationDuration,
  );
  bool _isEntering = false;
  bool _introStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introStarted) return;
    _introStarted = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _introController.value = 1;
    } else {
      _introController.forward();
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleStartPressed() async {
    if (_isEntering) return;
    setState(() => _isEntering = true);
    await _entryController.forward();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Staggered fade + rise used by the intro animation.
  Widget _reveal(double start, double end, Widget child) {
    final t = Curves.easeOutCubic.transform(
      ((_introController.value - start) / (end - start)).clamp(0.0, 1.0),
    );
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = _Palette(dark);

    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _entryController]),
        builder: (context, _) {
          final entry = _entryController.value;
          final fill = Curves.easeInOutCubic
              .transform((entry / 0.8).clamp(0.0, 1.0));
          final exit = Curves.easeInCubic
              .transform(((entry - 0.78) / 0.22).clamp(0.0, 1.0));

          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _AmbientPainter(dark: dark, intensity: 1 + fill),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(builder: (context, constraints) {
                  final gutter = constraints.maxWidth < 400 ? 24.0 : 32.0;
                  final orbSize =
                      (constraints.maxHeight * 0.3).clamp(150.0, 220.0);
                  return SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: gutter, vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 40)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: IntrinsicHeight(
                            child: Opacity(
                              opacity: 1 - exit,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _reveal(0.0, 0.45, _BrandBar(palette: p)),
                                  const Spacer(),
                                  const SizedBox(height: 32),
                                  _reveal(
                                    0.1,
                                    0.6,
                                    Center(
                                      child: Transform.scale(
                                        scale: 1 + exit * 0.08,
                                        child: ExcludeSemantics(
                                          child: SizedBox.square(
                                            dimension: orbSize,
                                            child: CustomPaint(
                                              painter: _GaugeOrbPainter(
                                                dark: dark,
                                                fill: fill,
                                                surface: p.surface,
                                                track: p.hairline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  _reveal(
                                    0.25,
                                    0.75,
                                    Text(
                                      'SISTEM MONITORING & KENDALI AIR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _Palette.brand,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _reveal(
                                    0.3,
                                    0.8,
                                    Semantics(
                                      header: true,
                                      child: Text.rich(
                                        TextSpan(children: [
                                          const TextSpan(text: 'Pantau air,\n'),
                                          TextSpan(
                                            text: 'tenang setiap hari.',
                                            style: TextStyle(color: p.muted),
                                          ),
                                        ]),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: p.ink,
                                          fontSize: 32,
                                          height: 1.18,
                                          letterSpacing: -0.9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _reveal(
                                    0.4,
                                    0.9,
                                    Text(
                                      'Kelola semua wadah air Anda secara real-time, dalam satu aplikasi yang sederhana.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: p.muted,
                                        fontSize: 15,
                                        height: 1.55,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 32),
                                  _reveal(
                                    0.5,
                                    0.95,
                                    _FeatureRow(palette: p),
                                  ),
                                  const SizedBox(height: 24),
                                  _reveal(
                                    0.55,
                                    1.0,
                                    _StartButton(
                                      isEntering: _isEntering,
                                      progress: entry,
                                      onPressed: _handleStartPressed,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _reveal(
                                    0.6,
                                    1.0,
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text('Belum punya akun?',
                                            style: TextStyle(
                                                color: p.muted, fontSize: 13)),
                                        TextButton(
                                          onPressed: _isEntering
                                              ? null
                                              : () => Navigator.pushNamed(
                                                  context, '/register'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: _Palette.brand,
                                            minimumSize: const Size(48, 48),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                          ),
                                          child: const Text(
                                            'Daftar sekarang',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Palette.brandLight, _Palette.brandDeep],
            ),
          ),
          child: const Icon(Icons.water_drop_rounded,
              color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          'SIMONIKA',
          style: TextStyle(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _Palette.brand),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: palette.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)),
          ],
        );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 10,
      children: [
        item(Icons.bolt_rounded, 'Real-time'),
        item(Icons.insights_rounded, 'Monitoring'),
        item(Icons.tune_rounded, 'Kendali air'),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.isEntering,
    required this.progress,
    required this.onPressed,
  });

  final bool isEntering;
  final double progress;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round().clamp(0, 100);
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _Palette.brand.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: _Palette.brand),
            ),
            if (isEntering)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(color: _Palette.brandDeep),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isEntering ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size.fromHeight(56),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: radius),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    const Text('Mulai sekarang',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1)),
                    if (isEntering)
                      Text(
                        '$percent%',
                        key: const Key('welcome_entry_progress_text'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      )
                    else
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft ambient glows behind the content — intentionally understated.
class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({required this.dark, required this.intensity});
  final bool dark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final base = dark ? 0.18 : 0.10;
    void glow(Offset c, double r, Color color, double a) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(c, r, [
            color.withValues(alpha: (a * intensity).clamp(0.0, 1.0)),
            color.withValues(alpha: 0),
          ]),
      );
    }

    glow(Offset(size.width * 0.5, size.height * 0.3), size.width * 0.9,
        _Palette.brandLight, base);
    glow(Offset(size.width * 1.0, size.height * 1.0), size.width * 0.8,
        _Palette.brand, base * 0.6);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.dark != dark || old.intensity != intensity;
}

/// Hero gauge: a ring that reads the water level and a disc holding water.
/// [fill] goes 0 → 1 during the entry animation.
class _GaugeOrbPainter extends CustomPainter {
  const _GaugeOrbPainter({
    required this.dark,
    required this.fill,
    required this.surface,
    required this.track,
  });

  final bool dark;
  final double fill;
  final Color surface;
  final Color track;

  static const _idleLevel = 0.62;

  Path _drop(Offset c, double h) {
    final w = h * 0.72;
    return Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..cubicTo(c.dx + w * 0.12, c.dy - h * 0.28, c.dx + w / 2, c.dy - h * 0.02,
          c.dx + w / 2, c.dy + h * 0.16)
      ..arcToPoint(Offset(c.dx - w / 2, c.dy + h * 0.16),
          radius: Radius.circular(w / 2))
      ..cubicTo(c.dx - w / 2, c.dy - h * 0.02, c.dx - w * 0.12, c.dy - h * 0.28,
          c.dx, c.dy - h / 2)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final level = _idleLevel + (1 - _idleLevel) * fill;

    // Ring track + progress arc.
    final ringR = r * 0.9;
    final ringRect = Rect.fromCircle(center: c, radius: ringR);
    canvas.drawCircle(
        c,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = track);
    final sweep = math.pi * 2 * level;
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: const GradientRotation(-math.pi / 2),
          colors: const [_Palette.brandLight, _Palette.brand],
        ).createShader(ringRect),
    );
    final endAngle = -math.pi / 2 + sweep;
    final knob = c + Offset(math.cos(endAngle), math.sin(endAngle)) * ringR;
    canvas.drawCircle(knob, 6, Paint()..color = surface);
    canvas.drawCircle(knob, 3.5, Paint()..color = _Palette.brand);

    // Inner disc.
    final discR = r * 0.72;
    canvas.drawCircle(
      c.translate(0, 10),
      discR,
      Paint()
        ..color = _Palette.brand.withValues(alpha: dark ? 0.35 : 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(c, discR, Paint()..color = surface);

    // Water.
    final waterR = discR - 7;
    final top = c.dy + waterR - waterR * 2 * (level * 0.82);
    final amp = 5.0 * (1 - fill * 0.6);
    final phase = fill * math.pi * 3;
    Path wave(double shift, double a) {
      final path = Path()..moveTo(c.dx - waterR, top);
      for (var x = -waterR; x <= waterR; x += 2) {
        final y = top +
            math.sin((x / waterR) * math.pi * 1.2 + phase + shift) * a;
        path.lineTo(c.dx + x, y);
      }
      return path
        ..lineTo(c.dx + waterR, c.dy + waterR)
        ..lineTo(c.dx - waterR, c.dy + waterR)
        ..close();
    }

    final waterRect = Rect.fromCircle(center: c, radius: waterR);
    canvas.save();
    canvas.clipPath(Path()..addOval(waterRect));
    canvas.drawPath(
      wave(math.pi * 0.8, amp * 0.8).shift(const Offset(0, -4)),
      Paint()..color = _Palette.brandLight.withValues(alpha: 0.28),
    );
    final front = wave(0, amp);
    canvas.drawPath(
      front,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx, top),
          Offset(c.dx, c.dy + waterR),
          const [_Palette.brandLight, _Palette.brand],
        ),
    );

    // Drop glyph: brand colour above water, white where submerged.
    final drop = _drop(c.translate(0, -waterR * 0.08), waterR * 0.62);
    canvas.drawPath(drop, Paint()..color = _Palette.brand);
    canvas.clipPath(front);
    canvas.drawPath(drop, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugeOrbPainter old) =>
      old.fill != fill ||
      old.dark != dark ||
      old.surface != surface ||
      old.track != track;
}
