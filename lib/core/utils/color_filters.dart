import 'dart:math' as math;

class ColorMatrixUtils {
  static const List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // ─── Matrix Operations ───────────────────────────────────────────────────

  /// Multiplies two 4×5 ColorFilter matrices.
  static List<double> multiply(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) sum += a[i * 5 + 4];
        result[i * 5 + j] = sum;
      }
    }
    return result;
  }

  // ─── Dynamic Adjustments ─────────────────────────────────────────────────

  /// Brightness: -1.0 (black) → 0 (neutral) → 1.0 (white)
  static List<double> brightness(double value) {
    final b = value * 255.0;
    return [1.0, 0, 0, 0, b,  0, 1.0, 0, 0, b,  0, 0, 1.0, 0, b,  0, 0, 0, 1.0, 0];
  }

  /// Contrast: -1.0 (low) → 0 (neutral) → 1.0 (high)
  static List<double> contrast(double value) {
    final s = value + 1.0;
    final o = 128.0 * (1.0 - s);
    return [s, 0, 0, 0, o,  0, s, 0, 0, o,  0, 0, s, 0, o,  0, 0, 0, 1.0, 0];
  }

  /// Saturation: 0.0 (grayscale) → 1.0 (neutral) → 2.0+ (high)
  static List<double> saturation(double value) {
    final inv = 1.0 - value;
    final r = 0.213 * inv;
    final g = 0.715 * inv;
    final b = 0.072 * inv;
    return [
      r + value, g, b, 0, 0,
      r, g + value, b, 0, 0,
      r, g, b + value, 0, 0,
      0, 0, 0, 1.0, 0,
    ];
  }

  /// Hue rotation: -180.0 to 180.0 degrees
  static List<double> hue(double degrees) {
    final double radians = degrees * math.pi / 180.0;
    final double cosA = math.cos(radians);
    final double sinA = math.sin(radians);
    
    // Standard RGB to YIQ and back approximation
    final double r1 = 0.213 + cosA * 0.787 - sinA * 0.213;
    final double r2 = 0.715 - cosA * 0.715 - sinA * 0.715;
    final double r3 = 0.072 - cosA * 0.072 + sinA * 0.928;

    final double g1 = 0.213 - cosA * 0.213 + sinA * 0.143;
    final double g2 = 0.715 + cosA * 0.285 + sinA * 0.140;
    final double g3 = 0.072 - cosA * 0.072 - sinA * 0.283;

    final double b1 = 0.213 - cosA * 0.213 - sinA * 0.787;
    final double b2 = 0.715 - cosA * 0.715 + sinA * 0.715;
    final double b3 = 0.072 + cosA * 0.928 + sinA * 0.072;

    return [
      r1, r2, r3, 0, 0,
      g1, g2, g3, 0, 0,
      b1, b2, b3, 0, 0,
      0,  0,  0,  1, 0,
    ];
  }

  /// Parses hex color to RGB (0.0 to 1.0)
  static List<double> _hexToRgb(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return [
        int.parse(hex.substring(0, 2), radix: 16) / 255.0,
        int.parse(hex.substring(2, 4), radix: 16) / 255.0,
        int.parse(hex.substring(4, 6), radix: 16) / 255.0,
      ];
    }
    return [0.5, 0.5, 0.5]; // default gray
  }

  /// Approximates 3-way color wheels using a single linear matrix.
  static List<double> colorWheels({
    required String shadowsTint,
    required double shadowsAmount,
    required String midtonesTint,
    required double midtonesAmount,
    required String highlightsTint,
    required double highlightsAmount,
  }) {
    final s = _hexToRgb(shadowsTint);
    final m = _hexToRgb(midtonesTint);
    final h = _hexToRgb(highlightsTint);
    
    // Calculate offsets (-0.5 means center gray contributes 0)
    final sR = (s[0] - 0.5) * shadowsAmount * 2.0;
    final sG = (s[1] - 0.5) * shadowsAmount * 2.0;
    final sB = (s[2] - 0.5) * shadowsAmount * 2.0;
    
    final mR = (m[0] - 0.5) * midtonesAmount * 2.0;
    final mG = (m[1] - 0.5) * midtonesAmount * 2.0;
    final mB = (m[2] - 0.5) * midtonesAmount * 2.0;
    
    final hR = (h[0] - 0.5) * highlightsAmount * 2.0;
    final hG = (h[1] - 0.5) * highlightsAmount * 2.0;
    final hB = (h[2] - 0.5) * highlightsAmount * 2.0;

    // Approximated gain
    final gainR = 1.0 + hR + (mR * 0.5);
    final gainG = 1.0 + hG + (mG * 0.5);
    final gainB = 1.0 + hB + (mB * 0.5);
    
    // Approximated offset (in 0-255 scale)
    final offsetR = (sR * 0.8 + mR * 0.2) * 255.0;
    final offsetG = (sG * 0.8 + mG * 0.2) * 255.0;
    final offsetB = (sB * 0.8 + mB * 0.2) * 255.0;

    return [
      gainR, 0, 0, 0, offsetR,
      0, gainG, 0, 0, offsetG,
      0, 0, gainB, 0, offsetB,
      0, 0, 0,     1, 0,
    ];
  }

  /// Approximates a curve using linear regression (least squares fit).
  static List<double> curveApproximation(List<dynamic> curvePoints, {int? channelIndex}) {
    if (curvePoints.isEmpty) return identity;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final p in curvePoints) {
      sumX += p.x;
      sumY += p.y;
      sumXY += p.x * p.y;
      sumX2 += p.x * p.x;
    }
    final n = curvePoints.length;
    double denominator = (n * sumX2 - sumX * sumX);
    double m = 1.0;
    double b = 0.0;
    if (denominator != 0) {
      m = (n * sumXY - sumX * sumY) / denominator;
      b = (sumY - m * sumX) / n;
    }

    if (channelIndex != null) {
      final result = List<double>.from(identity);
      result[channelIndex * 5 + channelIndex] = m;
      result[channelIndex * 5 + 4] = b * 255.0;
      return result;
    } else {
      return [
        m, 0, 0, 0, b * 255.0,
        0, m, 0, 0, b * 255.0,
        0, 0, m, 0, b * 255.0,
        0, 0, 0, 1, 0,
      ];
    }
  }

  // ─── Preset Filters ───────────────────────────────────────────────────────

  static const List<double> grayscalePreset = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> sepiaPreset = [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // Warm: boost reds, reduce blues
  static final List<double> warmPreset = multiply(
    brightness(0.05),
    const <double>[1.2, 0, 0, 0, 0,   0, 1.0, 0, 0, 0,   0, 0, 0.8, 0, 0,   0, 0, 0, 1.0, 0],
  );

  // Cool: boost blues, reduce reds
  static final List<double> coolPreset = multiply(
    brightness(0.02),
    const <double>[0.85, 0, 0, 0, 0,  0, 0.95, 0, 0, 0,  0, 0, 1.2, 0, 0,  0, 0, 0, 1.0, 0],
  );

  // Vintage: desaturate + warm tone + slight overexposure
  static final List<double> vintagePreset = multiply(
    saturation(0.6),
    multiply(
      brightness(0.08),
      const <double>[1.1, 0.05, 0, 0, 5.0,  0.05, 1.0, 0, 0, 5.0,  0, 0, 0.8, 0, 0,  0, 0, 0, 1.0, 0],
    ),
  );

  // Vivid: boost saturation + slight contrast
  static final List<double> vividPreset = multiply(
    saturation(1.6),
    contrast(0.15),
  );

  // Faded: desaturate + slight brightness lift
  static final List<double> fadePreset = multiply(
    saturation(0.7),
    brightness(0.12),
  );

  // ─── Lookup by filter ID ──────────────────────────────────────────────────

  static List<double> forId(String filterId) {
    switch (filterId) {
      case 'grayscale': return grayscalePreset;
      case 'sepia':     return sepiaPreset;
      case 'warm':      return warmPreset;
      case 'cool':      return coolPreset;
      case 'vintage':   return vintagePreset;
      case 'vivid':     return vividPreset;
      case 'fade':      return fadePreset;
      default:          return identity;
    }
  }
}
