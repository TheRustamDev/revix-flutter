import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class PulseScreen extends StatefulWidget {
  const PulseScreen({super.key});

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _rotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _backgroundGlow(),
          Column(
            children: [
              const SizedBox(height: 60),
              _header(),
              const Spacer(),
              _pulseOrb(),
              const Spacer(),
              _moodSelector(),
              const SizedBox(height: 100),
            ],
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white60, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow() => AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8B5CF6)
                    .withOpacity(0.15 * _pulseController.value),
                Colors.black,
              ],
              radius: 1.5,
            ),
          ),
        ),
      );

  Widget _header() => const Column(
        children: [
          Text('REVIX PULSE',
              style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4)),
          SizedBox(height: 8),
          Text('AI Mood Scanner Active',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );

  Widget _pulseOrb() => AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotateController]),
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 250 + (20 * _pulseController.value),
              height: 250 + (20 * _pulseController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899)
                        .withOpacity(0.2 * _pulseController.value),
                    blurRadius: 50,
                    spreadRadius: 10,
                  )
                ],
              ),
            ),
            // Rotating ring
            Transform.rotate(
              angle: _rotateController.value * pi * 2,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _DashedCirclePainter(),
              ),
            ),
            // Core
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    blurRadius: 30.0,
                    spreadRadius: 5.0,
                  )
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 50),
            ),
          ],
        ),
      );

  Widget _moodSelector() => Column(
        children: [
          const Text('How are you feeling?',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _moodIcon(context, '🔥', 'Hype', 'high energy phonk gym hits'),
              _moodIcon(
                  context, '☁️', 'Chill', 'lofi hip hop chill study beats'),
              _moodIcon(
                  context, '💔', 'Sad', 'sad lofi bollywood mashup hindi'),
              _moodIcon(
                  context, '⚡', 'Energetic', 'upbeat pop happy hits 2024'),
            ],
          ),
        ],
      );

  Widget _moodIcon(
      BuildContext context, String emoji, String label, String query) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    return GestureDetector(
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Scanning for your $label mood...'),
          backgroundColor: const Color(0xFF8B5CF6),
          duration: const Duration(seconds: 2),
        ));
        await player.search(query);
        if (player.searchResults.isNotEmpty) {
          await player.playSong(player.searchResults.first);
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A2E),
              border: Border.all(color: Colors.white10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dashCount = 30;
    const dashWidth = 0.1;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width / 2),
        i * (2 * pi / dashCount),
        dashWidth,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
