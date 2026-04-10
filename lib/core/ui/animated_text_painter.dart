import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════
/// Animated Text Engine — LTR/RTL Support
/// ═══════════════════════════════════════════
///
/// Renders text with word-by-word or character-by-character animations
/// respecting text directionality (LTR for French, RTL for Arabic).

/// Animation type for segmenting text
enum TextAnimationUnit { word, character }

/// Animation preset for text entrance/exit
class TextAnimationPreset {
  final String id;
  final String label;
  final TextAnimationUnit unit;
  final double defaultDuration;
  final double stagger; // delay between segments (seconds)

  const TextAnimationPreset({
    required this.id,
    required this.label,
    this.unit = TextAnimationUnit.word,
    this.defaultDuration = 1.0,
    this.stagger = 0.05,
  });

  // ═══════════════════════════════════════════
  // PRESET DEFINITIONS
  // ═══════════════════════════════════════════

  static const none = TextAnimationPreset(id: 'none', label: 'Aucune');

  static const typewriter = TextAnimationPreset(
    id: 'typewriter', label: 'Machine à écrire',
    unit: TextAnimationUnit.character, stagger: 0.08,
  );

  static const wordByWord = TextAnimationPreset(
    id: 'wordByWord', label: 'Mot par mot',
    unit: TextAnimationUnit.word, stagger: 0.1,
  );

  static const fadeIn = TextAnimationPreset(
    id: 'fadeIn', label: 'Apparition',
  );

  static const slideInLeft = TextAnimationPreset(
    id: 'slideInLeft', label: 'Glisser depuis gauche',
  );

  static const slideInRight = TextAnimationPreset(
    id: 'slideInRight', label: 'Glisser depuis droite',
  );

  static const slideInTop = TextAnimationPreset(
    id: 'slideInTop', label: 'Glisser depuis haut',
  );

  static const slideInBottom = TextAnimationPreset(
    id: 'slideInBottom', label: 'Glisser depuis bas',
  );

  static const scaleIn = TextAnimationPreset(
    id: 'scaleIn', label: 'Zoom entrant',
  );

  static const bounceIn = TextAnimationPreset(
    id: 'bounceIn', label: 'Rebond',
  );

  static const karaokeSweep = TextAnimationPreset(
    id: 'karaokeSweep', label: 'Karaoké Sweep',
  );

  static const divineIgnition = TextAnimationPreset(
    id: 'divineIgnition', label: 'Ignition Divine',
    unit: TextAnimationUnit.word, stagger: 0.05,
  );

  static const wave = TextAnimationPreset(
    id: 'wave', label: 'Vague',
    unit: TextAnimationUnit.word, stagger: 0.0,
  );

  static const glitch = TextAnimationPreset(
    id: 'glitch', label: 'Glitch',
    unit: TextAnimationUnit.character, stagger: 0.0,
  );

  static List<TextAnimationPreset> get all => [
    none, typewriter, wordByWord, fadeIn, slideInLeft, slideInRight,
    slideInTop, slideInBottom, scaleIn, bounceIn, karaokeSweep,
    divineIgnition, wave, glitch,
  ];
}

/// ═══════════════════════════════════════════
/// Animated Text Segment
/// ═══════════════════════════════════════════

class AnimatedSegment {
  final String text;
  final int index;
  final Offset position;
  final double opacity;
  final double scale;
  final double rotation;
  final double blur;
  final Color? color;

  const AnimatedSegment({
    required this.text,
    required this.index,
    this.position = Offset.zero,
    this.opacity = 1.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.blur = 0.0,
    this.color,
  });

  AnimatedSegment copyWith({
    String? text,
    int? index,
    Offset? position,
    double? opacity,
    double? scale,
    double? rotation,
    double? blur,
    Color? color,
  }) {
    return AnimatedSegment(
      text: text ?? this.text,
      index: index ?? this.index,
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      blur: blur ?? this.blur,
      color: color ?? this.color,
    );
  }
}

/// ═══════════════════════════════════════════
/// Easing Functions
/// ═══════════════════════════════════════════

class EasingFunctions {
  static double linear(double t) => t;
  static double easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
  static double easeIn(double t) => t * t * t;
  static double easeInOut(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }
  static double bounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
      return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
      return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
  }
}

/// ═══════════════════════════════════════════
/// Text Animation Painter
/// ═══════════════════════════════════════════

class AnimatedTextPainter extends CustomPainter {
  final String text;
  final TextAnimationPreset preset;
  final TextStyle style;
  final double progress; // 0.0 to 1.0
  final bool isRTL;
  final double? maxWidth;
  final double elapsed; // seconds since animation start
  final double duration; // total animation duration
  final Color? highlightColor; // color for karaoke highlight

  const AnimatedTextPainter({
    required this.text,
    required this.preset,
    required this.style,
    required this.progress,
    this.isRTL = false,
    this.maxWidth,
    this.elapsed = 0,
    this.duration = 1.0,
    this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (preset.id) {
      case 'none':
        _paintSimple(canvas, size, 1.0);
        break;
      case 'fadeIn':
        _paintSimple(canvas, size, progress);
        break;
      case 'typewriter':
        _paintTypewriter(canvas, size);
        break;
      case 'wordByWord':
        _paintWordByWord(canvas, size);
        break;
      case 'slideInLeft':
      case 'slideInRight':
      case 'slideInTop':
      case 'slideInBottom':
      case 'scaleIn':
      case 'bounceIn':
        _paintSegmentAnimation(canvas, size);
        break;
      case 'karaokeSweep':
        _paintKaraokeSweep(canvas, size);
        break;
      case 'divineIgnition':
        _paintDivineIgnition(canvas, size);
        break;
      case 'wave':
        _paintWave(canvas, size);
        break;
      case 'glitch':
        _paintGlitch(canvas, size);
        break;
      default:
        _paintSimple(canvas, size, 1.0);
    }
  }

  // ─────────────────────────────────────────────────────────
  // SIMPLE PAINT (no animation, or global fade)
  // ─────────────────────────────────────────────────────────

  void _paintSimple(Canvas canvas, Size size, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(
        color: style.color?.withValues(alpha: opacity),
      )),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
    )..layout(maxWidth: maxWidth ?? size.width);

    final x = isRTL ? size.width - textPainter.width : 0.0;
    textPainter.paint(canvas, Offset(x, 0));
  }

  // ─────────────────────────────────────────────────────────
  // TYPEWRITER
  // ─────────────────────────────────────────────────────────

  void _paintTypewriter(Canvas canvas, Size size) {
    final chars = text.split('');
    final visibleChars = (progress * chars.length).round().clamp(0, chars.length);

    // Build visible text string
    String visibleText;
    if (isRTL) {
      // RTL: show characters from the END of the string
      visibleText = chars.skip(chars.length - visibleChars).join();
    } else {
      // LTR: show characters from the START
      visibleText = chars.take(visibleChars).join();
    }

    final textPainter = TextPainter(
      text: TextSpan(text: visibleText, style: style),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
    )..layout(maxWidth: maxWidth ?? size.width);

    final x = isRTL ? size.width - textPainter.width : 0.0;
    textPainter.paint(canvas, Offset(x, 0));

    // Draw cursor
    final cursorX = isRTL ? 0.0 : textPainter.width;
    final cursorPaint = Paint()
      ..color = style.color ?? Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, textPainter.height),
      cursorPaint,
    );
  }

  // ─────────────────────────────────────────────────────────
  // WORD BY WORD
  // ─────────────────────────────────────────────────────────

  void _paintWordByWord(Canvas canvas, Size size) {
    final words = text.split(RegExp(r'\s+'));
    final visibleCount = (progress * words.length).ceil().clamp(0, words.length);

    if (isRTL) {
      // RTL: words appear from right to left
      final visibleWords = words.skip(words.length - visibleCount).toList();
      final visibleText = visibleWords.join(' ');
      final textPainter = TextPainter(
        text: TextSpan(text: visibleText, style: style),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      )..layout(maxWidth: maxWidth ?? size.width);

      textPainter.paint(canvas, Offset(size.width - textPainter.width, 0));
    } else {
      // LTR: words appear from left to right
      final visibleWords = words.take(visibleCount).toList();
      final visibleText = visibleWords.join(' ');
      final textPainter = TextPainter(
        text: TextSpan(text: visibleText, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      )..layout(maxWidth: maxWidth ?? size.width);

      textPainter.paint(canvas, Offset.zero);
    }
  }

  // ─────────────────────────────────────────────────────────
  // SEGMENT ANIMATION (slide, scale, bounce)
  // ─────────────────────────────────────────────────────────

  void _paintSegmentAnimation(Canvas canvas, Size size) {
    final segments = _buildSegments();
    for (final segment in segments) {
      _paintSegment(canvas, segment);
    }
  }

  List<AnimatedSegment> _buildSegments() {
    final segments = <AnimatedSegment>[];
    final units = preset.unit == TextAnimationUnit.word
        ? text.split(RegExp(r'\s+'))
        : text.split('');

    final totalUnits = units.length;
    final staggerPerUnit = preset.stagger;
    final unitDuration = duration.clamp(0.2, 1.0);

    for (int i = 0; i < totalUnits; i++) {
      final unitDelay = isRTL
          ? (totalUnits - 1 - i) * staggerPerUnit
          : i * staggerPerUnit;

      // Calculate progress for this specific unit
      double unitProgress;
      if (elapsed < unitDelay) {
        unitProgress = 0.0; // hasn't started yet
      } else if (elapsed < unitDelay + unitDuration) {
        unitProgress = EasingFunctions.easeOut((elapsed - unitDelay) / unitDuration);
      } else {
        unitProgress = 1.0; // fully visible
      }

      segments.add(_computeSegmentTransform(units[i], i, unitProgress));
    }

    return segments;
  }

  AnimatedSegment _computeSegmentTransform(
    String unitText,
    int index,
    double unitProgress,
  ) {
    final opacity = unitProgress.clamp(0.0, 1.0);
    final slideDistance = 30.0;

    double dx = 0, dy = 0;
    double scale = 1.0;
    double rotation = 0;

    switch (preset.id) {
      case 'slideInLeft':
        dx = (1 - unitProgress) * slideDistance * (isRTL ? -1 : 1);
        break;
      case 'slideInRight':
        dx = (1 - unitProgress) * slideDistance * (isRTL ? 1 : -1);
        break;
      case 'slideInTop':
        dy = (1 - unitProgress) * -slideDistance;
        break;
      case 'slideInBottom':
        dy = (1 - unitProgress) * slideDistance;
        break;
      case 'scaleIn':
        scale = unitProgress;
        break;
      case 'bounceIn':
        scale = unitProgress > 0 ? EasingFunctions.bounce(unitProgress) : 0;
        break;
    }

    return AnimatedSegment(
      text: unitText,
      index: index,
      position: Offset(dx, dy),
      opacity: opacity,
      scale: scale,
      rotation: rotation,
    );
  }

  void _paintSegment(Canvas canvas, AnimatedSegment segment) {
    if (segment.opacity <= 0.01) return;

    final textStyle = style.copyWith(
      color: style.color?.withValues(alpha: segment.opacity),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: segment.text, style: textStyle),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
    )..layout();

    canvas.save();

    // Apply transform
    final centerX = textPainter.width / 2;
    final centerY = textPainter.height / 2;

    canvas.translate(
      segment.position.dx + (isRTL ? -centerX : centerX),
      segment.position.dy + centerY,
    );
    canvas.scale(segment.scale);
    canvas.rotate(segment.rotation * math.pi / 180);

    textPainter.paint(canvas, Offset(-centerX, -centerY));
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────
  // KARAOKE SWEEP (Clipping Mask)
  // ─────────────────────────────────────────────────────────

  void _paintKaraokeSweep(Canvas canvas, Size size) {
    // 1. Draw base text (dimmed)
    final baseTextPainter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(
        color: style.color?.withValues(alpha: 0.3),
      )),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
    )..layout(maxWidth: maxWidth ?? size.width);

    final baseX = isRTL ? size.width - baseTextPainter.width : 0.0;
    baseTextPainter.paint(canvas, Offset(baseX, 0));

    // 2. Draw highlighted text with clipping mask
    final revealWidth = baseTextPainter.width * progress.clamp(0.0, 1.0);

    if (revealWidth <= 0) return;

    canvas.save();

    // RTL: clip from right to left
    // LTR: clip from left to right
    final clipX = isRTL
        ? size.width - revealWidth
        : baseX;

    canvas.clipRect(Rect.fromLTWH(clipX, 0, revealWidth, baseTextPainter.height));

    final highlightStyle = style.copyWith(
      color: highlightColor ?? const Color(0xFFFFD700),
      fontWeight: FontWeight.w700,
    );

    final highlightTextPainter = TextPainter(
      text: TextSpan(text: text, style: highlightStyle),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
    )..layout(maxWidth: maxWidth ?? size.width);

    highlightTextPainter.paint(canvas, Offset(baseX, 0));
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────
  // DIVINE IGNITION (Word-by-word glow)
  // ─────────────────────────────────────────────────────────

  void _paintDivineIgnition(Canvas canvas, Size size) {
    final words = text.split(RegExp(r'\s+'));
    final totalWords = words.length;
    final currentWordFloat = progress * totalWords;
    final falloff = 1.5; // how many words around current word get glow

    double xOffset = isRTL ? size.width : 0.0;
    final direction = isRTL ? -1 : 1;

    for (int i = 0; i < totalWords; i++) {
      final word = words[i];

      // Calculate distance from current "active" word
      final distanceFromActive = (i - currentWordFloat).abs();
      final intensity = math.max(0, 1 - distanceFromActive / falloff);

      // Build style for this word
      final wordStyle = style.copyWith(
        color: style.color?.withValues(alpha: 0.4 + 0.6 * intensity),
        shadows: intensity > 0.3
            ? [
                Shadow(
                  color: (highlightColor ?? const Color(0xFFFFD700))
                      .withValues(alpha: intensity * 0.8),
                  blurRadius: intensity * 15,
                ),
              ]
            : [],
        fontWeight: intensity > 0.5 ? FontWeight.w700 : style.fontWeight,
      );

      final wordPainter = TextPainter(
        text: TextSpan(text: word, style: wordStyle),
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      )..layout();

      // Position word
      final wordX = isRTL
          ? xOffset - wordPainter.width
          : (size.width - xOffset - wordPainter.width);

      wordPainter.paint(canvas, Offset(wordX, 0));

      // Advance position
      xOffset += wordPainter.width * direction;
      if (i < totalWords - 1) {
        final spacePainter = TextPainter(
          text: const TextSpan(text: ' ', style: TextStyle(fontSize: 0)),
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        )..layout();
        xOffset += spacePainter.width * direction;
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // WAVE (Continuous sine wave offset)
  // ─────────────────────────────────────────────────────────

  void _paintWave(Canvas canvas, Size size) {
    final words = text.split(RegExp(r'\s+'));
    final frequency = 3.0;
    final amplitude = 8.0;
    final time = elapsed * 2.0; // speed of wave

    double xOffset = isRTL ? size.width : 0.0;
    final direction = isRTL ? -1 : 1;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final offsetY = math.sin(time + i * frequency) * amplitude;

      final wordStyle = style.copyWith(
        color: style.color?.withValues(
          alpha: 0.5 + 0.5 * (0.5 + 0.5 * math.sin(time + i * frequency)),
        ),
      );

      final wordPainter = TextPainter(
        text: TextSpan(text: word, style: wordStyle),
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      )..layout();

      final wordX = isRTL
          ? xOffset - wordPainter.width
          : (size.width - xOffset - wordPainter.width);

      wordPainter.paint(canvas, Offset(wordX, offsetY));

      // Advance position
      xOffset += wordPainter.width * direction;
      if (i < words.length - 1) {
        final spacePainter = TextPainter(
          text: const TextSpan(text: ' ', style: TextStyle(fontSize: 0)),
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        )..layout();
        xOffset += spacePainter.width * direction;
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // GLITCH (Random displacement and color shifts)
  // ─────────────────────────────────────────────────────────

  void _paintGlitch(Canvas canvas, Size size) {
    final chars = text.split('');
    final rng = math.Random((elapsed * 1000).toInt());

    double xOffset = isRTL ? size.width : 0.0;
    final direction = isRTL ? -1 : 1;

    for (int i = 0; i < chars.length; i++) {
      // Random glitch effect on some characters
      final isGlitching = rng.nextDouble() < 0.15 * progress;
      final offsetX = isGlitching ? rng.nextDouble() * 10 - 5 : 0.0;
      final offsetY = isGlitching ? rng.nextDouble() * 6 - 3 : 0.0;

      Color charColor = style.color ?? Colors.white;
      if (isGlitching) {
        // Random color shift
        charColor = Color.fromRGBO(
          rng.nextInt(256),
          rng.nextInt(256),
          rng.nextInt(256),
          1.0,
        );
      }

      final charStyle = style.copyWith(color: charColor);
      final charPainter = TextPainter(
        text: TextSpan(text: chars[i], style: charStyle),
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      )..layout();

      final charX = isRTL
          ? xOffset - charPainter.width
          : (size.width - xOffset - charPainter.width);

      charPainter.paint(canvas, Offset(charX + offsetX, offsetY));

      // Advance position
      xOffset += charPainter.width * direction;
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedTextPainter old) {
    return old.progress != progress ||
        old.elapsed != elapsed ||
        old.text != text ||
        old.preset != preset;
  }
}
