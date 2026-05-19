import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({required this.child, super.key});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _c1;
  late AnimationController _c2;
  late AnimationController _c3;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = context.read<SettingsProvider>().appearance;
    final speed = settings.reducedMotion ? 0.0 : settings.animationSpeed;

    // Base durations
    const d1 = 7000;
    const d2 = 11000;
    const d3 = 17000;

    _c1 = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: speed > 0 ? (d1 ~/ speed) : 1000000))
      ..repeat(reverse: true);
    _c2 = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: speed > 0 ? (d2 ~/ speed) : 1000000))
      ..repeat(reverse: true);
    _c3 = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: speed > 0 ? (d3 ~/ speed) : 1000000))
      ..repeat(reverse: true);

    if (settings.reducedMotion) {
      _c1.stop();
      _c2.stop();
      _c3.stop();
    }
  }

  void _updateSpeeds() {
    final settings = context.read<SettingsProvider>().appearance;
    final speed = settings.reducedMotion ? 0.0 : settings.animationSpeed;

    _c1.duration =
        Duration(milliseconds: speed > 0 ? (7000 ~/ speed) : 1000000);
    _c2.duration =
        Duration(milliseconds: speed > 0 ? (11000 ~/ speed) : 1000000);
    _c3.duration =
        Duration(milliseconds: speed > 0 ? (17000 ~/ speed) : 1000000);

    if (settings.reducedMotion) {
      _c1.stop();
      _c2.stop();
      _c3.stop();
    } else {
      _c1.repeat(reverse: true);
      _c2.repeat(reverse: true);
      _c3.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateSpeeds();

    return Consumer<ThemeProvider>(
      builder: (_, theme, __) => AnimatedBuilder(
        animation: Listenable.merge([_c1, _c2, _c3]),
        builder: (_, __) => CustomPaint(
          painter: _BlobPainter(
            c1: theme.bgColor1,
            c2: theme.bgColor2,
            c3: theme.bgColor3,
            t1: _c1.value,
            t2: _c2.value,
            t3: _c3.value,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color c1, c2, c3;
  final double t1, t2, t3;
  _BlobPainter({
    required this.c1,
    required this.c2,
    required this.c3,
    required this.t1,
    required this.t2,
    required this.t3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black);

    void drawBlob(Color color, double cx, double cy, double radius) {
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withOpacity(0.75), Colors.transparent],
          ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
      );
    }

    drawBlob(c1, w * (0.15 + t1 * 0.35), h * (0.1 + t2 * 0.25), w * 0.65);
    drawBlob(c2, w * (0.75 - t2 * 0.3), h * (0.6 + t3 * 0.2), w * 0.60);
    drawBlob(c3, w * (0.45 + sin(t3 * pi) * 0.2),
        h * (0.4 + cos(t1 * pi) * 0.15), w * 0.50);

    // Dark vignette so text stays readable
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
          stops: const [0.35, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter o) =>
      o.t1 != t1 ||
      o.t2 != t2 ||
      o.t3 != t3 ||
      o.c1 != c1 ||
      o.c2 != c2 ||
      o.c3 != c3;
}
