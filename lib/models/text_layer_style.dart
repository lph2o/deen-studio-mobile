import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text Animation Preset Enum
// ─────────────────────────────────────────────────────────────────────────────

enum TextAnimationPreset {
  none,
  fadeIn,
  fadeOut,
  fadeInOut,
  slideInLeft,
  slideInRight,
  slideInTop,
  slideInBottom,
  typewriter,
  bounceIn,
  scaleIn,
  scaleOut,
  glitchIn,
  karaokeRTL,
  wordByWord,
  wordHighlight,
}

extension TextAnimationPresetExtension on TextAnimationPreset {
  String get id => name;

  double get defaultDuration {
    switch (this) {
      case TextAnimationPreset.typewriter:
      case TextAnimationPreset.wordByWord:
      case TextAnimationPreset.wordHighlight:
        return 2.0;
      case TextAnimationPreset.bounceIn:
      case TextAnimationPreset.scaleIn:
      case TextAnimationPreset.scaleOut:
        return 0.8;
      case TextAnimationPreset.glitchIn:
        return 1.2;
      case TextAnimationPreset.karaokeRTL:
        return 3.0;
      default:
        return 1.0;
    }
  }
}

extension TextAnimationPresetExt on TextAnimationPreset {
  String get label {
    switch (this) {
      case TextAnimationPreset.none: return 'Aucune';
      case TextAnimationPreset.fadeIn: return 'Apparition';
      case TextAnimationPreset.fadeOut: return 'Disparition';
      case TextAnimationPreset.fadeInOut: return 'Fondu enchaîné';
      case TextAnimationPreset.slideInLeft: return 'Glisser depuis gauche';
      case TextAnimationPreset.slideInRight: return 'Glisser depuis droite';
      case TextAnimationPreset.slideInTop: return 'Glisser depuis haut';
      case TextAnimationPreset.slideInBottom: return 'Glisser depuis bas';
      case TextAnimationPreset.typewriter: return 'Machine à écrire';
      case TextAnimationPreset.bounceIn: return 'Rebond';
      case TextAnimationPreset.scaleIn: return 'Zoom entrant';
      case TextAnimationPreset.scaleOut: return 'Zoom sortant';
      case TextAnimationPreset.glitchIn: return 'Glitch';
      case TextAnimationPreset.karaokeRTL: return 'Karaoké (RTL)';
      case TextAnimationPreset.wordByWord: return 'Mot par mot';
      case TextAnimationPreset.wordHighlight: return 'Surligné mot';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient Style
// ─────────────────────────────────────────────────────────────────────────────

class GradientTextStyle {
  final List<String> colors;     // hex strings
  final double angleRadians;

  const GradientTextStyle({
    this.colors = const ['#FF6B6B', '#4ECDC4'],
    this.angleRadians = 0.0,
  });

  GradientTextStyle copyWith({List<String>? colors, double? angleRadians}) =>
      GradientTextStyle(
        colors: colors ?? this.colors,
        angleRadians: angleRadians ?? this.angleRadians,
      );

  factory GradientTextStyle.fromMap(Map<String, dynamic> m) => GradientTextStyle(
    colors: List<String>.from(m['colors'] ?? ['#FF6B6B', '#4ECDC4']),
    angleRadians: (m['angleRadians'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {'colors': colors, 'angleRadians': angleRadians};
}

// ─────────────────────────────────────────────────────────────────────────────
// TextLayerStyle — Full rich text style model
// ─────────────────────────────────────────────────────────────────────────────

class TextLayerStyle {
  // Font
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isUppercase;
  final bool isBold;
  final bool isItalic;

  // Colors
  final String color;              // hex
  final String? backgroundColor;  // hex or null
  final GradientTextStyle? gradientStyle;

  // Stroke
  final String strokeColor;
  final double strokeWidth;

  // Shadow
  final String shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;

  // Spacing
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;

  // Alignment & Direction
  final TextAlign textAlign;
  final bool isRTL;

  // Decorations
  final bool underline;
  final bool strikethrough;

  // Animation
  final TextAnimationPreset animationPreset;
  final double animationInDuration;   // seconds
  final double animationOutDuration;  // seconds
  final String quranAnimationId;      // ID of selected Quran animation

  // Opacity (0.0-1.0)
  final double opacity;

  const TextLayerStyle({
    this.fontFamily = 'Inter',
    this.fontSize = 40,
    this.fontWeight = FontWeight.normal,
    this.isUppercase = false,
    this.isBold = false,
    this.isItalic = false,
    this.color = '#FFFFFF',
    this.backgroundColor,
    this.gradientStyle,
    this.strokeColor = '#000000',
    this.strokeWidth = 0.0,
    this.shadowColor = '#000000',
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.lineHeight = 1.2,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.textAlign = TextAlign.center,
    this.isRTL = false,
    this.underline = false,
    this.strikethrough = false,
    this.animationPreset = TextAnimationPreset.none,
    this.animationInDuration = 1.0,
    this.animationOutDuration = 0.5,
    this.quranAnimationId = '',
    this.opacity = 1.0,
  });

  TextLayerStyle copyWith({
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    bool? isUppercase,
    bool? isBold,
    bool? isItalic,
    String? color,
    String? backgroundColor,
    bool clearBackground = false,
    GradientTextStyle? gradientStyle,
    bool clearGradient = false,
    String? strokeColor,
    double? strokeWidth,
    String? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    TextAlign? textAlign,
    bool? isRTL,
    bool? underline,
    bool? strikethrough,
    TextAnimationPreset? animationPreset,
    double? animationInDuration,
    double? animationOutDuration,
    String? quranAnimationId,
    double? opacity,
  }) {
    return TextLayerStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      isUppercase: isUppercase ?? this.isUppercase,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      color: color ?? this.color,
      backgroundColor: clearBackground ? null : (backgroundColor ?? this.backgroundColor),
      gradientStyle: clearGradient ? null : (gradientStyle ?? this.gradientStyle),
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      textAlign: textAlign ?? this.textAlign,
      isRTL: isRTL ?? this.isRTL,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      animationPreset: animationPreset ?? this.animationPreset,
      animationInDuration: animationInDuration ?? this.animationInDuration,
      animationOutDuration: animationOutDuration ?? this.animationOutDuration,
      quranAnimationId: quranAnimationId ?? this.quranAnimationId,
      opacity: opacity ?? this.opacity,
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  factory TextLayerStyle.fromMap(Map<String, dynamic> m) {
    return TextLayerStyle(
      fontFamily: m['fontFamily'] ?? 'Inter',
      fontSize: (m['fontSize'] ?? 40).toDouble(),
      fontWeight: _parseFontWeight(m['fontWeight']),
      isUppercase: m['isUppercase'] ?? false,
      isBold: m['isBold'] ?? false,
      isItalic: m['isItalic'] ?? false,
      color: m['color'] ?? '#FFFFFF',
      backgroundColor: m['backgroundColor'],
      gradientStyle: m['gradientStyle'] != null ? GradientTextStyle.fromMap(m['gradientStyle']) : null,
      strokeColor: m['strokeColor'] ?? '#000000',
      strokeWidth: (m['strokeWidth'] ?? 0.0).toDouble(),
      shadowColor: m['shadowColor'] ?? '#000000',
      shadowBlur: (m['shadowBlur'] ?? 0.0).toDouble(),
      shadowOffsetX: (m['shadowOffsetX'] ?? 0.0).toDouble(),
      shadowOffsetY: (m['shadowOffsetY'] ?? 0.0).toDouble(),
      lineHeight: (m['lineHeight'] ?? 1.2).toDouble(),
      letterSpacing: (m['letterSpacing'] ?? 0.0).toDouble(),
      wordSpacing: (m['wordSpacing'] ?? 0.0).toDouble(),
      textAlign: _parseTextAlign(m['textAlign']),
      isRTL: m['isRTL'] ?? false,
      underline: m['underline'] ?? false,
      strikethrough: m['strikethrough'] ?? false,
      animationPreset: _parseAnimationPreset(m['animationPreset']),
      animationInDuration: (m['animationInDuration'] ?? 1.0).toDouble(),
      animationOutDuration: (m['animationOutDuration'] ?? 0.5).toDouble(),
      quranAnimationId: m['quranAnimationId'] ?? '',
      opacity: (m['opacity'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
      'isUppercase': isUppercase,
      'isBold': isBold,
      'isItalic': isItalic,
      'color': color,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (gradientStyle != null) 'gradientStyle': gradientStyle!.toMap(),
      'strokeColor': strokeColor,
      'strokeWidth': strokeWidth,
      'shadowColor': shadowColor,
      'shadowBlur': shadowBlur,
      'shadowOffsetX': shadowOffsetX,
      'shadowOffsetY': shadowOffsetY,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'wordSpacing': wordSpacing,
      'textAlign': textAlign.index,
      'isRTL': isRTL,
      'underline': underline,
      'strikethrough': strikethrough,
      'animationPreset': animationPreset.index,
      'animationInDuration': animationInDuration,
      'animationOutDuration': animationOutDuration,
      'quranAnimationId': quranAnimationId,
      'opacity': opacity,
    };
  }

  // ── Flutter Style Builder ──────────────────────────────────────────────────

  TextStyle toFlutterTextStyle({Color? overrideColor}) {
    final fontWeightResolved = isBold ? FontWeight.w700 : fontWeight;
    final decoration = _buildDecoration();

    List<Shadow>? textShadows;
    if (shadowColor.isNotEmpty && (shadowBlur > 0 || shadowOffsetX != 0 || shadowOffsetY != 0)) {
       textShadows = [
         Shadow(
           color: parseHexColor(shadowColor).withValues(alpha: opacity),
           blurRadius: shadowBlur,
           offset: Offset(shadowOffsetX, shadowOffsetY),
         )
       ];
    }

    Paint? foregroundPaint;
    Color? finalColor;
    
    if (gradientStyle != null) {
      // NOTE: For gradients, the shader bounds depend on the drawn text rect.
      // Since toFlutterTextStyle doesn't know the exact rect, it falls back to a large rect.
      // A more precise shader would require a ShaderMask, but this works for basic linear gradients.
      final gradient = LinearGradient(
        colors: gradientStyle!.colors.map(parseHexColor).toList(),
        transform: GradientRotation(gradientStyle!.angleRadians),
      );
      foregroundPaint = Paint()
        ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 1000, 100)); // approximate bounds
    } else {
      finalColor = overrideColor ?? parseHexColor(color).withValues(alpha: opacity);
    }

    return TextStyle(
      fontFamily: _isGoogleFont(fontFamily) ? null : fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeightResolved,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      color: foregroundPaint == null ? finalColor : null,
      foreground: foregroundPaint,
      backgroundColor: backgroundColor != null ? parseHexColor(backgroundColor!).withValues(alpha: opacity) : null,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: lineHeight,
      decoration: decoration,
      decorationColor: parseHexColor(color).withValues(alpha: opacity),
      shadows: textShadows,
    );
  }

  TextDecoration _buildDecoration() {
    if (underline && strikethrough) {
      return TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]);
    }
    if (underline) return TextDecoration.underline;
    if (strikethrough) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _isGoogleFont(String family) {
    return !FontCatalogue.isLocal(family);
  }

  static Color parseHexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.white;
  }

  static FontWeight _parseFontWeight(dynamic v) {
    if (v == null) return FontWeight.normal;
    if (v is int) return FontWeight.values[v.clamp(0, FontWeight.values.length - 1)];
    return FontWeight.normal;
  }

  static TextAlign _parseTextAlign(dynamic v) {
    if (v == null) return TextAlign.center;
    if (v is int) return TextAlign.values[v.clamp(0, TextAlign.values.length - 1)];
    return TextAlign.center;
  }

  static TextAnimationPreset _parseAnimationPreset(dynamic v) {
    if (v == null) return TextAnimationPreset.none;
    if (v is int) return TextAnimationPreset.values[v.clamp(0, TextAnimationPreset.values.length - 1)];
    return TextAnimationPreset.none;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font Catalogue
// ─────────────────────────────────────────────────────────────────────────────

class FontCatalogue {
  static const Map<String, List<String>> groups = {
    'Populaires': ['Inter', 'Poppins', 'Montserrat', 'Roboto', 'Roboto-Medium', 'Open Sans', 'Lato', 'DM Sans'],
    'Display': ['Bebas Neue', 'Anton', 'Oswald', 'Teko', 'Staatliches', 'Alfa Slab One', 'Black Ops One', 'Righteous'],
    'Élégantes': ['Playfair Display', 'Cinzel', 'Lora', 'Merriweather', 'DM Serif Display'],
    'Manuscrites': ['Pacifico', 'Lobster', 'Dancing Script', 'Caveat', 'Permanent Marker', 'Creepster'],
    'Techniques': ['Space Grotesk', 'Space Mono', 'JetBrains Mono', 'Tinos'],
    'Arabe': [
      'AlMajeed', 'Amiri-Quran', 'Amiri', 'Jameel', 'KufamRegular', 'KufamVariable', 
      'Me', 'Naskh', 'Noore', 'QuranFont', 'UthmanTN_v2-0', 'UthmanicBold', 
      'UthmanicHafs_V20', 'UthmanicRegular', 'UthmanicRegular2', 
      'Scheherazade New', 'Noto Naskh Arabic', 'Cairo', 'Tajawal'
    ],
    'Multilingue': ['Noto Sans', 'Quicksand'],
  };

  static const Set<String> arabicFonts = {
    'AlMajeed', 'Amiri-Quran', 'Amiri', 'Jameel', 'KufamRegular', 'KufamVariable', 
    'Me', 'Naskh', 'Noore', 'QuranFont', 'UthmanTN_v2-0', 'UthmanicBold', 
    'UthmanicHafs_V20', 'UthmanicRegular', 'UthmanicRegular2', 
    'Scheherazade New', 'Noto Naskh Arabic', 'Cairo', 'Tajawal'
  };

  static const Set<String> localFonts = {
    'AlMajeed', 'Amiri-Quran', 'Jameel', 'KufamRegular', 'KufamVariable', 'Me', 
    'Naskh', 'Noore', 'QuranFont', 'Roboto-Medium', 'Tinos', 'UthmanTN_v2-0', 
    'UthmanicBold', 'UthmanicHafs_V20', 'UthmanicRegular', 'UthmanicRegular2'
  };

  static bool isArabic(String font) => arabicFonts.contains(font);
  static bool isLocal(String font) => localFonts.contains(font);
}
