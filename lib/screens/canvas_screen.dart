import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _starController;
  final List<Offset> _stars = List.generate(
      50, (_) => Offset(Random().nextDouble(), Random().nextDouble()));

  @override
  void initState() {
    super.initState();
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _starController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Waves
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) => CustomPaint(
              painter: _CanvasPainter(
                  _waveController.value, _starController.value, _stars),
              size: Size.infinite,
            ),
          ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_fullscreen_rounded,
                            color: Colors.white30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('SLEEP CANVAS',
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3)),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: Colors.white30),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Centered Song Info (Minimal)
                if (player.currentSong != null) ...[
                  Text(player.currentSong!.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(player.currentSong!.artist ?? 'Unknown Artist',
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 13)),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final double wavePhase;
  final double starAlpha;
  final List<Offset> stars;

  _CanvasPainter(this.wavePhase, this.starAlpha, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    // Background Gradient
    final bgGradient = RadialGradient(
      center: Alignment.center,
      colors: [
        const Color(0xFF1A1A2E),
        Colors.black,
      ],
      radius: 1.2,
    );
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = bgGradient.createShader(Offset.zero & size));

    // Stars
    for (var star in stars) {
      final opacity =
          (0.1 + 0.3 * starAlpha * (star.dx + star.dy) % 1.0).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        1.5 * starAlpha,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Waves
    for (int i = 0; i < 3; i++) {
      _drawWave(canvas, size, i, wavePhase);
    }
  }

  void _drawWave(Canvas canvas, Size size, int index, double phase) {
    final path = Path();
    final yBase = size.height * 0.7 + (index * 40);
    final amplitude = 20.0 + (index * 10);
    final frequency = 0.005 + (index * 0.002);

    path.moveTo(0, size.height);
    path.lineTo(0, yBase);

    for (double x = 0; x <= size.width; x += 5) {
      final y = yBase +
          amplitude *
              sin((x * frequency) + (phase * 2 * pi) + (index * pi / 2));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final colors = [
      const Color(0xFF8B5CF6).withOpacity(0.1 - index * 0.03),
      const Color(0xFFEC4899).withOpacity(0.05 - index * 0.02),
      Colors.transparent,
    ];

    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(Rect.fromLTWH(0, yBase - amplitude, size.width,
              size.height - (yBase - amplitude))));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
