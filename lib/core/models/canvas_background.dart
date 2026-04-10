import 'package:flutter/material.dart';

class CanvasBackground {
  final String id;
  final String name;
  final String type; // 'solid', 'gradient', 'blur'
  final String color1;
  final String color2;
  final double angle; // degrees for gradient

  const CanvasBackground({
    required this.id,
    required this.name,
    required this.type,
    this.color1 = '#000000',
    this.color2 = '#000000',
    this.angle = 0.0,
  });

  /// Parse a hex color string (#RRGGBB) to a Flutter Color.
  Color getColor1() => _parseColor(color1);
  Color getColor2() => _parseColor(color2);

  static Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  /// Build a Widget that renders this background.
  Widget buildBackground({Widget? child}) {
    switch (type) {
      case 'solid':
        return Container(color: getColor1(), child: child);
      case 'gradient':
        final angleRad = angle * 3.14159 / 180;
        final beginX = -cos(angleRad);
        final beginY = -sin(angleRad);
        final endX = cos(angleRad);
        final endY = sin(angleRad);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(beginX, beginY),
              end: Alignment(endX, endY),
              colors: [getColor1(), getColor2()],
            ),
          ),
          child: child,
        );
      case 'blur':
        // Blur type: rendered as a special case in video_preview.dart
        // by blurring the first visual layer. Returns a transparent container here.
        return Container(color: Colors.transparent, child: child);
      default:
        return Container(color: Colors.black, child: child);
    }
  }
}

const kCanvasBackgrounds = [
  CanvasBackground(id: 'black', name: 'Noir', type: 'solid', color1: '#000000'),
  CanvasBackground(id: 'white', name: 'Blanc', type: 'solid', color1: '#FFFFFF'),
  CanvasBackground(id: 'blur', name: 'Flou', type: 'blur'),
  CanvasBackground(id: 'gradient_dark', name: 'Sombre', type: 'gradient', color1: '#1a1a2e', color2: '#16213e'),
  CanvasBackground(id: 'gradient_warm', name: 'Chaud', type: 'gradient', color1: '#ff6b6b', color2: '#feca57'),
  CanvasBackground(id: 'gradient_cool', name: 'Froid', type: 'gradient', color1: '#4facfe', color2: '#00f2fe'),
  CanvasBackground(id: 'gradient_purple', name: 'Violet', type: 'gradient', color1: '#667eea', color2: '#764ba2'),
  CanvasBackground(id: 'gradient_sunset', name: 'Sunset', type: 'gradient', color1: '#fa709a', color2: '#fee140'),
];

// Helper math functions since we can't import dart:math in a const context
double cos(double x) {
  // Taylor series approximation for cos
  double result = 0;
  for (int n = 0; n < 10; n++) {
    result += (n % 2 == 0 ? 1 : -1) * _pow(x, 2 * n) / _factorial(2 * n);
  }
  return result;
}

double sin(double x) {
  double result = 0;
  for (int n = 0; n < 10; n++) {
    result += (n % 2 == 0 ? 1 : -1) * _pow(x, 2 * n + 1) / _factorial(2 * n + 1);
  }
  return result;
}

double _pow(double base, int exp) {
  double result = 1;
  for (int i = 0; i < exp; i++) {
    result *= base;
  }
  return result;
}

int _factorial(int n) {
  if (n <= 1) return 1;
  int result = 1;
  for (int i = 2; i <= n; i++) {
    result *= i;
  }
  return result;
}
