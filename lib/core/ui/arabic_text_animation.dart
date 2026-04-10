import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════
/// 41 Premium Quran Text Animations
/// ═══════════════════════════════════════════
///
/// Each animation is visually unique with full RTL support
/// and word-by-word recitation sync.

enum ArabicTextAnimation {
  // ── REVELATION (5) ──
  divineRevelation,
  celestialLight,
  goldenParticles,
  divineRadiance,
  etherealGlow,
  // ── NATURE (9) ──
  sacredRipple,
  mercyWave,
  blessedRain,
  autumnLeaves,
  flowerBloom,
  gentleWind,
  waterDrops,
  rainbow,
  riverFlow,
  // ── CALLIGRAPHY (4) ──
  livingCalligraphy,
  inkFlow,
  brushStrokes,
  quillWriting,
  // ── GEOMETRY (6) ──
  mosaicAssembly,
  goldenSpiral,
  zellige,
  persianCarpet,
  fractalGrowth,
  honeycomb,
  // ── SPIRITUAL (7) ──
  crescentMoon,
  minaretRise,
  prayerBeads,
  incenseSmoke,
  sacredFire,
  nightOfPower,
  flyingCarpet,
  // ── COSMIC (10) ──
  constellation,
  stardust,
  aurora,
  galaxy,
  diamondSparkle,
  lightButterflies,
  sunset,
  lightning,
  earthShake,
  compass,
}

/// Map animation ID string to enum
ArabicTextAnimation arabicAnimationFromId(String id) {
  switch (id) {
    case 'divine_revelation': return ArabicTextAnimation.divineRevelation;
    case 'celestial_light': return ArabicTextAnimation.celestialLight;
    case 'golden_particles': return ArabicTextAnimation.goldenParticles;
    case 'divine_radiance': return ArabicTextAnimation.divineRadiance;
    case 'ethereal_glow': return ArabicTextAnimation.etherealGlow;
    case 'sacred_ripple': return ArabicTextAnimation.sacredRipple;
    case 'mercy_wave': return ArabicTextAnimation.mercyWave;
    case 'blessed_rain': return ArabicTextAnimation.blessedRain;
    case 'autumn_leaves': return ArabicTextAnimation.autumnLeaves;
    case 'flower_bloom': return ArabicTextAnimation.flowerBloom;
    case 'gentle_wind': return ArabicTextAnimation.gentleWind;
    case 'water_drops': return ArabicTextAnimation.waterDrops;
    case 'rainbow': return ArabicTextAnimation.rainbow;
    case 'river_flow': return ArabicTextAnimation.riverFlow;
    case 'living_calligraphy': return ArabicTextAnimation.livingCalligraphy;
    case 'ink_flow': return ArabicTextAnimation.inkFlow;
    case 'brush_strokes': return ArabicTextAnimation.brushStrokes;
    case 'quill_writing': return ArabicTextAnimation.quillWriting;
    case 'mosaic_assembly': return ArabicTextAnimation.mosaicAssembly;
    case 'golden_spiral': return ArabicTextAnimation.goldenSpiral;
    case 'zellige': return ArabicTextAnimation.zellige;
    case 'persian_carpet': return ArabicTextAnimation.persianCarpet;
    case 'fractal_growth': return ArabicTextAnimation.fractalGrowth;
    case 'honeycomb': return ArabicTextAnimation.honeycomb;
    case 'crescent_moon': return ArabicTextAnimation.crescentMoon;
    case 'minaret_rise': return ArabicTextAnimation.minaretRise;
    case 'prayer_beads': return ArabicTextAnimation.prayerBeads;
    case 'incense_smoke': return ArabicTextAnimation.incenseSmoke;
    case 'sacred_fire': return ArabicTextAnimation.sacredFire;
    case 'night_of_power': return ArabicTextAnimation.nightOfPower;
    case 'flying_carpet': return ArabicTextAnimation.flyingCarpet;
    case 'constellation': return ArabicTextAnimation.constellation;
    case 'stardust': return ArabicTextAnimation.stardust;
    case 'aurora': return ArabicTextAnimation.aurora;
    case 'galaxy': return ArabicTextAnimation.galaxy;
    case 'diamond_sparkle': return ArabicTextAnimation.diamondSparkle;
    case 'light_butterflies': return ArabicTextAnimation.lightButterflies;
    case 'sunset': return ArabicTextAnimation.sunset;
    case 'lightning': return ArabicTextAnimation.lightning;
    case 'earth_shake': return ArabicTextAnimation.earthShake;
    case 'compass': return ArabicTextAnimation.compass;
    default: return ArabicTextAnimation.divineRevelation;
  }
}

/// Configuration for Arabic text animation
class ArabicTextAnimationConfig {
  final ArabicTextAnimation animation;
  final String text;
  final TextStyle baseStyle;
  final Color highlightColor;
  final double progress;
  final double elapsed;
  final bool isRTL;
  final double? maxWidth;
  final List<Map<String, dynamic>> wordTimings;
  final double currentTime;
  final double layerStartTime;

  const ArabicTextAnimationConfig({
    required this.animation,
    required this.text,
    required this.baseStyle,
    this.highlightColor = const Color(0xFFFFD700),
    this.progress = 1.0,
    this.elapsed = 0,
    this.isRTL = true,
    this.maxWidth,
    this.wordTimings = const [],
    this.currentTime = 0,
    this.layerStartTime = 0,
  });
}

/// Word layout model
class _WordLayout {
  final String word;
  final double x, y, width, height;
  const _WordLayout({required this.word, required this.x, required this.y, required this.width, required this.height});
}

/// ═══════════════════════════════════════════
/// Main Painter
/// ═══════════════════════════════════════════

class ArabicTextPainter extends CustomPainter {
  final ArabicTextAnimationConfig config;
  const ArabicTextPainter({required this.config});


  @override
  void paint(Canvas canvas, Size size) {
    final words = _layoutWords(size);
    if (words.isEmpty) return;

    final totalWords = words.length;
    final currentWordFloat = config.progress * totalWords;
    final currentWordIndex = _getCurrentWordIndex(totalWords);

    switch (config.animation) {
      // ═══ REVELATION ═══
      case ArabicTextAnimation.divineRevelation:
        _paintDivineRevelation(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.celestialLight:
        _paintCelestialLight(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.goldenParticles:
        _paintGoldenParticles(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.divineRadiance:
        _paintDivineRadiance(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.etherealGlow:
        _paintEtherealGlow(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      // ═══ NATURE ═══
      case ArabicTextAnimation.sacredRipple:
        _paintSacredRipple(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.mercyWave:
        _paintMercyWave(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.blessedRain:
        _paintBlessedRain(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.autumnLeaves:
        _paintAutumnLeaves(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.flowerBloom:
        _paintFlowerBloom(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      case ArabicTextAnimation.gentleWind:
        _paintGentleWind(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.waterDrops:
        _paintWaterDrops(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.rainbow:
        _paintRainbow(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.riverFlow:
        _paintRiverFlow(canvas, size, words, currentWordFloat);
        break;
      // ═══ CALLIGRAPHY ═══
      case ArabicTextAnimation.livingCalligraphy:
        _paintLivingCalligraphy(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.inkFlow:
        _paintInkFlow(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.brushStrokes:
        _paintBrushStrokes(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.quillWriting:
        _paintQuillWriting(canvas, size, words, currentWordFloat);
        break;
      // ═══ GEOMETRY ═══
      case ArabicTextAnimation.mosaicAssembly:
        _paintMosaicAssembly(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      case ArabicTextAnimation.goldenSpiral:
        _paintGoldenSpiral(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.zellige:
        _paintZellige(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.persianCarpet:
        _paintPersianCarpet(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.fractalGrowth:
        _paintFractalGrowth(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      case ArabicTextAnimation.honeycomb:
        _paintHoneycomb(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      // ═══ SPIRITUAL ═══
      case ArabicTextAnimation.crescentMoon:
        _paintCrescentMoon(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.minaretRise:
        _paintMinaretRise(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.prayerBeads:
        _paintPrayerBeads(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      case ArabicTextAnimation.incenseSmoke:
        _paintIncenseSmoke(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.sacredFire:
        _paintSacredFire(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.nightOfPower:
        _paintNightOfPower(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.flyingCarpet:
        _paintFlyingCarpet(canvas, size, words, currentWordFloat);
        break;
      // ═══ COSMIC ═══
      case ArabicTextAnimation.constellation:
        _paintConstellation(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      case ArabicTextAnimation.stardust:
        _paintStardust(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.aurora:
        _paintAurora(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.galaxy:
        _paintGalaxy(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.diamondSparkle:
        _paintDiamondSparkle(canvas, size, words, currentWordFloat, currentWordIndex);
        break;
      case ArabicTextAnimation.lightButterflies:
        _paintLightButterflies(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.sunset:
        _paintSunset(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.lightning:
        _paintLightning(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.earthShake:
        _paintEarthShake(canvas, size, words, currentWordFloat);
        break;
      case ArabicTextAnimation.compass:
        _paintCompass(canvas, size, words, currentWordFloat);
        break;
    }
  }

  // ═══════════════════════════════════════════
  // Layout & Math Helpers
  // ═══════════════════════════════════════════

  List<_WordLayout> _layoutWords(Size size) {
    final rawWords = config.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (rawWords.isEmpty) return [];

    final words = <_WordLayout>[];
    final fontSize = config.baseStyle.fontSize ?? 32;
    final lineHeight = fontSize * 1.4;
    final startY = (size.height - lineHeight) / 2;
    double xOffset = 0;

    for (int i = 0; i < rawWords.length; i++) {
      final wordWidth = _measureWord(rawWords[i]);
      final spaceWidth = i < rawWords.length - 1 ? fontSize * 0.3 : 0;
      words.add(_WordLayout(word: rawWords[i], x: xOffset, y: startY, width: wordWidth, height: lineHeight));
      xOffset += wordWidth + spaceWidth;
    }
    return words;
  }

  double _measureWord(String word) {
    final p = TextPainter(text: TextSpan(text: word, style: config.baseStyle), textDirection: TextDirection.rtl)..layout();
    return p.width;
  }

  double _totalWidth(List<_WordLayout> words) {
    if (words.isEmpty) return 0;
    return words.last.x + words.last.width;
  }

  int _getCurrentWordIndex(int totalWords) {
    if (config.wordTimings.isNotEmpty && config.wordTimings.length == totalWords) {
      for (int i = 0; i < config.wordTimings.length; i++) {
        if (config.currentTime >= config.wordTimings[i]['start'] && config.currentTime < config.wordTimings[i]['end']) return i;
      }
      return totalWords - 1;
    }
    return (config.progress * totalWords).floor().clamp(0, totalWords - 1);
  }

  double _xOffset(_WordLayout w, Size size) => config.isRTL ? size.width - w.x - w.width : w.x;

  // Easing
  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
  double _easeOutBack(double t) { const s = 1.70158; return 1 + (s + 1) * math.pow(t - 1, 3) + s * math.pow(t - 1, 2); }

  void _drawTextAt(Canvas canvas, String text, TextStyle style, double x, double y) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.rtl)..layout();
    tp.paint(canvas, Offset(x, y));
  }

  // ═══════════════════════════════════════════
  // REVELATION ANIMATIONS (5)
  // ═══════════════════════════════════════════

  /// 1. DIVINE REVELATION — Karaoke sweep + golden particles floating up
  void _paintDivineRevelation(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    // Base dim text
    for (final w in words) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.baseStyle.color?.withValues(alpha: 0.35)), _xOffset(w, size), w.y);
    }
    // Clip reveal
    final revealW = _totalWidth(words) * config.progress.clamp(0.0, 1.0);
    if (revealW <= 0) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(config.isRTL ? size.width - revealW : 0, 0, revealW, size.height));
    for (final w in words) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.highlightColor, fontWeight: FontWeight.w700), _xOffset(w, size), w.y);
    }
    canvas.restore();
    // Particles
    final rng = math.Random(config.elapsed.toInt());
    for (int i = 0; i < 20; i++) {
      final px = rng.nextDouble() * size.width;
      final py = size.height * (1 - config.progress) + rng.nextDouble() * size.height * config.progress * 0.5;
      final r = rng.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(px, py), r, Paint()..color = config.highlightColor.withValues(alpha: 0.4 * config.progress));
    }
  }

  /// 2. CELESTIAL LIGHT — Vertical light beam sweep from top
  void _paintCelestialLight(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (final w in words) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.baseStyle.color?.withValues(alpha: 0.3)), _xOffset(w, size), w.y);
    }
    final beamY = size.height * config.progress.clamp(0.0, 1.0);
    final beamH = size.height * 0.15;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, beamY - beamH / 2, size.width, beamH));
    for (final w in words) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w700), _xOffset(w, size), w.y);
    }
    canvas.restore();
    // Light rays
    final paint = Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, beamY, size.width, beamH * 2));
    canvas.drawRect(Rect.fromLTWH(0, beamY, size.width, beamH * 2), paint);
  }

  /// 3. GOLDEN PARTICLES — Word-by-word with floating golden dots
  void _paintGoldenParticles(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final rng = math.Random(123);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final dist = (i - currentWordFloat).abs();
      final intensity = math.max(0, 1 - dist / 2);

      if (intensity > 0.2) {
        _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
          color: config.highlightColor, fontWeight: intensity > 0.5 ? FontWeight.w700 : null,
          shadows: [Shadow(color: config.highlightColor.withValues(alpha: 0.5), blurRadius: (12 * intensity).toDouble())],
        ), x, w.y);
      } else {
        _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.baseStyle.color?.withValues(alpha: 0.35)), x, w.y);
      }
    }
    // Floating particles
    for (int i = 0; i < 30; i++) {
      final px = rng.nextDouble() * size.width;
      final py = (rng.nextDouble() * size.height - config.elapsed * 30) % size.height;
      if (py < 0) continue;
      final r = rng.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(px, py), r, Paint()..color = config.highlightColor.withValues(alpha: 0.3 * config.progress));
    }
  }

  /// 4. DIVINE RADIANCE — Radial gradient glow from center expanding outward
  void _paintDivineRadiance(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final cx = size.width / 2, cy = size.height / 2;
    final radius = math.max(size.width, size.height) * config.progress.clamp(0.0, 1.0);

    // Background glow
    final glowPaint = Paint()..shader = RadialGradient(
      colors: [config.highlightColor.withValues(alpha: 0.2), Colors.transparent],
      radius: 0.5,
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, glowPaint);

    for (final w in words) {
      final x = _xOffset(w, size);
      final wx = x + w.width / 2;
      final dist = math.sqrt(math.pow(wx - cx, 2) + math.pow(w.y + w.height / 2 - cy, 2));
      final revealed = dist < radius;

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
        fontWeight: revealed ? FontWeight.w700 : null,
      ), x, w.y);
    }
  }

  /// 5. ETHEREAL GLOW — Soft pulsing glow around each revealed word
  void _paintEtherealGlow(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final dist = (i - currentWordFloat).abs();
      final pulse = 0.7 + 0.3 * math.sin(config.elapsed * 3 + i * 0.5);
      final intensity = math.max(0, 1 - dist / 2.5) * pulse;

      if (intensity > 0.1) {
        // Glow behind word
        final glowR = w.width * 0.6 * intensity;
        canvas.drawCircle(Offset(x + w.width / 2, w.y + w.height / 2), glowR, Paint()
          ..color = config.highlightColor.withValues(alpha: 0.15 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

        _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
          color: intensity > 0.5 ? Colors.white : config.baseStyle.color?.withValues(alpha: 0.35 + 0.65 * intensity),
          fontWeight: intensity > 0.5 ? FontWeight.w700 : null,
        ), x, w.y);
      } else {
        _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.baseStyle.color?.withValues(alpha: 0.3)), x, w.y);
      }
    }
  }

  // ═══════════════════════════════════════════
  // NATURE ANIMATIONS (9)
  // ═══════════════════════════════════════════

  /// 6. SACRED RIPPLE — Words ripple outward like water waves
  void _paintSacredRipple(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final dist = (i - currentWordFloat).abs();
      final ripple = dist < 3 ? math.sin((3 - dist) * math.pi * 2) * 3 * config.progress : 0;
      final x = _xOffset(w, size);

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: dist < 1.5 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
        shadows: ripple.abs() > 1 ? [Shadow(color: config.highlightColor.withValues(alpha: 0.4), blurRadius: 8)] : [],
      ), x, w.y + ripple);
    }
  }

  /// 7. MERCY WAVE — Gentle sinusoidal wave passes through words
  void _paintMercyWave(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final dist = (i - currentWordFloat).abs();
      final waveOffset = math.sin((currentWordFloat - i) * 1.2 + config.elapsed * 2) * 6;
      final colorIntensity = math.max(0, 1 - dist / 3);
      final x = _xOffset(w, size);

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: colorIntensity > 0.5 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35 + 0.65 * colorIntensity),
      ), x, w.y + waveOffset);
    }
  }

  /// 8. BLESSED RAIN — Small dots rain down on revealed words
  void _paintBlessedRain(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final rng = math.Random(777);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = i < currentWordFloat;
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
      ), x, w.y);

      // Rain drops on revealed words
      if (revealed) {
        for (int d = 0; d < 5; d++) {
          final rx = x + rng.nextDouble() * w.width;
          final ry = (w.y - 20 + rng.nextDouble() * 40 + config.elapsed * 50) % (size.height + 20) - 10;
          canvas.drawLine(Offset(rx, ry), Offset(rx + 1, ry + 6), Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1);
        }
      }
    }
  }

  /// 9. AUTUMN LEAVES — Small leaf shapes drift across revealed text
  void _paintAutumnLeaves(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final rng = math.Random(999);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = i < currentWordFloat;
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
        fontWeight: revealed ? FontWeight.w700 : null,
      ), x, w.y);
    }
    // Falling leaves
    final leafColors = [const Color(0xFFD2691E), const Color(0xFFCD853F), const Color(0xFFDAA520), const Color(0xFFB8860B)];
    for (int i = 0; i < 15; i++) {
      final lx = (rng.nextDouble() * size.width + config.elapsed * 20 * rng.nextDouble()) % size.width;
      final ly = (rng.nextDouble() * size.height + config.elapsed * 40) % (size.height + 20) - 10;
      final rot = config.elapsed * 2 + i;
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(rot);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 6, height: 3), Paint()
        ..color = leafColors[i % 4].withValues(alpha: 0.5 * config.progress));
      canvas.restore();
    }
  }

  /// 10. FLOWER BLOOM — Words scale up from center like blooming flowers
  void _paintFlowerBloom(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = ((i + 1) / words.length).clamp(0.0, 1.0);
      final bloom = config.progress > wordProgress ? _easeOutCubic((config.progress - wordProgress) * 3).clamp(0.0, 1.0) : 0;
      final scale = 0.5 + 0.5 * bloom;

      canvas.save();
      canvas.translate(x + w.width / 2, w.y + w.height / 2);
      canvas.scale(scale);
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: bloom > 0.5 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
        fontWeight: bloom > 0.5 ? FontWeight.w700 : null,
      ), -w.width / 2, -w.height / 2);
      canvas.restore();
    }
  }

  /// 11. GENTLE WIND — Words sway gently left-right like in a breeze
  void _paintGentleWind(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final dist = (i - currentWordFloat).abs();
      final windOffset = math.sin(config.elapsed * 2 + i * 0.4) * 4 * (config.progress.clamp(0.0, 1.0));
      final swayY = math.cos(config.elapsed * 1.5 + i * 0.3) * 2;
      final x = _xOffset(w, size) + windOffset;

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: dist < 2 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
      ), x, w.y + swayY);
    }
  }

  /// 12. WATER DROPS — Circular ripple expands on each revealed word
  void _paintWaterDrops(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final dist = (i - currentWordFloat).abs();
      final revealed = dist < 2;

      if (revealed) {
        final rippleR = (config.elapsed * 20) % 30;
        canvas.drawCircle(Offset(x + w.width / 2, w.y + w.height / 2), rippleR, Paint()
          ..color = config.highlightColor.withValues(alpha: 0.2 * (1 - rippleR / 30))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
      ), x, w.y);
    }
  }

  /// 13. RAINBOW — Gradient color sweep across text
  void _paintRainbow(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final totalW = _totalWidth(words);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordCenter = w.x + w.width / 2;
      final rainbowPos = ((wordCenter / totalW - config.progress * 0.5) * 2).clamp(-1, 1);

      Color wordColor;
      if (rainbowPos.abs() < 0.5) {
        final hue = (rainbowPos + 0.5) * 360;
        wordColor = HSLColor.fromAHSL(1, hue % 360, 0.8, 0.6).toColor();
      } else {
        wordColor = config.baseStyle.color?.withValues(alpha: 0.35) ?? Colors.white;
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: wordColor, fontWeight: rainbowPos.abs() < 0.3 ? FontWeight.w700 : null), x, w.y);
    }
  }

  /// 14. RIVER FLOW — Horizontal flow with subtle wave distortion
  void _paintRiverFlow(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final revealedCount = (config.progress * words.length).ceil().clamp(0, words.length);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - revealedCount : i < revealedCount;
      final waveY = math.sin(config.elapsed * 3 + i * 0.5) * 2;

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.25),
        fontWeight: revealed ? FontWeight.w600 : null,
      ), x, w.y + waveY);
    }
  }

  // ═══════════════════════════════════════════
  // CALLIGRAPHY ANIMATIONS (4)
  // ═══════════════════════════════════════════

  /// 15. LIVING CALLIGRAPHY — Words appear as if being written by invisible pen
  void _paintLivingCalligraphy(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final revealedCount = (config.progress * words.length).ceil().clamp(0, words.length);
    final visibleWords = config.isRTL
        ? words.skip(words.length - revealedCount).toList()
        : words.take(revealedCount).toList();

    // Pen trail
    if (visibleWords.isNotEmpty) {
      final lastW = config.isRTL ? visibleWords.first : visibleWords.last;
      final lx = config.isRTL ? _xOffset(lastW, size) + lastW.width : _xOffset(lastW, size);
      canvas.drawCircle(Offset(lx, lastW.y + lastW.height / 2), 3, Paint()
        ..color = config.highlightColor.withValues(alpha: 0.6));
    }

    for (final w in visibleWords) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: config.highlightColor, fontWeight: FontWeight.w700,
        shadows: [Shadow(color: config.highlightColor.withValues(alpha: 0.3), blurRadius: 5)],
      ), _xOffset(w, size), w.y);
    }
  }

  /// 16. INK FLOW — Words appear gradually like ink flowing on paper
  void _paintInkFlow(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = config.isRTL
          ? ((words.length - 1 - i) / words.length).clamp(0.0, 1.0)
          : (i / words.length).clamp(0.0, 1.0);
      final revealed = config.progress > wordProgress;
      final inkProgress = revealed ? _easeOutCubic((config.progress - wordProgress) * 4).clamp(0.0, 1.0) : 0;

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(config.isRTL ? size.width - w.x - w.width * inkProgress : _xOffset(w, size), w.y, w.width * inkProgress, w.height));
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: config.highlightColor.withValues(alpha: 0.35 + 0.65 * inkProgress),
        fontWeight: FontWeight.w600,
      ), x, w.y);
      canvas.restore();
    }
  }

  /// 17. BRUSH STROKES — Words appear with thick brush-like reveal
  void _paintBrushStrokes(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = config.isRTL
          ? ((words.length - 1 - i) / words.length)
          : ((i + 1) / words.length);
      final strokeProgress = (config.progress / wordProgress).clamp(0.0, 1.0);

      // Brush stroke background
      if (strokeProgress > 0) {
        final strokeH = w.height * 1.2;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, w.y + w.height / 2 - strokeH / 2, w.width + 4, strokeH),
          const Radius.circular(4),
        ), Paint()..color = config.highlightColor.withValues(alpha: 0.1 * strokeProgress));
      }

      final revealed = config.progress >= wordProgress;
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
        fontWeight: revealed ? FontWeight.w700 : null,
      ), x, w.y);
    }
  }

  /// 18. QUILL WRITING — Elegant word-by-word with feather pen effect
  void _paintQuillWriting(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final revealedCount = (config.progress * words.length).ceil().clamp(0, words.length);
    final visibleWords = config.isRTL
        ? words.skip(words.length - revealedCount)
        : words.take(revealedCount);

    for (final w in visibleWords) {
      final x = _xOffset(w, size);
      // Slight angle transform for handwritten feel
      canvas.save();
      canvas.translate(x + w.width / 2, w.y + w.height / 2);
      canvas.rotate(0.02 * math.sin(config.elapsed + w.x * 0.01));
      canvas.translate(-w.width / 2, -w.height / 2);
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: config.highlightColor, fontWeight: FontWeight.w600,
      ), 0, 0);
      canvas.restore();
    }
  }

  // ═══════════════════════════════════════════
  // GEOMETRY ANIMATIONS (6)
  // ═══════════════════════════════════════════

  /// 19. MOSAIC ASSEMBLY — Words appear as mosaic tiles snapping into place
  void _paintMosaicAssembly(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    final tileRng = math.Random(42);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = config.isRTL ? ((words.length - i) / words.length) : ((i + 1) / words.length);
      final revealed = config.progress > wordProgress;

      // Tile effect
      if (!revealed) {
        _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.baseStyle.color?.withValues(alpha: 0.2)), x, w.y);
      } else {
        // Scattered tiles converging
        final converge = _easeOutBack((config.progress - wordProgress) * 3).clamp(0.0, 1.0);
        canvas.save();
        canvas.translate(x + w.width / 2, w.y + w.height / 2);
        canvas.scale(converge);
        canvas.translate(-w.width / 2, -w.height / 2);
        _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.highlightColor, fontWeight: FontWeight.w700), 0, 0);
        canvas.restore();

        // Mosaic tiles
        if (converge < 1) {
          for (int t = 0; t < 3; t++) {
            final tx = x + tileRng.nextDouble() * w.width;
            final ty = w.y + tileRng.nextDouble() * w.height;
            canvas.drawRect(Rect.fromCenter(center: Offset(tx, ty), width: 4, height: 4), Paint()
              ..color = config.highlightColor.withValues(alpha: 0.3 * (1 - converge)));
          }
        }
      }
    }
  }

  /// 20. GOLDEN SPIRAL — Words spiral in from center
  void _paintGoldenSpiral(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = ((i + 1) / words.length).clamp(0.0, 1.0);
      final spiral = config.progress > wordProgress ? _easeOutCubic((config.progress - wordProgress) * 3).clamp(0.0, 1.0) : 0;

      canvas.save();
      // Spiral from center
      final spiralAngle = (1 - spiral) * math.pi * 2;
      final spiralDist = (1 - spiral) * 50;
      final sx = x + w.width / 2 + math.cos(spiralAngle + i) * spiralDist - w.width / 2;
      final sy = w.y + w.height / 2 + math.sin(spiralAngle + i) * spiralDist - w.height / 2;
      canvas.translate(sx, sy);
      canvas.scale(0.5 + 0.5 * spiral);
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: spiral > 0.5 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x - sx, w.y - sy);
      canvas.restore();
    }
  }

  /// 21. ZELLIGE — Geometric pattern reveal behind each word
  void _paintZellige(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final patternRng = math.Random(2024);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      // Geometric pattern
      if (revealed) {
        final patternSize = 8.0;
        for (double px = x; px < x + w.width; px += patternSize) {
          for (double py = w.y; py < w.y + w.height; py += patternSize) {
            if (patternRng.nextDouble() < 0.3) {
              canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: patternSize * 0.7, height: patternSize * 0.7),
                Paint()..color = config.highlightColor.withValues(alpha: 0.08));
            }
          }
        }
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  /// 22. PERSIAN CARPET — Rich ornamental frame builds around text
  void _paintPersianCarpet(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      // Ornamental border
      if (revealed) {
        final borderR = 4.0;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 4, w.y - 2, w.width + 8, w.height + 4),
          Radius.circular(borderR),
        ), Paint()
          ..color = config.highlightColor.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
        fontWeight: revealed ? FontWeight.w600 : null,
      ), x, w.y);
    }
  }

  /// 23. FRACTAL GROWTH — Words grow organically like fractal branches
  void _paintFractalGrowth(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = config.isRTL ? ((words.length - i) / words.length) : ((i + 1) / words.length);
      final growth = config.progress > wordProgress ? _easeOutCubic((config.progress - wordProgress) * 2).clamp(0.0, 1.0) : 0;

      canvas.save();
      canvas.translate(x + w.width / 2, w.y + w.height / 2);
      canvas.scale(0.3 + 0.7 * growth);
      canvas.translate(-w.width / 2, -w.height / 2);
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: growth > 0.5 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), 0, 0);
      canvas.restore();
    }
  }

  /// 24. HONEYCOMB — Hexagonal cells reveal each word
  void _paintHoneycomb(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      // Hexagonal cell
      if (revealed) {
        final hexR = math.max(w.width, w.height) * 0.6;
        final path = Path();
        for (int h = 0; h < 6; h++) {
          final angle = h * math.pi / 3 - math.pi / 6;
          final hx = x + w.width / 2 + hexR * math.cos(angle);
          final hy = w.y + w.height / 2 + hexR * math.sin(angle);
          if (h == 0) { path.moveTo(hx, hy); } else { path.lineTo(hx, hy); }
        }
        path.close();
        canvas.drawPath(path, Paint()
          ..color = config.highlightColor.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  // ═══════════════════════════════════════════
  // SPIRITUAL ANIMATIONS (7)
  // ═══════════════════════════════════════════

  /// 25. CRESCENT MOON — Crescent shape sweeps across text
  void _paintCrescentMoon(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
    // Crescent indicator
    final moonX = size.width * (1 - config.progress.clamp(0.0, 1.0));
    canvas.drawArc(Rect.fromCenter(center: Offset(moonX, size.height * 0.3), width: 20, height: 20), 0.3, 5.5, true, Paint()
      ..color = config.highlightColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill);
  }

  /// 26. MINARET RISE — Words rise up like minarets from below
  void _paintMinaretRise(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wordProgress = ((i + 1) / words.length).clamp(0.0, 1.0);
      final rise = config.progress > wordProgress ? _easeOutCubic((config.progress - wordProgress) * 2).clamp(0.0, 1.0) : 0;

      canvas.save();
      canvas.translate(x, w.y + w.height * (1 - rise));
      canvas.clipRect(Rect.fromLTWH(0, 0, w.width, w.height * rise + 2));
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: rise > 0.5 ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), 0, 0);
      canvas.restore();
    }
  }

  /// 27. PRAYER BEADS — Bead-like dots connect revealed words
  void _paintPrayerBeads(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    final revealedWords = <_WordLayout>[];
    for (int i = 0; i < words.length; i++) {
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();
      if (revealed) revealedWords.add(words[i]);
    }

    // Connect beads
    for (int i = 0; i < revealedWords.length - 1; i++) {
      final w1 = revealedWords[i], w2 = revealedWords[i + 1];
      final x1 = _xOffset(w1, size) + w1.width, x2 = _xOffset(w2, size);
      final midX = (x1 + x2) / 2;
      canvas.drawCircle(Offset(midX, w1.y + w1.height / 2), 3, Paint()
        ..color = config.highlightColor.withValues(alpha: 0.3));
    }

    // Words
    for (final w in revealedWords) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: config.highlightColor, fontWeight: FontWeight.w700,
      ), _xOffset(w, size), w.y);
    }
  }

  /// 28. INCENSE SMOKE — Wispy smoke rises from text
  void _paintIncenseSmoke(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final smokeRng = math.Random(28);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);

      // Smoke wisps above revealed words
      if (revealed) {
        for (int s = 0; s < 3; s++) {
          final smokeX = x + smokeRng.nextDouble() * w.width;
          final smokeY = w.y - 5 - smokeRng.nextDouble() * 20 - (config.elapsed * 10) % 30;
          canvas.drawCircle(Offset(smokeX, smokeY), smokeRng.nextDouble() * 3 + 1, Paint()
            ..color = Colors.white.withValues(alpha: 0.1 * config.progress));
        }
      }
    }
  }

  /// 29. SACRED FIRE — Flame effect on active word
  void _paintSacredFire(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final fireRng = math.Random(29);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final dist = (i - currentWordFloat).abs();
      final isActive = dist < 1.5;

      // Flames above active word
      if (isActive) {
        for (int f = 0; f < 8; f++) {
          final fx = x + fireRng.nextDouble() * w.width;
          final fy = w.y - fireRng.nextDouble() * 15;
          final fh = fireRng.nextDouble() * 10 + 5;
          final flameColors = [Colors.orange, Colors.red, const Color(0xFFFFD700)];
          canvas.drawOval(Rect.fromCenter(center: Offset(fx, fy), width: 3, height: fh), Paint()
            ..color = flameColors[f % 3].withValues(alpha: 0.4));
        }
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: isActive ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.35),
        shadows: isActive ? [Shadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 8)] : [],
      ), x, w.y);
    }
  }

  /// 30. NIGHT OF POWER — Stars twinkle on revealed words
  void _paintNightOfPower(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final starRng = math.Random(30);
    // Dark background effect
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
      ..color = Colors.black.withValues(alpha: 0.2 * config.progress));

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      // Stars
      if (revealed) {
        for (int s = 0; s < 4; s++) {
          final sx = x + starRng.nextDouble() * w.width;
          final sy = w.y - 5 - starRng.nextDouble() * 10;
          final twinkle = 0.5 + 0.5 * math.sin(config.elapsed * 5 + s + i);
          canvas.drawCircle(Offset(sx, sy), 1.5 * twinkle, Paint()
            ..color = Colors.white.withValues(alpha: twinkle * 0.6));
        }
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? Colors.white : config.baseStyle.color?.withValues(alpha: 0.25),
        fontWeight: revealed ? FontWeight.w700 : null,
      ), x, w.y);
    }
  }

  /// 31. FLYING CARPET — Text floats and bobs like a magic carpet
  void _paintFlyingCarpet(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final bobY = math.sin(config.elapsed * 2) * 4 * config.progress;
    canvas.save();
    canvas.translate(0, bobY);

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
        shadows: revealed ? [Shadow(color: config.highlightColor.withValues(alpha: 0.3), blurRadius: 6)] : [],
      ), x, w.y);
    }
    canvas.restore();
  }

  // ═══════════════════════════════════════════
  // COSMIC ANIMATIONS (10)
  // ═══════════════════════════════════════════

  /// 32. CONSTELLATION — Words connected by star lines
  void _paintConstellation(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    final revealed = <_WordLayout>[];
    for (int i = 0; i < words.length; i++) {
      final isRevealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();
      if (isRevealed) revealed.add(words[i]);
    }

    // Connect with lines
    if (revealed.length > 1) {
      for (int i = 0; i < revealed.length - 1; i++) {
        final w1 = revealed[i], w2 = revealed[i + 1];
        final x1 = _xOffset(w1, size) + w1.width / 2, x2 = _xOffset(w2, size) + w2.width / 2;
        canvas.drawLine(Offset(x1, w1.y + w1.height / 2), Offset(x2, w2.y + w2.height / 2), Paint()
          ..color = config.highlightColor.withValues(alpha: 0.2)
          ..strokeWidth = 1);
      }
    }

    // Stars at word centers
    for (final w in revealed) {
      final cx = _xOffset(w, size) + w.width / 2;
      canvas.drawCircle(Offset(cx, w.y + w.height / 2), 2, Paint()
        ..color = config.highlightColor.withValues(alpha: 0.5));
    }

    // Words
    for (final w in revealed) {
      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(color: config.highlightColor, fontWeight: FontWeight.w700), _xOffset(w, size), w.y);
    }
  }

  /// 33. STARDUST — Fine glitter particles on revealed words
  void _paintStardust(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final dustRng = math.Random(33);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      if (revealed) {
        for (int d = 0; d < 12; d++) {
          final dx = x + dustRng.nextDouble() * w.width;
          final dy = w.y + dustRng.nextDouble() * w.height;
          canvas.drawCircle(Offset(dx, dy), dustRng.nextDouble() * 1.5, Paint()
            ..color = config.highlightColor.withValues(alpha: 0.3));
        }
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  /// 34. AURORA — Color wave sweeps across text
  void _paintAurora(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final wave = math.sin(i * 0.5 - config.elapsed * 2) * 0.5 + 0.5;
      final hue = (wave * 120 + config.elapsed * 50) % 360;
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor() : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  /// 35. GALAXY — Spiral reveal from center
  void _paintGalaxy(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final cx = size.width / 2, cy = size.height / 2;
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final wx = _xOffset(w, size) + w.width / 2;
      final wy = w.y + w.height / 2;
      final dist = math.sqrt(math.pow(wx - cx, 2) + math.pow(wy - cy, 2));
      final maxDist = math.sqrt(math.pow(cx, 2) + math.pow(cy, 2));
      final revealed = dist < maxDist * config.progress;

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.25),
        fontWeight: revealed ? FontWeight.w700 : null,
      ), _xOffset(w, size), w.y);
    }
    // Spiral arm hint
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.8, height: size.height * 0.8), 0, config.progress * math.pi * 4, false, Paint()
      ..color = config.highlightColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  /// 36. DIAMOND SPARKLE — Words sparkle like diamonds
  void _paintDiamondSparkle(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat, int currentWordIndex) {
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final dist = (i - currentWordFloat).abs();
      final sparkle = dist < 1.5 ? (0.5 + 0.5 * math.sin(config.elapsed * 8 + i * 2)) : 0;
      final revealed = dist < 2;

      // Sparkle cross
      if (sparkle > 0.7) {
        final cx = x + w.width / 2, cy = w.y + w.height / 2;
        canvas.drawLine(Offset(cx - 8, cy), Offset(cx + 8, cy), Paint()
          ..color = Colors.white.withValues(alpha: sparkle * 0.6)
          ..strokeWidth = 1);
        canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), Paint()
          ..color = Colors.white.withValues(alpha: sparkle * 0.6)
          ..strokeWidth = 1);
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  /// 37. LIGHT BUTTERFLIES — Small glowing butterflies flutter around text
  void _paintLightButterflies(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final bfRng = math.Random(37);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);

      // Butterfly
      if (revealed) {
        final bx = x + bfRng.nextDouble() * w.width + math.sin(config.elapsed * 3 + i) * 15;
        final by = w.y + math.cos(config.elapsed * 2 + i) * 10;
        // Wings
        canvas.drawOval(Rect.fromCenter(center: Offset(bx - 3, by), width: 4, height: 6), Paint()
          ..color = config.highlightColor.withValues(alpha: 0.3));
        canvas.drawOval(Rect.fromCenter(center: Offset(bx + 3, by), width: 4, height: 6), Paint()
          ..color = config.highlightColor.withValues(alpha: 0.3));
      }
    }
  }

  /// 38. SUNSET — Warm gradient wash over text
  void _paintSunset(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    // Gradient background
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter, end: Alignment.topCenter,
      colors: [
        const Color(0xFFFF6B35).withValues(alpha: 0.15 * config.progress),
        const Color(0xFFFFD700).withValues(alpha: 0.1 * config.progress),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = gradient);

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? const Color(0xFFFF8C42) : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  /// 39. LIGHTNING — Electric flash on active word
  void _paintLightning(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final lightRng = math.Random(39);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final dist = (i - currentWordFloat).abs();
      final isFlashing = dist < 1 && (config.elapsed * 5).floor() % 3 == 0;

      if (isFlashing) {
        // Lightning bolt
        canvas.drawLine(Offset(x + w.width / 2, w.y - 10), Offset(x + w.width / 2 + lightRng.nextDouble() * 10 - 5, w.y), Paint()
          ..color = Colors.white
          ..strokeWidth = 2);
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: dist < 1.5 || isFlashing ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
        shadows: isFlashing ? [Shadow(color: Colors.white, blurRadius: 15)] : [],
      ), x, w.y);
    }
  }

  /// 40. EARTH SHAKE — Words tremble when revealed
  void _paintEarthShake(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final shakeRng = math.Random(40);
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      double shakeX = 0, shakeY = 0;
      if (revealed && config.progress < 0.3) {
        final shakeIntensity = (0.3 - config.progress) * 10;
        shakeX = (shakeRng.nextDouble() - 0.5) * shakeIntensity;
        shakeY = (shakeRng.nextDouble() - 0.5) * shakeIntensity;
      }

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
        fontWeight: revealed ? FontWeight.w700 : null,
      ), x + shakeX, w.y + shakeY);
    }
  }

  /// 41. COMPASS — Directional pointer sweeps to each word
  void _paintCompass(Canvas canvas, Size size, List<_WordLayout> words, double currentWordFloat) {
    final cx = size.width / 2, cy = size.height / 2;

    // Compass needle
    if (words.isNotEmpty) {
      final targetIdx = (config.progress * (words.length - 1)).round().clamp(0, words.length - 1);
      final targetW = words[targetIdx];
      final tx = _xOffset(targetW, size) + targetW.width / 2;
      final ty = targetW.y + targetW.height / 2;

      canvas.drawLine(Offset(cx, cy), Offset(tx, ty), Paint()
        ..color = config.highlightColor.withValues(alpha: 0.3)
        ..strokeWidth = 1);
      canvas.drawCircle(Offset(tx, ty), 3, Paint()
        ..color = config.highlightColor.withValues(alpha: 0.5));
    }

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final x = _xOffset(w, size);
      final revealed = config.isRTL ? i >= words.length - (config.progress * words.length).ceil() : i < (config.progress * words.length).ceil();

      _drawTextAt(canvas, w.word, config.baseStyle.copyWith(
        color: revealed ? config.highlightColor : config.baseStyle.color?.withValues(alpha: 0.3),
      ), x, w.y);
    }
  }

  @override
  bool shouldRepaint(covariant ArabicTextPainter old) {
    return old.config.progress != config.progress ||
        old.config.elapsed != config.elapsed ||
        old.config.currentTime != config.currentTime ||
        old.config.text != config.text ||
        old.config.animation != config.animation;
  }
}
