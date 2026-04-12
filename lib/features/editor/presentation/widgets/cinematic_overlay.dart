import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cinematic Overlay — golden particles · vignette · letterbox
// Animates via an external AnimationController (0.0 → 1.0 repeating).
// ─────────────────────────────────────────────────────────────────────────────

class CinematicOverlay extends StatelessWidget {
  final double progress; // 0.0–1.0 from AnimationController
  final double width;
  final double height;
  final bool showLetterbox;

  const CinematicOverlay({
    super.key,
    required this.progress,
    required this.width,
    required this.height,
    this.showLetterbox = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particle layer
        CustomPaint(
          painter: _GoldenParticlePainter(progress: progress),
          size: Size(width, height),
        ),
        // Vignette overlay
        _buildVignette(),
        // Cinematic letterbox bars
        if (showLetterbox) ...[
          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: height * 0.07,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // Bottom bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: height * 0.07,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.45),
            ],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Golden Particle Painter
// ─────────────────────────────────────────────────────────────────────────────

class _GoldenParticlePainter extends CustomPainter {
  final double progress;

  // Total number of particles rendered — tune for density
  static const int _kParticleCount = 60;

  _GoldenParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // Fixed seed = stable particles

    for (int i = 0; i < _kParticleCount; i++) {
      final seed = rng.nextDouble();
      final seed2 = rng.nextDouble();
      final seed3 = rng.nextDouble();
      final seed4 = rng.nextDouble();

      // Phase offset so each particle has a unique cycle
      final phase = seed;
      final speed = 0.15 + seed2 * 0.35; // Different drifting speeds

      // Looping position over time — particles float upward
      final t = ((progress * speed + phase) % 1.0);

      // Horizontal gentle sway
      final sway = math.sin((progress * speed * 2 * math.pi) + phase * math.pi * 4) * 0.04;
      final x = (seed3 + sway).clamp(0.02, 0.98) * size.width;
      // Vertical: start at bottom (1.0), float up to top (0.0)
      final y = (1.0 - t) * size.height;

      // Opacity follows a bell curve → appears and fades gracefully
      final opacity = _bellCurve(t) * (0.3 + seed4 * 0.5);

      // Size: small sparkles, randomised
      final radius = 1.0 + seed4 * 2.5;

      // Golden colour with warm variation
      final hue = 35.0 + seed2 * 20.0; // 35–55° → gold to amber
      final color = HSVColor.fromAHSV(opacity.clamp(0.0, 1.0), hue, 0.8, 1.0).toColor();

      final paint = Paint()..color = color..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Occasionally draw a tiny cross sparkle for extra shimmer
      if (seed4 > 0.7) {
        final armPaint = Paint()
          ..color = color.withValues(alpha: opacity * 0.6)
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round;
        final arm = radius * 2.5;
        canvas.drawLine(Offset(x - arm, y), Offset(x + arm, y), armPaint);
        canvas.drawLine(Offset(x, y - arm), Offset(x, y + arm), armPaint);
      }
    }

    // Draw a few slow light streaks (horizontal lens flares)
    _drawLightStreaks(canvas, size);
  }

  void _drawLightStreaks(Canvas canvas, Size size) {
    final streaks = [
      (0.25, 0.30), // (yRatio, xSpeedPhase)
      (0.65, 0.70),
      (0.48, 0.55),
    ];

    for (final (yRatio, phase) in streaks) {
      final t = (progress * 0.08 + phase) % 1.0;
      final x = t * size.width * 1.4 - size.width * 0.2;
      final y = yRatio * size.height;
      final opacity = _bellCurve(t) * 0.12;
      if (opacity <= 0) continue;

      final streakPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFE78A).withValues(alpha: 0.0),
            const Color(0xFFFFE78A).withValues(alpha: opacity),
            const Color(0xFFFFE78A).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(x - 80, y - 2, 160, 4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 80, y - 2, 160, 4), const Radius.circular(2)),
        streakPaint,
      );
    }
  }

  double _bellCurve(double t) {
    // Smooth fade-in at bottom, fade-out at top
    return math.sin(t * math.pi).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _GoldenParticlePainter old) =>
      old.progress != progress;
}
