import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quran Animation Export Rendering
// ─────────────────────────────────────────────────────────────────────────────
// Standalone canvas painting functions for each animation type.
// Extracted from CustomPainters to work directly with Canvas during export.
// ─────────────────────────────────────────────────────────────────────────────

void paintDivineRevelation(Canvas canvas, Rect rect, double progress, {Color glowColor = const Color(0xFFFFD700)}) {
  final rng = math.Random(42);
  const particleCount = 40;
  for (var i = 0; i < particleCount; i++) {
    final px = rng.nextDouble() * rect.width;
    final py = rng.nextDouble() * rect.height;
    final pSize = rng.nextDouble() * 3.0 + 1;
    final revealThreshold = i / particleCount;
    if (progress >= revealThreshold) {
      final fadeIn = math.min(1.0, (progress - revealThreshold) * 5);
      final shimmer = 0.7 + 0.3 * math.sin(progress * math.pi * 2 + i);
      final opacity = fadeIn * shimmer;
      final paint = Paint()
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(rect.left + px, rect.top + py), pSize, paint);
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(rect.left + px, rect.top + py), pSize * 2.5, glowPaint);
    }
  }
}

void paintCelestialLight(Canvas canvas, Rect rect, double progress) {
  final sweepLength = progress * rect.height;
  final sweepRect = Rect.fromLTWH(rect.left, rect.top, rect.width, sweepLength);
  final gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: const [Color(0xFFFFFFCC), Color(0xFFFFF8DC), Color(0x00FFFFFF)],
  );
  final paint = Paint()..shader = gradient.createShader(sweepRect);
  canvas.drawRect(sweepRect, paint);
}

void paintGoldenParticles(Canvas canvas, Rect rect, double progress) {
  final rng = math.Random(42);
  const particleCount = 80;
  for (var i = 0; i < particleCount; i++) {
    final px = rng.nextDouble() * rect.width;
    final py = rng.nextDouble() * rect.height;
    final pSize = rng.nextDouble() * 4.0 + 1;
    final revealThreshold = i / particleCount;
    if (progress >= revealThreshold) {
      final fadeIn = math.min(1.0, (progress - revealThreshold) * 5);
      final shimmer = 0.7 + 0.3 * math.sin(progress * math.pi * 2 + i);
      final opacity = fadeIn * shimmer;
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(rect.left + px, rect.top + py), pSize, paint);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(rect.left + px, rect.top + py), pSize * 2.5, glowPaint);
    }
  }
}

void paintDivineRadiance(Canvas canvas, Rect rect, double progress) {
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final maxRadius = math.max(rect.width, rect.height) * progress * 0.5;
  final glowPaint = Paint()
    ..color = const Color(0xFFFFD700).withValues(alpha: 0.2 * progress)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  canvas.drawCircle(Offset(cx, cy), maxRadius, glowPaint);
  // Particles
  final rng = math.Random(42);
  const particleCount = 50;
  for (var i = 0; i < particleCount; i++) {
    final angle = rng.nextDouble() * math.pi * 2;
    final dist = rng.nextDouble() * maxRadius;
    final px = cx + math.cos(angle) * dist;
    final py = cy + math.sin(angle) * dist;
    final revealThreshold = i / particleCount;
    if (progress >= revealThreshold) {
      final fadeIn = math.min(1.0, (progress - revealThreshold) * 5);
      final pSize = rng.nextDouble() * 5.0 + 1;
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: fadeIn * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), pSize, paint);
    }
  }
}

void paintEtherealGlow(Canvas canvas, Rect rect, double progress) {
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final maxRadius = math.max(rect.width, rect.height) * 0.5;
  final glowPaint = Paint()
    ..color = const Color(0xFFE0B0FF).withValues(alpha: 0.3 * progress)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  canvas.drawCircle(Offset(cx, cy), maxRadius * progress, glowPaint);
}

void paintSacredRipple(Canvas canvas, Rect rect, double progress) {
  _paintWave(canvas, rect, progress, const Color(0xFF4FC3F7), 15.0, 3);
}

void paintMercyWave(Canvas canvas, Rect rect, double progress) {
  _paintWave(canvas, rect, progress, const Color(0xFF64B5F6), 15.0, 3);
}

void paintRiverFlow(Canvas canvas, Rect rect, double progress) {
  _paintWave(canvas, rect, progress, const Color(0xFF4DD0E1), 15.0, 3);
}

void _paintWave(Canvas canvas, Rect rect, double progress, Color waveColor, double amplitude, int waveCount) {
  const frequency = 0.02;
  for (var w = 0; w < waveCount; w++) {
    final path = Path();
    final waveOffset = w * 0.33;
    final waveProgress = math.max(0.0, math.min(1.0, (progress - waveOffset) * 2));
    if (waveProgress <= 0) continue;
    final visibleWidth = rect.width * waveProgress;
    final yBase = rect.height * (0.5 + w * 0.12);
    
    // Arabic is RTL: start from the right edge
    path.moveTo(rect.right, rect.top + yBase);
    for (var x = 0; x <= visibleWidth; x += 2) {
      final y = rect.top + yBase +
          math.sin(x * frequency + progress * math.pi * 2 + w) * amplitude * waveProgress;
      // Draw towards the left edge
      path.lineTo(rect.right - x, y);
    }
    final paint = Paint()
      ..color = waveColor.withValues(alpha: 0.3 * waveProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, paint);
  }
}

void paintBlessedRain(Canvas canvas, Rect rect, double progress) {
  _paintFallingDrops(canvas, rect, progress, const Color(0xFF4FC3F7), 30);
}

void paintWaterDrops(Canvas canvas, Rect rect, double progress) {
  _paintFallingDrops(canvas, rect, progress, const Color(0xFF4FC3F7), 30);
}

void _paintFallingDrops(Canvas canvas, Rect rect, double progress, Color dropColor, int objectCount) {
  final rng = math.Random(55);
  for (var i = 0; i < objectCount; i++) {
    final revealThreshold = i / objectCount;
    if (progress < revealThreshold) continue;
    final baseX = rect.left + rng.nextDouble() * rect.width;
    final fallProgress = (progress - revealThreshold) / (1 - revealThreshold);
    final y = rect.top - 20 + fallProgress * (rect.height + 40);
    if (y < rect.top - 20 || y > rect.bottom + 20) continue;
    final sway = math.sin(progress * math.pi * 4 + i * 0.7) * 15;
    final x = baseX + sway;
    final fadeIn = math.min(1.0, fallProgress * 3);
    final fadeOut = math.max(0.0, 1 - fallProgress * 0.5);
    final alpha = fadeIn * fadeOut * 0.6;
    final paint = Paint()..color = dropColor.withValues(alpha: alpha);
    // Teardrop
    canvas.save();
    canvas.translate(x, y);
    final path = Path()
      ..moveTo(0, -5)
      ..quadraticBezierTo(3, 0, 3, 2)
      ..arcTo(Rect.fromLTWH(-3, 0, 6, 4), 0, math.pi, false)
      ..quadraticBezierTo(3, 0, 0, -5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

void paintAutumnLeaves(Canvas canvas, Rect rect, double progress) {
  _paintFallingObjects(canvas, rect, progress, 'leaf', const Color(0xFFFF8C00), 25);
}

void paintFlowerBloom(Canvas canvas, Rect rect, double progress) {
  _paintFallingObjects(canvas, rect, progress, 'petal', const Color(0xFFFF69B4), 20);
}

void paintGentleWind(Canvas canvas, Rect rect, double progress) {
  _paintFallingObjects(canvas, rect, progress, 'leaf', const Color(0xFF90EE90), 15);
}

void paintLightButterflies(Canvas canvas, Rect rect, double progress) {
  _paintFallingObjects(canvas, rect, progress, 'butterfly', const Color(0xFFDDA0DD), 15);
}

void _paintFallingObjects(Canvas canvas, Rect rect, double progress, String objectType, Color objectColor, int objectCount) {
  final rng = math.Random(55);
  for (var i = 0; i < objectCount; i++) {
    final revealThreshold = i / objectCount;
    if (progress < revealThreshold) continue;
    final baseX = rect.left + rng.nextDouble() * rect.width;
    final fallProgress = (progress - revealThreshold) / (1 - revealThreshold);
    final y = rect.top - 20 + fallProgress * (rect.height + 40);
    if (y < rect.top - 20 || y > rect.bottom + 20) continue;
    final sway = math.sin(progress * math.pi * 4 + i * 0.7) * 15;
    final x = baseX + sway;
    final fadeIn = math.min(1.0, fallProgress * 3);
    final fadeOut = math.max(0.0, 1 - fallProgress * 0.5);
    final alpha = fadeIn * fadeOut;
    switch (objectType) {
      case 'butterfly':
        _drawButterfly(canvas, Offset(x, y), alpha, objectColor);
        break;
      case 'leaf':
        _drawLeaf(canvas, Offset(x, y), alpha, objectColor);
        break;
      case 'petal':
        _drawPetal(canvas, Offset(x, y), alpha, objectColor);
        break;
    }
  }
}

void _drawButterfly(Canvas canvas, Offset pos, double alpha, Color color) {
  final paint = Paint()..color = color.withValues(alpha: alpha * 0.8);
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  canvas.drawOval(Rect.fromLTWH(-6, -4, 5, 8), paint);
  canvas.drawOval(Rect.fromLTWH(1, -4, 5, 8), paint);
  canvas.drawOval(Rect.fromLTWH(-0.5, -3, 1, 6), Paint()..color = const Color(0xFF333333).withValues(alpha: alpha));
  canvas.restore();
}

void _drawLeaf(Canvas canvas, Offset pos, double alpha, Color color) {
  final paint = Paint()..color = color.withValues(alpha: alpha * 0.7);
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

void _drawPetal(Canvas canvas, Offset pos, double alpha, Color color) {
  final paint = Paint()..color = color.withValues(alpha: alpha * 0.8);
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  final path = Path()
    ..moveTo(0, -5)
    ..quadraticBezierTo(5, 0, 0, 5)
    ..quadraticBezierTo(-5, 0, 0, -5);
  canvas.drawPath(path, paint);
  canvas.restore();
}

void paintRainbow(Canvas canvas, Rect rect, double progress) {
  final gradient = LinearGradient(
    begin: Alignment.centerRight, // RTL: Start gradient from Right
    end: Alignment.centerLeft,
    colors: const [
      Color(0xFFFF0000), Color(0xFFFF7F00), Color(0xFFFFFF00),
      Color(0xFF00FF00), Color(0xFF0000FF), Color(0xFF4B0082), Color(0xFF9400D3),
    ],
  );
  // RTL: The sweep reveals right-to-left
  final sweepLength = progress * rect.width;
  final sweepRect = Rect.fromLTRB(rect.right - sweepLength, rect.top, rect.right, rect.bottom);
  final paint = Paint()..shader = gradient.createShader(sweepRect);
  canvas.save();
  canvas.clipRect(sweepRect);
  canvas.drawRect(rect, paint);
  canvas.restore();
}

void paintLivingCalligraphy(Canvas canvas, Rect rect, double progress, Color inkColor) {
  _paintCalligraphyStroke(canvas, rect, progress, inkColor, 2.5);
}

void paintInkFlow(Canvas canvas, Rect rect, double progress) {
  _paintCalligraphyStroke(canvas, rect, progress, const Color(0xFF1A1A2E), 3.0);
}

void paintBrushStrokes(Canvas canvas, Rect rect, double progress) {
  _paintCalligraphyStroke(canvas, rect, progress, const Color(0xFF8B0000), 4.0);
}

void paintQuillWriting(Canvas canvas, Rect rect, double progress) {
  _paintCalligraphyStroke(canvas, rect, progress, const Color(0xFF2F4F4F), 2.0);
}

void _paintCalligraphyStroke(Canvas canvas, Rect rect, double progress, Color inkColor, double strokeThickness) {
  final path = Path();
  final drawLength = rect.width * progress;
  // Arabic is RTL: Start from the right edge
  path.moveTo(rect.right, rect.top + rect.height * 0.5);
  var x = 0.0;
  while (x <= drawLength) {
    final t = x / rect.width;
    final y = rect.top + rect.height * 0.5 +
        math.sin(t * math.pi * 4) * 15 * progress +
        math.sin(t * math.pi * 8) * 5 * progress;
    // Draw towards the left edge
    path.lineTo(rect.right - x, y);
    x += 2;
  }
  final paint = Paint()
    ..color = inkColor.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeThickness
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(path, paint);
  
  // Ink drip at leading edge (moving leftward)
  if (progress > 0.05 && progress < 0.95) {
    // Current tip is at the left-most extreme of the current drawLength
    final tipX = rect.right - drawLength;
    final tipY = rect.top + rect.height * 0.5 +
        math.sin(progress * math.pi * 4) * 15 * progress +
        math.sin(progress * math.pi * 8) * 5 * progress;
    for (var i = 0; i < 5; i++) {
      final dropPaint = Paint()
        ..color = inkColor.withValues(alpha: 0.3 - i * 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      // Trailing drips appear slightly to the right of the tip (since movement is leftward) + i*3
      canvas.drawCircle(Offset(tipX + i * 3, tipY + i * 4), 1.5 - i * 0.2, dropPaint);
    }
  }
}

void paintMosaicAssembly(Canvas canvas, Rect rect, double progress) {
  _paintMosaic(canvas, rect, progress, const Color(0xFF4A90D9), 18);
}

void paintZellige(Canvas canvas, Rect rect, double progress) {
  _paintMosaic(canvas, rect, progress, const Color(0xFF00695C), 14);
}

void paintPersianCarpet(Canvas canvas, Rect rect, double progress) {
  _paintMosaic(canvas, rect, progress, const Color(0xFF8B0000), 14);
}

void _paintMosaic(Canvas canvas, Rect rect, double progress, Color tileColor, double tileSize) {
  final cols = (rect.width / tileSize).ceil();
  final rows = (rect.height / tileSize).ceil();
  final totalTiles = cols * rows;
  final visibleTiles = (progress * totalTiles).round();
  final rng = math.Random(200);
  final tileOrder = List.generate(totalTiles, (i) => i);
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
    final x = rect.left + col * tileSize;
    final y = rect.top + row * tileSize;
    final fadeIn = math.min(1.0, (progress * totalTiles - t) * 2);
    final tilePaint = Paint()..color = tileColor.withValues(alpha: 0.4 * fadeIn);
    final tileRect = Rect.fromLTWH(x + 1, y + 1, tileSize - 2, tileSize - 2);
    canvas.drawRect(tileRect, tilePaint);
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 * fadeIn)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(tileRect.deflate(0.5), borderPaint);
  }
}

void paintGoldenSpiral(Canvas canvas, Rect rect, double progress) {
  _paintSpiral(canvas, rect, progress, const Color(0xFFFFD700), false);
}

void paintFractalGrowth(Canvas canvas, Rect rect, double progress) {
  _paintSpiral(canvas, rect, progress, const Color(0xFF4CAF50), false);
}

void paintGalaxy(Canvas canvas, Rect rect, double progress) {
  _paintSpiral(canvas, rect, progress, const Color(0xFFDDA0DD), true);
}

void _paintSpiral(Canvas canvas, Rect rect, double progress, Color spiralColor, bool isGalaxy) {
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final maxRadius = math.min(rect.width, rect.height) * 0.4;
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
    ..maskFilter = isGalaxy ? const MaskFilter.blur(BlurStyle.normal, 5) : null;
  canvas.drawPath(path, paint);
  if (isGalaxy) {
    final glowPaint = Paint()
      ..color = spiralColor.withValues(alpha: 0.2 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(cx, cy), maxRadius * progress, glowPaint);
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

void paintHoneycomb(Canvas canvas, Rect rect, double progress) {
  const hexRadius = 15.0;
  final hexWidth = hexRadius * 2;
  final hexHeight = math.sqrt(3) * hexRadius;
  final cols = (rect.width / (hexWidth * 0.75)).ceil() + 1;
  final rows = (rect.height / hexHeight).ceil() + 1;
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
    final cx = rect.left + col * hexWidth * 0.75;
    final cy = rect.top + row * hexHeight + (col % 2 == 1 ? hexHeight * 0.5 : 0);
    final fadeIn = math.min(1.0, (progress * totalHexes - h) * 2);
    final hexPath = _createHexagon(cx, cy, hexRadius - 1);
    final hexPaint = Paint()..color = const Color(0xFFFFA500).withValues(alpha: 0.3 * fadeIn);
    canvas.drawPath(hexPath, hexPaint);
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.4 * fadeIn)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
  canvas.drawPath(hexPath, borderPaint);
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

void paintCrescentMoon(Canvas canvas, Rect rect, double progress) {
  final cx = rect.center.dx;
  final cy = rect.center.dy - 20 * (1 - progress);
  final s = 35.0 * progress;
  if (s <= 0) return;
  // Glow
  final glowPaint = Paint()
    ..color = const Color(0xFFFFF8DC).withValues(alpha: 0.15 * progress)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  canvas.drawCircle(Offset(cx, cy), s * 1.5, glowPaint);
  // Crescent
  canvas.saveLayer(
    Rect.fromLTWH(cx - s * 2, cy - s * 2, s * 4, s * 4),
    Paint(),
  );
  final moonPaint = Paint()..color = const Color(0xFFFFF8DC).withValues(alpha: 0.9 * progress);
  canvas.drawCircle(Offset(cx, cy), s, moonPaint);
  final cutoutPaint = Paint()
    ..color = const Color(0xFF000000)
    ..blendMode = BlendMode.dstOut;
  canvas.drawCircle(Offset(cx + s * 0.4, cy - s * 0.1), s * 0.85, cutoutPaint);
  canvas.restore();
  // Stars
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

void paintPrayerBeads(Canvas canvas, Rect rect, double progress) {
  const beadCount = 33;
  final visibleBeads = (progress * beadCount).round();
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final radius = math.min(math.min(cx - rect.left, rect.right - cx), math.min(cy - rect.top, rect.bottom - cy)) * 0.7;
  final actualRadius = math.max(20.0, radius);
  for (var i = 0; i < visibleBeads; i++) {
    final angle = (i / beadCount) * math.pi * 2 - math.pi / 2;
    final x = cx + math.cos(angle) * actualRadius;
    final y = cy + math.sin(angle) * actualRadius;
    final fadeIn = math.min(1.0, (progress * beadCount - i) * 3);
    final beadPaint = Paint()
      ..color = const Color(0xFF8B4513).withValues(alpha: 0.8 * fadeIn);
    canvas.drawCircle(Offset(x, y), 5, beadPaint);
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.3 * fadeIn);
    canvas.drawCircle(Offset(x - 1.5, y - 1.5), 2, highlightPaint);
  }
  // String
  if (visibleBeads > 1) {
    final path = Path();
    for (var i = 0; i < visibleBeads; i++) {
      final angle = (i / beadCount) * math.pi * 2 - math.pi / 2;
      final x = cx + math.cos(angle) * actualRadius;
      final y = cy + math.sin(angle) * actualRadius;
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

void paintIncenseSmoke(Canvas canvas, Rect rect, double progress) {
  const smokeColor = Color(0xFFB0B0B0);
  final smokeStreams = 3;
  for (var s = 0; s < smokeStreams; s++) {
    final baseX = rect.left + rect.width * (0.3 + s * 0.2);
    final path = Path();
    path.moveTo(baseX, rect.bottom);
    final streamProgress = math.max(0.0, math.min(1.0, (progress - s * 0.1) * 1.3));
    final maxHeight = rect.height * streamProgress;
    for (var y = 0; y <= maxHeight; y += 4) {
      final t = y / rect.height;
      final x = baseX +
          math.sin(t * math.pi * 3 + s * 2 + progress * math.pi) * (20 + t * 30) +
          math.sin(t * math.pi * 5) * 10;
      path.lineTo(x, rect.bottom - y);
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

void paintSacredFire(Canvas canvas, Rect rect, double progress) {
  final rng = math.Random(88);
  final flameCount = (progress * 40).round();
  for (var i = 0; i < flameCount; i++) {
    final baseX = rect.left + rect.width * (0.2 + rng.nextDouble() * 0.6);
    final flameProgress = math.max(0.0, math.min(1.0, (progress - i / 40) * 2));
    if (flameProgress <= 0) continue;
    final maxHeight = rect.height * 0.6 * flameProgress;
    final path = Path();
    path.moveTo(baseX, rect.bottom);
    for (var y = 0; y <= maxHeight; y += 3) {
      final t = y / maxHeight;
      const flicker = 8.0;
      final x = baseX +
          math.sin(y * 0.15 + progress * 10 + i) * flicker * (1 - t) +
          math.sin(y * 0.05 - progress * 5) * flicker * 0.5;
      path.lineTo(x, rect.bottom - y);
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
  canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - 20, rect.width, 20), glowPaint);
}

void paintNightOfPower(Canvas canvas, Rect rect, double progress) {
  // Dark overlay that fades out
  canvas.drawRect(rect, Paint()..color = const Color(0xFF0A0A2E).withValues(alpha: 1 - progress));
  // Radial glow
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final maxRadius = math.max(rect.width, rect.height) * 0.5 * progress;
  final glowPaint = Paint()
    ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 * progress)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  canvas.drawCircle(Offset(cx, cy), maxRadius, glowPaint);
}

void paintConstellation(Canvas canvas, Rect rect, double progress) {
  final rng = math.Random(99);
  const starCount = 15;
  final stars = <Offset>[];
  for (var i = 0; i < starCount; i++) {
    stars.add(Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    ));
  }
  // Lines
  for (var i = 0; i < stars.length - 1; i++) {
    final revealProgress = math.max(0.0, math.min(1.0, (progress - i / starCount) * starCount));
    if (revealProgress > 0) {
      final linePaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.2 * revealProgress)
        ..strokeWidth = 1.0;
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }
  }
  // Stars
  for (var i = 0; i < stars.length; i++) {
    final revealThreshold = i / starCount;
    if (progress >= revealThreshold) {
      final fadeIn = math.min(1.0, (progress - revealThreshold) * 4);
      final twinkle = 0.7 + 0.3 * math.sin(progress * math.pi * 4 + i);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: fadeIn * twinkle * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(stars[i], 12, glowPaint);
      final starPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: fadeIn * twinkle);
      canvas.drawCircle(stars[i], 3, starPaint);
    }
  }
}

void paintStardust(Canvas canvas, Rect rect, double progress) {
  final rng = math.Random(42);
  const particleCount = 70;
  for (var i = 0; i < particleCount; i++) {
    final px = rect.left + rng.nextDouble() * rect.width;
    final py = rect.top + rng.nextDouble() * rect.height;
    final pSize = rng.nextDouble() * 2.5 + 1;
    final revealThreshold = i / particleCount;
    if (progress >= revealThreshold) {
      final fadeIn = math.min(1.0, (progress - revealThreshold) * 5);
      final shimmer = 0.7 + 0.3 * math.sin(progress * math.pi * 2 + i);
      final paint = Paint()
        ..color = const Color(0xFFE0B0FF).withValues(alpha: fadeIn * shimmer * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), pSize, paint);
      final glowPaint = Paint()
        ..color = const Color(0xFFE0B0FF).withValues(alpha: fadeIn * shimmer * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(px, py), pSize * 2.5, glowPaint);
    }
  }
}

void paintAurora(Canvas canvas, Rect rect, double progress) {
  final gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: const [Color(0xFF00FF88), Color(0xFF00DDFF), Color(0xFF8800FF), Color(0xFFFF00AA)],
  );
  final sweepLength = progress * rect.height;
  final sweepRect = Rect.fromLTWH(rect.left, rect.top, rect.width, sweepLength);
  final paint = Paint()..shader = gradient.createShader(sweepRect);
  canvas.save();
  canvas.clipRect(sweepRect);
  canvas.drawRect(rect, paint);
  canvas.restore();
}

void paintDiamondSparkle(Canvas canvas, Rect rect, double progress) {
  final rng = math.Random(42);
  const particleCount = 30;
  for (var i = 0; i < particleCount; i++) {
    final px = rect.left + rng.nextDouble() * rect.width;
    final py = rect.top + rng.nextDouble() * rect.height;
    final pSize = rng.nextDouble() * 3.0 + 1;
    final revealThreshold = i / particleCount;
    if (progress >= revealThreshold) {
      final fadeIn = math.min(1.0, (progress - revealThreshold) * 5);
      final shimmer = 0.7 + 0.3 * math.sin(progress * math.pi * 2 + i);
      final paint = Paint()
        ..color = const Color(0xFFB9F2FF).withValues(alpha: fadeIn * shimmer * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), pSize, paint);
      final glowPaint = Paint()
        ..color = const Color(0xFFB9F2FF).withValues(alpha: fadeIn * shimmer * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(px, py), pSize * 2.5, glowPaint);
    }
  }
}

void paintSunset(Canvas canvas, Rect rect, double progress) {
  final gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: const [
      Color(0xFFFF4500), Color(0xFFFF8C00), Color(0xFFFFD700),
      Color(0xFFFF6347), Color(0xFF8B008B),
    ],
  );
  final sweepLength = progress * rect.height;
  final sweepRect = Rect.fromLTWH(rect.left, rect.top, rect.width, sweepLength);
  final paint = Paint()..shader = gradient.createShader(sweepRect);
  canvas.save();
  canvas.clipRect(sweepRect);
  canvas.drawRect(rect, paint);
  canvas.restore();
}

void paintLightning(Canvas canvas, Rect rect, double progress) {
  final rng = math.Random(123);
  final flashPhase = (progress * 4).floor();
  final flashIntensity = flashPhase % 2 == 0
      ? math.sin(progress * math.pi * 4) * 0.5 + 0.5
      : 0.0;
  if (flashIntensity <= 0.05) return;
  final boltCount = 2 + rng.nextInt(3);
  for (var b = 0; b < boltCount; b++) {
    final startX = rect.left + rng.nextDouble() * rect.width;
    final path = Path();
    path.moveTo(startX, rect.top);
    var x = startX;
    var y = 0.0;
    final segmentLength = 15 + rng.nextDouble() * 20;
    while (y < rect.height) {
      x += (rng.nextDouble() - 0.5) * 40;
      y += segmentLength;
      path.lineTo(x, rect.top + y);
      // Branch
      if (rng.nextDouble() > 0.6) {
        final branchPath = Path();
        branchPath.moveTo(x, rect.top + y);
        var bx = x;
        var by = y;
        for (var i = 0; i < 3; i++) {
          bx += (rng.nextDouble() - 0.5) * 30;
          by += segmentLength * 0.6;
          branchPath.lineTo(bx, rect.top + by);
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
  canvas.drawRect(rect, Paint()..color = Colors.white.withValues(alpha: flashIntensity * 0.1));
}

void paintEarthShake(Canvas canvas, Rect rect, double progress) {
  // This animation is mainly a text transform (shake + scale)
  // For export, we just add a subtle visual overlay
  if (progress < 0.3) {
    final shakeIntensity = 10 * (1 - progress / 0.3);
    final rng = math.Random(progress.hashCode);
    final shakeX = (rng.nextDouble() - 0.5) * shakeIntensity;
    final shakeY = shakeX * 0.5;
    canvas.translate(shakeX, shakeY);
  }
}

void paintCompass(Canvas canvas, Rect rect, double progress) {
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final radius = math.min(math.min(cx - rect.left, rect.right - cx), math.min(cy - rect.top, rect.bottom - cy)) * 0.8;
  final actualRadius = math.max(30.0, radius);
  // Ring
  final ringPaint = Paint()
    ..color = const Color(0xFFC0C0C0).withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawCircle(Offset(cx, cy), actualRadius, ringPaint);
  // Inner ring
  final innerRingPaint = Paint()
    ..color = const Color(0xFF808080).withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  canvas.drawCircle(Offset(cx, cy), actualRadius * 0.85, innerRingPaint);
  // Cardinal directions
  final cardinalDirs = ['N', 'E', 'S', 'W'];
  final cardinalColors = [const Color(0xFFE53E3E), const Color(0xFFA0A0A0), const Color(0xFFA0A0A0), const Color(0xFFA0A0A0)];
  for (var i = 0; i < 4; i++) {
    final angle = i * math.pi / 2 - math.pi / 2;
    final x = cx + math.cos(angle) * actualRadius * 0.9;
    final y = cy + math.sin(angle) * actualRadius * 0.9;
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
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }
  // Needle
  final needleAngle = progress * math.pi * 4 - math.pi / 2;
  final needleLength = actualRadius * 0.75;
  final needleTip = Offset(cx + math.cos(needleAngle) * needleLength, cy + math.sin(needleAngle) * needleLength);
  final needleTail = Offset(
    cx + math.cos(needleAngle + math.pi) * actualRadius * 0.25,
    cy + math.sin(needleAngle + math.pi) * actualRadius * 0.25,
  );
  final northPaint = Paint()
    ..color = const Color(0xFFE53E3E).withValues(alpha: 0.9)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(cx, cy), needleTip, northPaint);
  final southPaint = Paint()
    ..color = const Color(0xFF333333).withValues(alpha: 0.6)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(cx, cy), needleTail, southPaint);
  // Center dot
  canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = const Color(0xFFC0C0C0));
  // Degree marks
  for (var d = 0; d < 360; d += 30) {
    final angle = d * math.pi / 180 - math.pi / 2;
    final innerR = actualRadius * 0.92;
    final outerR = actualRadius * 0.97;
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

void paintFlyingCarpet(Canvas canvas, Rect rect, double progress) {
  // This animation is mainly a horizontal scroll reveal
  // No extra overlay needed
}

void paintMinaretRise(Canvas canvas, Rect rect, double progress) {
  // This animation is mainly a slide-up transform
  // Add a subtle silhouette overlay
  if (progress < 0.8) {
    final minaretColor = const Color(0xFF2C3E50).withValues(alpha: 0.1 * (1 - progress));
    final paint = Paint()..color = minaretColor;
    // Simple minaret shape
    final mw = 12.0 * progress;
    final mh = rect.height * 0.7 * progress;
    final mx = rect.left + rect.width * 0.5 - mw / 2;
    final my = rect.bottom - mh;
    canvas.drawRect(Rect.fromLTWH(mx, my, mw, mh), paint);
    // Top dome
    canvas.drawOval(Rect.fromLTWH(mx - 3, my - 6, mw + 6, 12), paint);
  }
}

/// Dispatch function: given an animation ID, progress, and rect,
/// calls the appropriate painting function.
void paintQuranAnimation(Canvas canvas, Rect rect, String animationId, double progress, {Color? textColor}) {
  final inkColor = textColor ?? const Color(0xFFFFFFFF);
  switch (animationId) {
    // REVELATION
    case 'divine_revelation':
      paintDivineRevelation(canvas, rect, progress);
      break;
    case 'celestial_light':
      paintCelestialLight(canvas, rect, progress);
      break;
    case 'golden_particles':
      paintGoldenParticles(canvas, rect, progress);
      break;
    case 'divine_radiance':
      paintDivineRadiance(canvas, rect, progress);
      break;
    case 'ethereal_glow':
      paintEtherealGlow(canvas, rect, progress);
      break;

    // NATURE
    case 'sacred_ripple':
      paintSacredRipple(canvas, rect, progress);
      break;
    case 'mercy_wave':
      paintMercyWave(canvas, rect, progress);
      break;
    case 'blessed_rain':
      paintBlessedRain(canvas, rect, progress);
      break;
    case 'autumn_leaves':
      paintAutumnLeaves(canvas, rect, progress);
      break;
    case 'flower_bloom':
      paintFlowerBloom(canvas, rect, progress);
      break;
    case 'gentle_wind':
      paintGentleWind(canvas, rect, progress);
      break;
    case 'water_drops':
      paintWaterDrops(canvas, rect, progress);
      break;
    case 'rainbow':
      paintRainbow(canvas, rect, progress);
      break;
    case 'river_flow':
      paintRiverFlow(canvas, rect, progress);
      break;

    // CALLIGRAPHY
    case 'living_calligraphy':
      paintLivingCalligraphy(canvas, rect, progress, inkColor);
      break;
    case 'ink_flow':
      paintInkFlow(canvas, rect, progress);
      break;
    case 'brush_strokes':
      paintBrushStrokes(canvas, rect, progress);
      break;
    case 'quill_writing':
      paintQuillWriting(canvas, rect, progress);
      break;

    // GEOMETRY
    case 'mosaic_assembly':
      paintMosaicAssembly(canvas, rect, progress);
      break;
    case 'golden_spiral':
      paintGoldenSpiral(canvas, rect, progress);
      break;
    case 'zellige':
      paintZellige(canvas, rect, progress);
      break;
    case 'persian_carpet':
      paintPersianCarpet(canvas, rect, progress);
      break;
    case 'fractal_growth':
      paintFractalGrowth(canvas, rect, progress);
      break;
    case 'honeycomb':
      paintHoneycomb(canvas, rect, progress);
      break;

    // SPIRITUAL
    case 'crescent_moon':
      paintCrescentMoon(canvas, rect, progress);
      break;
    case 'minaret_rise':
      paintMinaretRise(canvas, rect, progress);
      break;
    case 'prayer_beads':
      paintPrayerBeads(canvas, rect, progress);
      break;
    case 'incense_smoke':
      paintIncenseSmoke(canvas, rect, progress);
      break;
    case 'sacred_fire':
      paintSacredFire(canvas, rect, progress);
      break;
    case 'night_of_power':
      paintNightOfPower(canvas, rect, progress);
      break;
    case 'flying_carpet':
      paintFlyingCarpet(canvas, rect, progress);
      break;

    // COSMIC
    case 'constellation':
      paintConstellation(canvas, rect, progress);
      break;
    case 'stardust':
      paintStardust(canvas, rect, progress);
      break;
    case 'aurora':
      paintAurora(canvas, rect, progress);
      break;
    case 'galaxy':
      paintGalaxy(canvas, rect, progress);
      break;
    case 'diamond_sparkle':
      paintDiamondSparkle(canvas, rect, progress);
      break;
    case 'light_butterflies':
      paintLightButterflies(canvas, rect, progress);
      break;
    case 'sunset':
      paintSunset(canvas, rect, progress);
      break;
    case 'lightning':
      paintLightning(canvas, rect, progress);
      break;
    case 'earth_shake':
      paintEarthShake(canvas, rect, progress);
      break;
    case 'compass':
      paintCompass(canvas, rect, progress);
      break;
  }
}
