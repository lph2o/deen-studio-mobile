import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quran Animation Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Particle effects (golden particles, divine radiance, etc.)
class ParticlePainter extends CustomPainter {
  final double progress;
  final Color particleColor;
  final int particleCount;
  final bool isGolden;
  final double particleSize;

  ParticlePainter({
    required this.progress,
    this.particleColor = const Color(0xFFFFD700),
    this.particleCount = 60,
    this.isGolden = true,
    this.particleSize = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final particles = <({Offset pos, double size, double opacity})>[];
    for (var i = 0; i < particleCount; i++) {
      final px = rng.nextDouble() * size.width;
      final py = rng.nextDouble() * size.height;
      final pSize = rng.nextDouble() * particleSize + 1;
      final revealThreshold = i / particleCount;
      if (progress >= revealThreshold) {
        final fadeIn = math.min(1.0, (progress - revealThreshold) * 5);
        final shimmer = 0.7 + 0.3 * math.sin(progress * math.pi * 2 + i);
        particles.add((
          pos: Offset(px, py),
          size: pSize,
          opacity: fadeIn * shimmer,
        ));
      }
    }
    for (final p in particles) {
      final color = isGolden
          ? particleColor.withValues(alpha: p.opacity)
          : particleColor.withValues(alpha: p.opacity * 0.8);
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p.pos, p.size, paint);
      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: p.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(p.pos, p.size * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Wave effect (sacred ripple, mercy wave, river flow)
class WavePainter extends CustomPainter {
  final double progress;
  final double amplitude;
  final Color waveColor;
  final int waveCount;
  final double frequency;

  WavePainter({
    required this.progress,
    this.amplitude = 12.0,
    this.waveColor = const Color(0xFF4FC3F7),
    this.waveCount = 3,
    this.frequency = 0.02,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var w = 0; w < waveCount; w++) {
      final path = Path();
      final waveOffset = w * 0.33;
      final waveProgress = math.max(0.0, math.min(1.0, (progress - waveOffset) * 2));
      if (waveProgress <= 0) continue;

      final visibleWidth = size.width * waveProgress;
      final yBase = size.height * (0.5 + w * 0.12);

      path.moveTo(0, yBase);
      for (var x = 0; x <= visibleWidth; x += 2) {
        final y = yBase +
            math.sin(x * frequency + progress * math.pi * 2 + w) *
                amplitude *
                waveProgress;
        path.lineTo(x.toDouble(), y);
      }

      final paint = Paint()
        ..color = waveColor.withValues(alpha: 0.3 * waveProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.amplitude != amplitude;
}

/// Calligraphy stroke effect (living calligraphy, ink flow)
class CalligraphyStrokePainter extends CustomPainter {
  final double progress;
  final Color inkColor;
  final double strokeThickness;

  CalligraphyStrokePainter({
    required this.progress,
    this.inkColor = const Color(0xFF1A1A2E),
    this.strokeThickness = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final drawLength = size.width * progress;

    path.moveTo(0, size.height * 0.5);
    var x = 0.0;
    while (x <= drawLength) {
      final t = x / size.width;
      final y = size.height * 0.5 +
          math.sin(t * math.pi * 4) * 15 * progress +
          math.sin(t * math.pi * 8) * 5 * progress;
      path.lineTo(x, y);
      x += 2;
    }

    final paint = Paint()
      ..color = inkColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeThickness
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // Ink drip effect at leading edge
    if (progress > 0.05 && progress < 0.95) {
      final tipX = drawLength;
      final tipY = size.height * 0.5 +
          math.sin(progress * math.pi * 4) * 15 * progress +
          math.sin(progress * math.pi * 8) * 5 * progress;
      for (var i = 0; i < 5; i++) {
        final dropPaint = Paint()
          ..color = inkColor.withValues(alpha: 0.3 - i * 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(
          Offset(tipX + i * 3, tipY + i * 4),
          1.5 - i * 0.2,
          dropPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CalligraphyStrokePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Crescent moon
class CrescentMoonPainter extends CustomPainter {
  final double progress;
  final Color moonColor;
  final Offset position;
  final double size;

  CrescentMoonPainter({
    required this.progress,
    this.moonColor = const Color(0xFFFFF8DC),
    this.position = Offset.zero,
    this.size = 40.0,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2 + position.dx;
    final cy = canvasSize.height / 2 + position.dy - 20 * (1 - progress);
    final s = size * progress;

    if (s <= 0) return;

    // Moon glow
    final glowPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.15 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), s * 1.5, glowPaint);

    // Crescent shape
    final moonPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.9 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), s, moonPaint);

    // Cutout circle to create crescent
    final cutoutPaint = Paint()
      ..color = const Color(0xFF000000)
      ..blendMode = BlendMode.dstOut;
    canvas.saveLayer(
      Rect.fromLTWH(cx - s * 2, cy - s * 2, s * 4, s * 4),
      Paint(),
    );
    canvas.drawCircle(Offset(cx, cy), s, moonPaint);
    canvas.drawCircle(Offset(cx + s * 0.4, cy - s * 0.1), s * 0.85, cutoutPaint);
    canvas.restore();

    // Small stars around moon
    final starRng = math.Random(7);
    for (var i = 0; i < 5; i++) {
      final angle = starRng.nextDouble() * math.pi * 2;
      final dist = s * (1.2 + starRng.nextDouble() * 0.8);
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist;
      final starPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: progress * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(sx, sy), 1.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CrescentMoonPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Constellation / stars effect
class ConstellationPainter extends CustomPainter {
  final double progress;
  final Color starColor;
  final int starCount;

  ConstellationPainter({
    required this.progress,
    this.starColor = const Color(0xFFFFD700),
    this.starCount = 15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final stars = <Offset>[];
    for (var i = 0; i < starCount; i++) {
      stars.add(Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      ));
    }

    // Draw connecting lines
    for (var i = 0; i < stars.length - 1; i++) {
      final revealProgress = math.max(0.0, math.min(1.0, (progress - i / starCount) * starCount));
      if (revealProgress > 0) {
        final linePaint = Paint()
          ..color = starColor.withValues(alpha: 0.2 * revealProgress)
          ..strokeWidth = 1.0;
        canvas.drawLine(stars[i], stars[i + 1], linePaint);
      }
    }

    // Draw stars
    for (var i = 0; i < stars.length; i++) {
      final revealThreshold = i / starCount;
      if (progress >= revealThreshold) {
        final fadeIn = math.min(1.0, (progress - revealThreshold) * 4);
        final twinkle = 0.7 + 0.3 * math.sin(progress * math.pi * 4 + i);

        // Star glow
        final glowPaint = Paint()
          ..color = starColor.withValues(alpha: fadeIn * twinkle * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(stars[i], 12, glowPaint);

        // Star core
        final starPaint = Paint()
          ..color = starColor.withValues(alpha: fadeIn * twinkle);
        canvas.drawCircle(stars[i], 3, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Falling objects (butterflies, leaves, petals, rain drops)
class FallingObjectsPainter extends CustomPainter {
  final double progress;
  final String objectType;
  final Color objectColor;
  final int objectCount;

  FallingObjectsPainter({
    required this.progress,
    this.objectType = 'leaf',
    this.objectColor = const Color(0xFFFF6B6B),
    this.objectCount = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(55);
    for (var i = 0; i < objectCount; i++) {
      final revealThreshold = i / objectCount;
      if (progress < revealThreshold) continue;

      final baseX = rng.nextDouble() * size.width;
      final fallProgress = (progress - revealThreshold) / (1 - revealThreshold);
      final y = -20 + fallProgress * (size.height + 40);

      if (y < -20 || y > size.height + 20) continue;

      // Sway motion
      final sway = math.sin(progress * math.pi * 4 + i * 0.7) * 15;
      final x = baseX + sway;
      final fadeIn = math.min(1.0, fallProgress * 3);
      final fadeOut = math.max(0.0, 1 - fallProgress * 0.5);
      final alpha = fadeIn * fadeOut;

      switch (objectType) {
        case 'butterfly':
          _drawButterfly(canvas, Offset(x, y), alpha);
          break;
        case 'leaf':
          _drawLeaf(canvas, Offset(x, y), alpha);
          break;
        case 'petal':
          _drawPetal(canvas, Offset(x, y), alpha);
          break;
        case 'drop':
          _drawDrop(canvas, Offset(x, y), alpha);
          break;
      }
    }
  }

  void _drawButterfly(Canvas canvas, Offset pos, double alpha) {
    final paint = Paint()
      ..color = objectColor.withValues(alpha: alpha * 0.8);
    // Wings
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawOval(Rect.fromLTWH(-6, -4, 5, 8), paint);
    canvas.drawOval(Rect.fromLTWH(1, -4, 5, 8), paint);
    // Body
    canvas.drawOval(Rect.fromLTWH(-0.5, -3, 1, 6), Paint()..color = const Color(0xFF333333).withValues(alpha: alpha));
    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, Offset pos, double alpha) {
    final paint = Paint()..color = objectColor.withValues(alpha: alpha * 0.7);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(math.pi / 6);
    final path = Path()
      ..moveTo(0, -6)
      ..quadraticBezierTo(4, 0, 0, 6)
      ..quadraticBezierTo(-4, 0, 0, -6);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPetal(Canvas canvas, Offset pos, double alpha) {
    final paint = Paint()..color = objectColor.withValues(alpha: alpha * 0.8);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    final path = Path()
      ..moveTo(0, -5)
      ..quadraticBezierTo(5, 0, 0, 5)
      ..quadraticBezierTo(-5, 0, 0, -5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawDrop(Canvas canvas, Offset pos, double alpha) {
    final paint = Paint()..color = objectColor.withValues(alpha: alpha * 0.6);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawCircle(Offset(0, 2), 3, paint);
    // Teardrop shape
    final path = Path()
      ..moveTo(0, -5)
      ..quadraticBezierTo(3, 0, 3, 2)
      ..arcTo(Rect.fromLTWH(-3, 0, 6, 4), 0, math.pi, false)
      ..quadraticBezierTo(3, 0, 0, -5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FallingObjectsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Smoke effect (incense smoke)
class SmokePainter extends CustomPainter {
  final double progress;
  final Color smokeColor;

  SmokePainter({
    required this.progress,
    this.smokeColor = const Color(0xFF9E9E9E),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final smokeStreams = 3;
    for (var s = 0; s < smokeStreams; s++) {
      final baseX = size.width * (0.3 + s * 0.2);
      final path = Path();
      path.moveTo(baseX, size.height);

      final streamProgress = math.max(0.0, math.min(1.0, (progress - s * 0.1) * 1.3));
      final maxHeight = size.height * streamProgress;

      for (var y = 0; y <= maxHeight; y += 4) {
        final t = y / size.height;
        final x = baseX +
            math.sin(t * math.pi * 3 + s * 2 + progress * math.pi) * (20 + t * 30) +
            math.sin(t * math.pi * 5) * 10;
        path.lineTo(x, size.height - y);
      }

      final paint = Paint()
        ..color = smokeColor.withValues(alpha: 0.15 * streamProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 + (1 - streamProgress) * 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SmokePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Gradient sweep (rainbow, sunset, aurora)
class GradientSweepPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final bool isVertical;

  GradientSweepPainter({
    required this.progress,
    required this.colors,
    this.isVertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sweepLength = progress * (isVertical ? size.height : size.width);
    final rect = isVertical
        ? Rect.fromLTWH(0, 0, size.width, sweepLength)
        : Rect.fromLTWH(0, 0, sweepLength, size.height);

    final gradient = isVertical
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          )
        : LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: colors,
          );

    final paint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GradientSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Spiral effect (golden spiral, galaxy)
class SpiralPainter extends CustomPainter {
  final double progress;
  final Color spiralColor;
  final bool isGalaxy;

  SpiralPainter({
    required this.progress,
    this.spiralColor = const Color(0xFFFFD700),
    this.isGalaxy = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = math.min(cx, cy) * 0.8;
    final path = Path();
    final totalAngle = progress * math.pi * 8;

    path.moveTo(cx, cy);
    var angle = 0.0;
    while (angle <= totalAngle) {
      final r = (angle / (math.pi * 8)) * maxRadius;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      path.lineTo(x, y);
      angle += 0.1;
    }

    final paint = Paint()
      ..color = spiralColor.withValues(alpha: 0.6 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isGalaxy ? 3.0 : 2.0
      ..maskFilter = isGalaxy
          ? const MaskFilter.blur(BlurStyle.normal, 5)
          : null;
    canvas.drawPath(path, paint);

    if (isGalaxy) {
      // Center glow
      final glowPaint = Paint()
        ..color = spiralColor.withValues(alpha: 0.2 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(cx, cy), maxRadius * progress, glowPaint);

      // Scattered stars
      final rng = math.Random(33);
      for (var i = 0; i < 30; i++) {
        if (rng.nextDouble() > progress) continue;
        final starAngle = rng.nextDouble() * math.pi * 2;
        final starDist = rng.nextDouble() * maxRadius * progress;
        final sx = cx + math.cos(starAngle) * starDist;
        final sy = cy + math.sin(starAngle) * starDist;
        final starPaint = Paint()
          ..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.5 * progress);
        canvas.drawCircle(Offset(sx, sy), 1 + rng.nextDouble() * 2, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpiralPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Fire effect (sacred fire)
class FirePainter extends CustomPainter {
  final double progress;

  FirePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(88);
    final flameCount = (progress * 40).round();

    for (var i = 0; i < flameCount; i++) {
      final baseX = size.width * (0.2 + rng.nextDouble() * 0.6);
      final flameProgress = math.max(0.0, math.min(1.0, (progress - i / 40) * 2));
      if (flameProgress <= 0) continue;

      final maxHeight = size.height * 0.6 * flameProgress;
      final path = Path();
      path.moveTo(baseX, size.height);

      for (var y = 0; y <= maxHeight; y += 3) {
        final t = y / maxHeight;
        const flicker = 8.0;
        final x = baseX +
            math.sin(y * 0.15 + progress * 10 + i) * flicker * (1 - t) +
            math.sin(y * 0.05 - progress * 5) * flicker * 0.5;
        path.lineTo(x, size.height - y);
      }

      final firePaint = Paint()
        ..color = (i % 3 == 0
                ? const Color(0xFFFF4500)
                : i % 3 == 1
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFF6B35))
            .withValues(alpha: 0.5 * flameProgress * (1 - i / 40))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, firePaint);
    }

    // Bottom glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.15 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 20, size.width, 20),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FirePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Lightning effect
class LightningPainter extends CustomPainter {
  final double progress;

  LightningPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(123);
    final flashPhase = (progress * 4).floor();
    final flashIntensity = flashPhase % 2 == 0
        ? math.sin(progress * math.pi * 4) * 0.5 + 0.5
        : 0.0;

    if (flashIntensity <= 0.05) return;

    // Draw lightning bolts
    final boltCount = 2 + rng.nextInt(3);
    for (var b = 0; b < boltCount; b++) {
      final startX = rng.nextDouble() * size.width;
      final path = Path();
      path.moveTo(startX, 0);

      var x = startX;
      var y = 0.0;
      final segmentLength = 15 + rng.nextDouble() * 20;
      while (y < size.height) {
        x += (rng.nextDouble() - 0.5) * 40;
        y += segmentLength;
        path.lineTo(x, y);

        // Branch
        if (rng.nextDouble() > 0.6) {
          final branchPath = Path();
          branchPath.moveTo(x, y);
          var bx = x;
          var by = y;
          for (var i = 0; i < 3; i++) {
            bx += (rng.nextDouble() - 0.5) * 30;
            by += segmentLength * 0.6;
            branchPath.lineTo(bx, by);
          }
          final branchPaint = Paint()
            ..color = const Color(0xFFADD8E6).withValues(alpha: flashIntensity * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawPath(branchPath, branchPaint);
        }
      }

      final boltPaint = Paint()
        ..color = const Color(0xFFADD8E6).withValues(alpha: flashIntensity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, boltPaint);
    }

    // Flash overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white.withValues(alpha: flashIntensity * 0.1),
    );
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Mosaic tile assembly
class MosaicPainter extends CustomPainter {
  final double progress;
  final Color tileColor;
  final double tileSize;

  MosaicPainter({
    required this.progress,
    this.tileColor = const Color(0xFF4A90D9),
    this.tileSize = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / tileSize).ceil();
    final rows = (size.height / tileSize).ceil();
    final totalTiles = cols * rows;
    final visibleTiles = (progress * totalTiles).round();

    final rng = math.Random(200);
    final tileOrder = List.generate(totalTiles, (i) => i);
    // Stable shuffle
    for (var i = totalTiles - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = tileOrder[i];
      tileOrder[i] = tileOrder[j];
      tileOrder[j] = temp;
    }

    for (var t = 0; t < visibleTiles && t < tileOrder.length; t++) {
      final idx = tileOrder[t];
      final col = idx % cols;
      final row = idx ~/ cols;

      final x = col * tileSize;
      final y = row * tileSize;
      final fadeIn = math.min(1.0, (progress * totalTiles - t) * 2);

      final tilePaint = Paint()
        ..color = tileColor.withValues(alpha: 0.4 * fadeIn)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(x + 1, y + 1, tileSize - 2, tileSize - 2);
      canvas.drawRect(rect, tilePaint);

      // Border
      final borderPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(rect.deflate(0.5), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MosaicPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Honeycomb pattern
class HoneycombPainter extends CustomPainter {
  final double progress;
  final Color honeyColor;

  HoneycombPainter({
    required this.progress,
    this.honeyColor = const Color(0xFFFFA500),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hexRadius = 15.0;
    final hexWidth = hexRadius * 2;
    final hexHeight = math.sqrt(3) * hexRadius;
    final cols = (size.width / (hexWidth * 0.75)).ceil() + 1;
    final rows = (size.height / hexHeight).ceil() + 1;
    final totalHexes = cols * rows;
    final visibleHexes = (progress * totalHexes).round();

    final rng = math.Random(300);
    final hexOrder = List.generate(totalHexes, (i) => i);
    for (var i = totalHexes - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = hexOrder[i];
      hexOrder[i] = hexOrder[j];
      hexOrder[j] = temp;
    }

    for (var h = 0; h < visibleHexes && h < hexOrder.length; h++) {
      final idx = hexOrder[h];
      final col = idx % cols;
      final row = idx ~/ cols;

      final cx = col * hexWidth * 0.75;
      final cy = row * hexHeight + (col % 2 == 1 ? hexHeight * 0.5 : 0);
      final fadeIn = math.min(1.0, (progress * totalHexes - h) * 2);

      final hexPaint = Paint()
        ..color = honeyColor.withValues(alpha: 0.3 * fadeIn)
        ..style = PaintingStyle.fill;

      final path = _createHexagon(cx, cy, hexRadius - 1);
      canvas.drawPath(path, hexPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.4 * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _createHexagon(double cx, double cy, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 6;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant HoneycombPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Prayer beads
class PrayerBeadsPainter extends CustomPainter {
  final double progress;
  final Color beadColor;
  final int beadCount;

  PrayerBeadsPainter({
    required this.progress,
    this.beadColor = const Color(0xFF8B4513),
    this.beadCount = 33,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleBeads = (progress * beadCount).round();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) * 0.7;

    for (var i = 0; i < visibleBeads; i++) {
      final angle = (i / beadCount) * math.pi * 2 - math.pi / 2;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      final fadeIn = math.min(1.0, (progress * beadCount - i) * 3);

      // Bead
      final beadPaint = Paint()
        ..color = beadColor.withValues(alpha: 0.8 * fadeIn)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5, beadPaint);

      // Highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 * fadeIn);
      canvas.drawCircle(Offset(x - 1.5, y - 1.5), 2, highlightPaint);
    }

    // Connecting string
    if (visibleBeads > 1) {
      final path = Path();
      for (var i = 0; i < visibleBeads; i++) {
        final angle = (i / beadCount) * math.pi * 2 - math.pi / 2;
        final x = cx + math.cos(angle) * radius;
        final y = cy + math.sin(angle) * radius;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final stringPaint = Paint()
        ..color = const Color(0xFF654321).withValues(alpha: 0.5 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, stringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PrayerBeadsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Compass with animated needle
class CompassPainter extends CustomPainter {
  final double progress;
  final Color needleColor;

  CompassPainter({
    required this.progress,
    this.needleColor = const Color(0xFFE53E3E),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) * 0.8;

    // Compass ring
    final ringPaint = Paint()
      ..color = const Color(0xFFC0C0C0).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    // Inner ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFF808080).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), radius * 0.85, innerRingPaint);

    // Cardinal directions
    final cardinalDirs = ['N', 'E', 'S', 'W'];
    final cardinalColors = [
      const Color(0xFFE53E3E),
      const Color(0xFFA0A0A0),
      const Color(0xFFA0A0A0),
      const Color(0xFFA0A0A0),
    ];
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final x = cx + math.cos(angle) * radius * 0.9;
      final y = cy + math.sin(angle) * radius * 0.9;
      final textPainter = TextPainter(
        text: TextSpan(
          text: cardinalDirs[i],
          style: TextStyle(
            color: cardinalColors[i].withValues(alpha: progress),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Needle
    final needleAngle = progress * math.pi * 4 - math.pi / 2;
    final needleLength = radius * 0.75;
    final needleTip = Offset(
      cx + math.cos(needleAngle) * needleLength,
      cy + math.sin(needleAngle) * needleLength,
    );
    final needleTailAngle = math.pi;
    final needleTailLength = radius * 0.25;
    final needleTail = Offset(
      cx + math.cos(needleAngle + needleTailAngle) * needleTailLength,
      cy + math.sin(needleAngle + needleTailAngle) * needleTailLength,
    );

    // North half (red)
    final northPaint = Paint()
      ..color = needleColor.withValues(alpha: 0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), needleTip, northPaint);

    // South half (dark)
    final southPaint = Paint()
      ..color = const Color(0xFF333333).withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), needleTail, southPaint);

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()..color = const Color(0xFFC0C0C0),
    );

    // Degree marks
    for (var d = 0; d < 360; d += 30) {
      final angle = d * math.pi / 180 - math.pi / 2;
      final innerR = radius * 0.92;
      final outerR = radius * 0.97;
      final x1 = cx + math.cos(angle) * innerR;
      final y1 = cy + math.sin(angle) * innerR;
      final x2 = cx + math.cos(angle) * outerR;
      final y2 = cy + math.sin(angle) * outerR;

      final tickPaint = Paint()
        ..color = const Color(0xFF808080).withValues(alpha: progress * 0.5)
        ..strokeWidth = d % 90 == 0 ? 2 : 1;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
