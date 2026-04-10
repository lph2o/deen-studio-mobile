import 'package:flutter/material.dart';
import '../models/text_layer_style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text Style Preset
// ─────────────────────────────────────────────────────────────────────────────

class TextStylePreset {
  final String id;
  final String name;
  final String category;  // 'tendance', 'general', 'colore', 'musulman'
  final TextLayerStyle style;

  const TextStylePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.style,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'style': style.toMap(),
  };

  factory TextStylePreset.fromMap(Map<String, dynamic> m) => TextStylePreset(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    category: m['category'] ?? 'general',
    style: TextLayerStyle.fromMap(m['style'] ?? {}),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Built-in Presets Catalogue
// ─────────────────────────────────────────────────────────────────────────────

final List<TextStylePreset> kBuiltInPresets = [
  // ── Tendance ──────────────────────────────────────────────────────────────
  TextStylePreset(
    id: 'neon_glow',
    name: 'Neon Glow',
    category: 'tendance',
    style: const TextLayerStyle(
      fontFamily: 'Anton',
      fontSize: 48,
      isBold: true,
      color: '#FFFFFF',
      shadowColor: '#ec4899',
      shadowBlur: 20.0,
      letterSpacing: 2,
    ),
  ),
  TextStylePreset(
    id: 'retro_wave',
    name: 'Retro Wave',
    category: 'tendance',
    style: const TextLayerStyle(
      fontFamily: 'Righteous',
      fontSize: 44,
      color: '#fef08a',
      shadowColor: '#06b6d4',
      shadowOffsetX: 4,
      shadowOffsetY: 4,
      shadowBlur: 5,
    ),
  ),
  TextStylePreset(
    id: 'electric_blue',
    name: 'Electric Blue',
    category: 'tendance',
    style: const TextLayerStyle(
      fontFamily: 'Montserrat',
      fontSize: 44,
      isBold: true,
      color: '#3b82f6',
      shadowColor: '#3b82f6',
      shadowBlur: 20.0,
      letterSpacing: 8,
    ),
  ),
  TextStylePreset(
    id: 'warm_script',
    name: 'Warm Script',
    category: 'tendance',
    style: const TextLayerStyle(
      fontFamily: 'Pacifico',
      fontSize: 40,
      color: '#fdba74',
      shadowColor: '#f97316',
      shadowBlur: 15,
    ),
  ),

  // ── Général ───────────────────────────────────────────────────────────────
  TextStylePreset(
    id: 'military',
    name: 'Military',
    category: 'general',
    style: const TextLayerStyle(
      fontFamily: 'Black Ops One',
      fontSize: 44,
      color: '#84cc16',
      shadowColor: '#1a2e05',
      shadowBlur: 8,
      shadowOffsetY: 4,
      letterSpacing: 4,
    ),
  ),
  TextStylePreset(
    id: 'cinematic_gold',
    name: 'Cinematic Gold',
    category: 'general',
    style: const TextLayerStyle(
      fontFamily: 'Cinzel',
      fontSize: 42,
      isBold: true,
      color: '#facc15',
      shadowColor: '#000000',
      shadowBlur: 12,
      shadowOffsetY: 4,
      letterSpacing: 10,
    ),
  ),
  TextStylePreset(
    id: 'industrial',
    name: 'Industrial',
    category: 'general',
    style: const TextLayerStyle(
      fontFamily: 'Anton',
      fontSize: 48,
      color: '#e5e5e5',
      shadowColor: '#000000',
      shadowBlur: 16,
      shadowOffsetY: 6,
      letterSpacing: 15,
    ),
  ),
  TextStylePreset(
    id: 'subtitle_basic',
    name: 'Subtitle',
    category: 'general',
    style: const TextLayerStyle(
      fontFamily: 'Anton',
      fontSize: 40,
      color: '#FFFFFF',
      strokeColor: '#000000',
      strokeWidth: 8.0,
    ),
  ),

  // ── Coloré ────────────────────────────────────────────────────────────────
  TextStylePreset(
    id: 'techno',
    name: 'Techno',
    category: 'colore',
    style: const TextLayerStyle(
      fontFamily: 'Space Grotesk',
      fontSize: 44,
      isBold: true,
      color: '#e2e8f0',
      shadowColor: '#3b82f6',
      shadowBlur: 18,
      letterSpacing: 20,
    ),
  ),
  TextStylePreset(
    id: 'horror',
    name: 'Horror',
    category: 'colore',
    style: const TextLayerStyle(
      fontFamily: 'Creepster',
      fontSize: 48,
      color: '#ef4444',
      shadowColor: '#450a0a',
      shadowBlur: 12,
      shadowOffsetY: 4,
    ),
  ),
  TextStylePreset(
    id: 'mystic',
    name: 'Mystic',
    category: 'colore',
    style: const TextLayerStyle(
      fontFamily: 'Cinzel',
      fontSize: 42,
      color: '#c084fc',
      shadowColor: '#ffffff',
      shadowBlur: 15,
    ),
  ),
  TextStylePreset(
    id: 'bold_minimal',
    name: 'Bold Minimal',
    category: 'colore',
    style: const TextLayerStyle(
      fontFamily: 'Inter',
      fontSize: 48,
      isBold: true,
      fontWeight: FontWeight.w800,
      color: '#000000',
      backgroundColor: '#FFFFFF',
    ),
  ),

  // ── Musulman (Arabic) ─────────────────────────────────────────────────────
  TextStylePreset(
    id: 'quran_classic',
    name: 'Coranique',
    category: 'musulman',
    style: const TextLayerStyle(
      fontFamily: 'UthmanicRegular',
      fontSize: 52,
      color: '#FFFFFF',
      shadowColor: '#000000',
      shadowBlur: 8,
      isRTL: true,
    ),
  ),
  TextStylePreset(
    id: 'arabic_gold',
    name: 'Or Arabe',
    category: 'musulman',
    style: const TextLayerStyle(
      fontFamily: 'Amiri',
      fontSize: 48,
      color: '#facc15',
      shadowColor: '#000000',
      shadowBlur: 12,
      isRTL: true,
    ),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Preview Renderer — builds a Widget thumbnail for a preset
// ─────────────────────────────────────────────────────────────────────────────

class PresetPreviewPainter extends CustomPainter {
  final TextStylePreset preset;

  const PresetPreviewPainter(this.preset);

  @override
  void paint(Canvas canvas, Size size) {
    final s = preset.style;
    final text = preset.name;

    // Background
    final bgPaint = Paint()
      ..color = s.backgroundColor != null
          ? TextLayerStyle.parseHexColor(s.backgroundColor!)
          : const Color(0xFF1a1a2e);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Build text style with scaled-down font
    const scaleFactor = 0.28;
    final flutterStyle = s.toFlutterTextStyle().copyWith(fontSize: s.fontSize * scaleFactor);

    // Shadow
    if (s.shadowBlur > 0 || s.shadowOffsetX != 0 || s.shadowOffsetY != 0) {
      final shadowPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: flutterStyle.copyWith(
            color: TextLayerStyle.parseHexColor(s.shadowColor),
            shadows: [
              Shadow(
                color: TextLayerStyle.parseHexColor(s.shadowColor),
                blurRadius: s.shadowBlur * scaleFactor,
                offset: Offset(s.shadowOffsetX * scaleFactor, s.shadowOffsetY * scaleFactor),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width * 0.9);
      final pos = Offset((size.width - shadowPainter.width) / 2, (size.height - shadowPainter.height) / 2);
      shadowPainter.paint(canvas, pos);
    }

    // Stroke
    if (s.strokeWidth > 0) {
      final strokePainter = TextPainter(
        text: TextSpan(
          text: text,
          style: flutterStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = s.strokeWidth * scaleFactor
              ..color = TextLayerStyle.parseHexColor(s.strokeColor),
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width * 0.9);
      final pos = Offset((size.width - strokePainter.width) / 2, (size.height - strokePainter.height) / 2);
      strokePainter.paint(canvas, pos);
    }

    // Main text
    if (s.gradientStyle != null) {
      final grad = LinearGradient(
        colors: s.gradientStyle!.colors.map(TextLayerStyle.parseHexColor).toList(),
        transform: GradientRotation(s.gradientStyle!.angleRadians),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: flutterStyle.copyWith(
            foreground: Paint()
              ..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width * 0.9);
      final pos = Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2);
      tp.paint(canvas, pos);
    } else {
      final tp = TextPainter(
        text: TextSpan(text: text, style: flutterStyle),
        textDirection: s.isRTL ? TextDirection.rtl : TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width * 0.9);
      final pos = Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2);
      tp.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(covariant PresetPreviewPainter old) => old.preset.id != preset.id;
}
