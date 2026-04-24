import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:deen_studio_01/models/text_layer_style.dart';

/// Paints deformed glyph slices so the animation affects the text itself.
class GlyphDeformationText extends StatelessWidget {
  final TextSpan text;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final String animationId;
  final double progress;
  final AnimationConfig config;

  const GlyphDeformationText({
    super.key,
    required this.text,
    required this.textAlign,
    required this.textDirection,
    required this.animationId,
    required this.progress,
    this.config = const AnimationConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final textPainter = TextPainter(
          text: text,
          textDirection: textDirection,
          textAlign: textAlign,
          maxLines: null,
        )..layout(maxWidth: maxWidth);

        return SizedBox(
          width: maxWidth,
          height: textPainter.height,
          child: CustomPaint(
            painter: _GlyphDeformationPainter(
              text: text,
              textAlign: textAlign,
              textDirection: textDirection,
              animationId: animationId,
              progress: progress.clamp(0.0, 1.0),
              config: config,
            ),
          ),
        );
      },
    );
  }
}

class _GlyphDeformationPainter extends CustomPainter {
  final TextSpan text;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final String animationId;
  final double progress;
  final AnimationConfig config;

  const _GlyphDeformationPainter({
    required this.text,
    required this.textAlign,
    required this.textDirection,
    required this.animationId,
    required this.progress,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: text,
      textDirection: textDirection,
      textAlign: textAlign,
      maxLines: null,
    )..layout(maxWidth: size.width);

    final sliceCount = ((textPainter.height / 4).round()).clamp(18, 40);
    final sliceHeight = textPainter.height / sliceCount;

    final globalOffset = _globalOffsetFor(animationId, progress, textPainter.height);

    for (int i = 0; i < sliceCount; i++) {
      final y = i * sliceHeight;
      final ny = textPainter.height <= 0
          ? 0.0
          : (y / textPainter.height).clamp(0.0, 1.0);
      final visibility = _sliceVisibilityFor(animationId, progress, ny);
      if (visibility <= 0.0) continue;

      final offset =
          _offsetFor(animationId, progress, y, textPainter.height) + globalOffset;

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, y, size.width, sliceHeight + 1));
      canvas.translate(offset.dx, offset.dy);
      if (visibility < 0.999) {
        canvas.saveLayer(
          Rect.fromLTWH(0, y, size.width, sliceHeight + 1),
          Paint()..color = Colors.white.withValues(alpha: visibility),
        );
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      } else {
        textPainter.paint(canvas, Offset.zero);
      }
      canvas.restore();
    }
  }

  Offset _offsetFor(String id, double t, double y, double textHeight) {
    final phase = t * math.pi * 2;
    final ny = textHeight <= 0 ? 0.0 : (y / textHeight).clamp(0.0, 1.0);
    final intensity = config.intensity * 2.0; // 0.5 default -> 1.0 multiplier
    final freq = config.frequency * 2.0;
    final dirRad = config.direction * math.pi / 180;

    switch (id) {
      case 'sacred_ripple':
        return Offset(
          math.sin((y * 0.06 * freq) + phase * 2.4 + dirRad) * 7.0 * intensity,
          math.sin((y * 0.03 * freq) + phase * 1.8 + dirRad) * 1.2 * intensity,
        );
      case 'mercy_wave':
        final eased = Curves.easeInOut.transform(
          0.5 + 0.5 * math.sin((y * 0.02 * freq) + phase * 1.1 + dirRad),
        );
        return Offset(
          math.sin((y * 0.035 * freq) + phase * 1.2 + dirRad) * (2.2 + 2.0 * eased) * intensity,
          math.sin((y * 0.02 * freq) + phase * 1.0 + dirRad) * 0.55 * intensity,
        );
      case 'river_flow':
        final drift = -6.0 * t * intensity; // continuous drift affected by intensity
        return Offset(
          drift + math.sin((y * 0.05 * freq) + phase * 1.6 + dirRad) * 2.4 * intensity,
          math.cos((y * 0.018 * freq) + phase * 1.0 + dirRad) * 0.45 * intensity,
        );
      case 'ethereal_glow':
        final pulse = (0.6 + 0.4 * math.sin(phase * 1.5)) * intensity;
        return Offset(
          math.sin((y * 0.02 * freq) + phase * 1.1 + dirRad) * (1.3 * pulse),
          math.cos((y * 0.012 * freq) + phase * 0.8 + dirRad) * (0.8 * pulse),
        );
      case 'divine_radiance':
        final center = ny - 0.5;
        final centerDist = center.abs();
        final weight = (1.0 - centerDist * 1.9).clamp(0.0, 1.0) * intensity;
        return Offset(
          center.sign * (2.8 * weight * (0.45 + 0.55 * math.sin(phase + dirRad).abs())),
          math.cos((y * 0.02 * freq) + phase * 1.6 + dirRad) * (0.9 * weight),
        );
      case 'divine_revelation':
        final reveal = Curves.easeOut.transform(t);
        final settle = (1.0 - reveal) * (8.0 + 4.0 * (1.0 - ny)) * intensity;
        return Offset(
          math.sin((y * 0.014 * freq) + phase * 0.7 + dirRad) * (0.8 * reveal * intensity),
          -settle,
        );
      case 'celestial_light':
        final beamY = t; // top -> bottom light sweep
        final distance = (ny - beamY).abs();
        final beam = (1.0 - (distance * 5.0 * freq)).clamp(0.0, 1.0);
        return Offset(
          math.sin((y * 0.01 * freq) + phase + dirRad) * (1.0 + beam * 3.2 * intensity),
          -beam * 1.0 * intensity,
        );
      case 'night_of_power':
        final reveal = Curves.easeInOut.transform(t);
        return Offset(
          math.sin((y * 0.012 * freq) + phase * 0.5 + dirRad) * (0.6 * reveal * intensity),
          (0.5 - ny) * (1.0 - reveal) * 5.5 * intensity,
        );
      case 'lightning':
        final spike = math.sin(phase * 9.0 + dirRad).abs() > 0.93 ? 1.0 : 0.0;
        final bandNoise = _hash01(y * 0.37 * freq + (t * 60).floorToDouble() * 0.19);
        final jagged = (bandNoise * 2.0 - 1.0) * (5.0 * spike * intensity);
        return Offset(
          jagged,
          spike > 0 ? (bandNoise - 0.5) * 1.4 * intensity : 0.0,
        );
      case 'earth_shake':
        final kick = math.sin(phase * 10.0 + dirRad) * 3.0 * intensity;
        final lag = (ny - 0.5) * 0.7 * intensity;
        return Offset(kick + lag, math.sin(phase * 14.0 + ny * 3.0 * freq + dirRad) * 0.35 * intensity);
      case 'galaxy':
        final center = ny - 0.5;
        final radius = (1.0 - center.abs()).clamp(0.0, 1.0);
        final swirl = math.sin((y * 0.028 * freq) + phase * 2.8 + dirRad) * (5.2 * radius * intensity);
        return Offset(swirl, center * (1.6 + 0.6 * math.cos(phase * 1.3 + dirRad)) * intensity);
      default:
        return Offset.zero;
    }
  }

  Offset _globalOffsetFor(String id, double t, double textHeight) {
    final phase = t * math.pi * 2;
    final intensity = config.intensity * 2.0;
    final dirRad = config.direction * math.pi / 180;
    
    switch (id) {
      case 'earth_shake':
        return Offset(math.sin(phase * 12.0 + dirRad) * 1.6 * intensity, math.cos(phase * 17.0 + dirRad) * 0.5 * intensity);
      case 'lightning':
        final flash = math.sin(phase * 9.0 + dirRad).abs() > 0.93 ? 1.0 : 0.0;
        return Offset(flash * math.sin(phase * 40.0) * 1.2 * intensity, 0);
      default:
        return Offset.zero;
    }
  }

  double _sliceVisibilityFor(String id, double t, double ny) {
    final intensity = config.intensity * 2.0;
    final freq = config.frequency * 2.0;
    
    switch (id) {
      case 'divine_revelation':
        final front = t;
        return ((front - ny) * 6.0 * freq + 0.2 * intensity).clamp(0.0, 1.0);
      case 'celestial_light':
        final beamY = t;
        final dist = (ny - beamY).abs();
        final beam = (1.0 - dist * 6.0 * freq).clamp(0.0, 1.0);
        return (0.6 + beam * 0.4 * intensity).clamp(0.0, 1.0);
      case 'night_of_power':
        final reveal = Curves.easeInOut.transform(t);
        return (0.15 + reveal * 0.85 * intensity).clamp(0.0, 1.0);
      default:
        return 1.0;
    }
  }

  double _hash01(double x) {
    final s = math.sin(x * 12.9898) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _GlyphDeformationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationId != animationId ||
        oldDelegate.text != text ||
        oldDelegate.config != config;
  }
}
