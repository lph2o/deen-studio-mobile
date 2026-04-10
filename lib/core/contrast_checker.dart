import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/text_layer_style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WCAG 2.1 AA Contrast Checker
// ─────────────────────────────────────────────────────────────────────────────

class ContrastChecker {
  /// Compute WCAG 2.1 relative luminance of a Color.
  static double relativeLuminance(Color c) {
    double linearize(int v) {
      final s = v / 255.0;
      return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }
    final r = linearize((c.r * 255.0).round().clamp(0, 255));
    final g = linearize((c.g * 255.0).round().clamp(0, 255));
    final b = linearize((c.b * 255.0).round().clamp(0, 255));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Compute WCAG 2.1 contrast ratio between foreground and background.
  static double contrastRatio(Color fg, Color bg) {
    final l1 = relativeLuminance(fg) + 0.05;
    final l2 = relativeLuminance(bg) + 0.05;
    return l1 > l2 ? l1 / l2 : l2 / l1;
  }

  /// Returns true if the contrast meets WCAG AA (4.5:1 for normal text).
  static bool meetsAA(Color fg, Color bg) => contrastRatio(fg, bg) >= 4.5;

  /// Returns true if the contrast meets WCAG AAA (7:1 for normal text).
  static bool meetsAAA(Color fg, Color bg) => contrastRatio(fg, bg) >= 7.0;

  /// Returns a color to indicate compliance level.
  static Color complianceColor(Color fg, Color bg) {
    final ratio = contrastRatio(fg, bg);
    if (ratio >= 7.0) return const Color(0xFF22c55e);  // Green - AAA
    if (ratio >= 4.5) return const Color(0xFF84cc16);  // Lime - AA
    if (ratio >= 3.0) return const Color(0xFFf97316);  // Orange - AA Large
    return const Color(0xFFef4444);                    // Red - Fail
  }

  /// Returns a label for the compliance level.
  static String complianceLabel(Color fg, Color bg) {
    final ratio = contrastRatio(fg, bg);
    if (ratio >= 7.0) return 'AAA ✓';
    if (ratio >= 4.5) return 'AA ✓';
    if (ratio >= 3.0) return 'Texte Large';
    return 'Insuffisant';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color Parser Helper
// ─────────────────────────────────────────────────────────────────────────────

Color parseHexColor(String hex, {Color fallback = Colors.white}) {
  return TextLayerStyle.parseHexColor(hex);
}

String colorToHex(Color c) {
  return '#${(c.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(c.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(c.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
}
