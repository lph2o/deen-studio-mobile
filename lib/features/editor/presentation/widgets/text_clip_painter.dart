import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/project.dart';
import '../../../../models/text_layer_style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text Clip Painter — renders a text layer with full visual effects
// ─────────────────────────────────────────────────────────────────────────────

class TextClipPainter extends CustomPainter {
  final Layer layer;
  final double playheadProgress;
  final double currentTime;
  final double? textMaxWidth;

  const TextClipPainter({
    required this.layer,
    this.playheadProgress = 0.0,
    this.currentTime = 0.0,
    this.textMaxWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final style = layer.textStyle;
    if (style == null) return;

    final rawText = style.isUppercase ? layer.content.toUpperCase() : layer.content;

    // Apply typewriter effect if applicable
    final text = _applyTextAnimation(rawText, style, playheadProgress);

    // Check if we should highlight the current word being recited
    final currentWordIndex = _getCurrentWordIndex();

    // If word timings exist and we have a current word, render with highlighting
    if (layer.wordTimings.isNotEmpty && currentWordIndex >= 0) {
      _paintWithWordHighlight(canvas, text, style, currentWordIndex, size);
      return;
    }

    final flutterStyle = _resolveTextStyle(style);

    // -- Layout --
    final tp = TextPainter(
      text: TextSpan(text: text, style: flutterStyle),
      textAlign: style.textAlign,
      textDirection: style.isRTL ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: textMaxWidth ?? size.width); // Handled by wrapping widget (e.g. ConstrainedBox)

    // Position: local origin
    const position = Offset.zero;

    // -- 1. Background rect --
    if (style.backgroundColor != null) {
      final bgPaint = Paint()
        ..color = TextLayerStyle.parseHexColor(style.backgroundColor!).withValues(alpha: style.opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(position.dx - 8, position.dy - 4, tp.width + 16, tp.height + 8),
          const Radius.circular(4),
        ),
        bgPaint,
      );
    }

    // -- 2. Shadow --
    if (style.shadowBlur > 0 || style.shadowOffsetX != 0 || style.shadowOffsetY != 0) {
      final shadowStyle = flutterStyle.copyWith(
        color: TextLayerStyle.parseHexColor(style.shadowColor).withValues(alpha: style.opacity),
        shadows: [
          Shadow(
            color: TextLayerStyle.parseHexColor(style.shadowColor),
            blurRadius: style.shadowBlur,
            offset: Offset(style.shadowOffsetX, style.shadowOffsetY),
          ),
        ],
      );
      TextPainter(
        text: TextSpan(text: text, style: shadowStyle),
        textAlign: style.textAlign,
        textDirection: style.isRTL ? TextDirection.rtl : TextDirection.ltr,
      )
        ..layout(maxWidth: textMaxWidth ?? size.width)
        ..paint(canvas, position);
    }

    // -- 3. Stroke (painted under the fill) --
    if (style.strokeWidth > 0) {
      final strokeStyle = flutterStyle.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = TextLayerStyle.parseHexColor(style.strokeColor).withValues(alpha: style.opacity),
      );
      TextPainter(
        text: TextSpan(text: text, style: strokeStyle),
        textAlign: style.textAlign,
        textDirection: style.isRTL ? TextDirection.rtl : TextDirection.ltr,
      )
        ..layout(maxWidth: textMaxWidth ?? size.width)
        ..paint(canvas, position);
    }

    // -- 4. Gradient or solid fill --
    if (style.gradientStyle != null) {
      final gradient = LinearGradient(
        colors: style.gradientStyle!.colors
            .map(TextLayerStyle.parseHexColor)
            .toList(),
        transform: GradientRotation(style.gradientStyle!.angleRadians),
      );
      final gradientPaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromLTWH(position.dx, position.dy, tp.width, tp.height));
      final gradStyle = flutterStyle.copyWith(foreground: gradientPaint);
      TextPainter(
        text: TextSpan(text: text, style: gradStyle),
        textAlign: style.textAlign,
        textDirection: style.isRTL ? TextDirection.rtl : TextDirection.ltr,
      )
        ..layout(maxWidth: textMaxWidth ?? size.width)
        ..paint(canvas, position);
    } else {
      tp.paint(canvas, position);
    }
  }

  // ── Text Style Builder ─────────────────────────────────────────────────────

  TextStyle _resolveTextStyle(TextLayerStyle style) {
    final baseStyle = style.toFlutterTextStyle();
    // Apply Google font if not a local font
    if (FontCatalogue.isLocal(style.fontFamily)) return baseStyle;
    try {
      return GoogleFonts.getFont(style.fontFamily, textStyle: baseStyle);
    } catch (_) {
      return baseStyle;
    }
  }

  // ── Word Timing & Highlight ──────────────────────────────────────────────

  /// Find the index of the word currently being recited.
  int _getCurrentWordIndex() {
    if (layer.wordTimings.isEmpty) return -1;

    final elapsed = currentTime - layer.startTime;
    for (int i = 0; i < layer.wordTimings.length; i++) {
      final wordStart = layer.wordTimings[i]['start'] as double;
      final wordEnd = layer.wordTimings[i]['end'] as double;
      if (elapsed >= wordStart && elapsed < wordEnd) {
        return i;
      }
    }
    return -1;
  }

  /// Paint text with word-by-word highlighting for Quran recitation sync.
  void _paintWithWordHighlight(Canvas canvas, String text, TextLayerStyle style, int highlightIndex, Size canvasSize) {
    final words = layer.wordTimings.map((e) => e['word'] as String).toList();
    final baseColor = TextLayerStyle.parseHexColor(style.color.isEmpty ? '#FFFFFF' : style.color);
    final highlightColor = const Color(0xFFFFD700); // Gold color for current word

    // Create text spans with highlighted word
    final textSpans = <TextSpan>[];
    for (int i = 0; i < words.length; i++) {
      final wordStyle = _resolveTextStyle(style).copyWith(
        color: i == highlightIndex ? highlightColor : baseColor,
        fontWeight: i == highlightIndex ? FontWeight.w700 : null,
      );
      textSpans.add(TextSpan(text: '${words[i]} ', style: wordStyle));
    }

    final tp = TextPainter(
      text: TextSpan(children: textSpans),
      textAlign: style.textAlign,
      textDirection: style.isRTL ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: textMaxWidth ?? canvasSize.width);

    tp.paint(canvas, Offset.zero);
  }

  String _applyTextAnimation(String text, TextLayerStyle style, double progress) {
    switch (style.animationPreset) {
      case TextAnimationPreset.typewriter:
        final visible = (text.length * progress).floor().clamp(0, text.length);
        return text.substring(0, visible);
      case TextAnimationPreset.karaokeRTL:
        // Returns highlighted portion (full text; highlight handled separately)
        return text;
      default:
        return text;
    }
  }

  @override
  bool shouldRepaint(covariant TextClipPainter old) {
    return old.layer != layer ||
        old.playheadProgress != playheadProgress ||
        old.currentTime != currentTime;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font Size Auto-Computer
// ─────────────────────────────────────────────────────────────────────────────

double computeOptimalFontSize({
  required String text,
  required String fontFamily,
  required double maxWidth,
  required double maxHeight,
  double initialFontSize = 60,
}) {
  double fontSize = initialFontSize;
  while (fontSize >= 12) {
    final style = TextLayerStyle(fontFamily: fontFamily, fontSize: fontSize);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style.toFlutterTextStyle()),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    if (tp.height <= maxHeight) break;
    fontSize -= 2;
  }
  return fontSize;
}
