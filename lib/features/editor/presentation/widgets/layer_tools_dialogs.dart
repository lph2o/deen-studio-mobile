import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deen_studio_01/core/ui/app_bottom_sheet.dart';
import 'package:deen_studio_01/core/utils/toast_service.dart';
import 'package:deen_studio_01/core/theme.dart';

/// ═══════════════════════════════════════════
/// Volume Dialog — Compact & Live Preview
/// ═══════════════════════════════════════════

class VolumeDialog extends StatefulWidget {
  final double initialVolume;
  const VolumeDialog({super.key, this.initialVolume = 1.0});

  @override
  State<VolumeDialog> createState() => _VolumeDialogState();
}

class _VolumeDialogState extends State<VolumeDialog> {
  late double _volume;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = _volume == 0;
    final isOriginal = _volume == 1.0;
    final isLoud = _volume > 1.0;

    return AppBottomSheet(
      title: 'Volume',
      subtitle: isMuted
          ? 'Couplé'
          : isOriginal
              ? 'Volume original'
              : '${(_volume * 100).toInt()}%',
      icon: Icon(
        isMuted
            ? LucideIcons.volumeX
            : isLoud
                ? LucideIcons.volume2
                : LucideIcons.volume1,
        color: isMuted ? Colors.red : isLoud ? AppTheme.secondaryColor : AppTheme.primaryColor,
        size: 20,
      ),
      footer: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context, _volume);
          ToastService.showSuccess(context, 'Volume: ${(_volume * 100).toInt()}%');
        },
        icon: const Icon(LucideIcons.check, size: 18),
        label: const Text('Appliquer'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      children: [
        // Large volume display
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '${(_volume * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: isMuted ? Colors.red : AppTheme.primaryColor,
              ),
            ),
          ),
        ),

        AppSliderRow(
          label: 'Niveau',
          value: _volume,
          min: 0,
          max: 2,
          divisions: 20,
          valueLabel: (v) => '${(v * 100).toInt()}%',
          activeColor: isMuted ? Colors.red : isLoud ? AppTheme.secondaryColor : AppTheme.primaryColor,
          onChanged: (v) => setState(() => _volume = v),
        ),

        const SizedBox(height: 12),

        // Quick presets
        Row(
          children: [
            Expanded(
              child: PresetChip(
                label: 'Mute',
                isSelected: isMuted,
                activeColor: Colors.red,
                icon: const Icon(LucideIcons.volumeX),
                onTap: () => setState(() => _volume = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PresetChip(
                label: 'Original',
                isSelected: isOriginal,
                icon: const Icon(LucideIcons.rotateCcw),
                onTap: () => setState(() => _volume = 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PresetChip(
                label: '200%',
                isSelected: _volume == 2.0,
                icon: const Icon(LucideIcons.volume2),
                onTap: () => setState(() => _volume = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════
/// Speed Dialog — Visual presets + slider
/// ═══════════════════════════════════════════

class SpeedDialog extends StatefulWidget {
  final double initialSpeed;
  const SpeedDialog({super.key, this.initialSpeed = 1.0});

  @override
  State<SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends State<SpeedDialog> {
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final isSlow = _speed < 1.0;
    final isFast = _speed > 1.0;
    final isNormal = _speed == 1.0;

    return AppBottomSheet(
      title: 'Vitesse',
      subtitle: isNormal ? 'Vitesse normale' : '${_speed.toStringAsFixed(1)}x',
      icon: Icon(
        isSlow ? LucideIcons.clock : isFast ? LucideIcons.zap : LucideIcons.gauge,
        color: isNormal ? AppTheme.primaryColor : isFast ? AppTheme.secondaryColor : Colors.amber,
        size: 20,
      ),
      footer: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context, _speed);
          ToastService.showSuccess(context, 'Vitesse: ${_speed.toStringAsFixed(1)}x');
        },
        icon: const Icon(LucideIcons.check, size: 18),
        label: const Text('Appliquer'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      children: [
        // Speed display
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: isNormal ? AppTheme.primaryColor : isFast ? AppTheme.secondaryColor : Colors.amber,
                ),
                children: [
                  TextSpan(text: _speed.toStringAsFixed(1)),
                  TextSpan(
                    text: 'x',
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
        ),

        AppSliderRow(
          label: 'Vitesse',
          value: _speed,
          min: 0.25,
          max: 4,
          divisions: 15,
          valueLabel: (v) => '${v.toStringAsFixed(1)}x',
          activeColor: isNormal ? AppTheme.primaryColor : isFast ? AppTheme.secondaryColor : Colors.amber,
          onChanged: (v) => setState(() => _speed = v),
        ),

        const SizedBox(height: 12),

        // Preset chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SpeedPreset(0.25, _speed, Icons.slow_motion_video, Colors.amber),
            _SpeedPreset(0.5, _speed, Icons.play_arrow, Colors.amber),
            _SpeedPreset(0.75, _speed, Icons.play_arrow, AppTheme.primaryColor),
            _SpeedPreset(1.0, _speed, Icons.speed, AppTheme.primaryColor),
            _SpeedPreset(1.5, _speed, Icons.fast_forward, AppTheme.secondaryColor),
            _SpeedPreset(2.0, _speed, Icons.fast_forward, AppTheme.secondaryColor),
            _SpeedPreset(3.0, _speed, Icons.rocket_launch, Colors.redAccent),
            _SpeedPreset(4.0, _speed, Icons.rocket_launch, Colors.redAccent),
          ],
        ),
      ],
    );
  }
}

class _SpeedPreset extends StatelessWidget {
  final double value;
  final double current;
  final IconData icon;
  final Color color;

  const _SpeedPreset(this.value, this.current, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    final label = value.toStringAsFixed(1).replaceAll('.0', '');

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40 - 36) / 4,
      child: PresetChip(
        label: '${label}x',
        isSelected: isSelected,
        activeColor: color,
        icon: Icon(icon),
        onTap: () {
          if (context.mounted) {
            Navigator.of(context).pop(value);
          }
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════
/// Fade Dialog — Dual sliders with preview
/// ═══════════════════════════════════════════

class FadeDialog extends StatefulWidget {
  final double initialFadeIn;
  final double initialFadeOut;
  const FadeDialog({super.key, this.initialFadeIn = 0.0, this.initialFadeOut = 0.0});

  @override
  State<FadeDialog> createState() => _FadeDialogState();
}

class _FadeDialogState extends State<FadeDialog> {
  late double _fadeIn;
  late double _fadeOut;

  @override
  void initState() {
    super.initState();
    _fadeIn = widget.initialFadeIn;
    _fadeOut = widget.initialFadeOut;
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Estomper (Fade)',
      subtitle: _fadeIn == 0 && _fadeOut == 0
          ? 'Aucun fondu'
          : 'In: ${_fadeIn.toStringAsFixed(1)}s • Out: ${_fadeOut.toStringAsFixed(1)}s',
      icon: const Icon(LucideIcons.sun, color: AppTheme.primaryColor, size: 20),
      footer: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context, {'fadeIn': _fadeIn, 'fadeOut': _fadeOut});
          ToastService.showSuccess(
            context,
            'Fade In: ${_fadeIn.toStringAsFixed(1)}s, Fade Out: ${_fadeOut.toStringAsFixed(1)}s',
          );
        },
        icon: const Icon(LucideIcons.check, size: 18),
        label: const Text('Appliquer'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      children: [
        // Visual fade preview
        _FadePreview(fadeIn: _fadeIn, fadeOut: _fadeOut),

        const SizedBox(height: 16),

        AppSliderRow(
          label: 'Entrée (Fade In)',
          value: _fadeIn,
          min: 0,
          max: 5,
          divisions: 10,
          valueLabel: (v) => '${v.toStringAsFixed(1)}s',
          activeColor: AppTheme.primaryColor,
          onChanged: (v) => setState(() => _fadeIn = v),
        ),

        AppSliderRow(
          label: 'Sortie (Fade Out)',
          value: _fadeOut,
          min: 0,
          max: 5,
          divisions: 10,
          valueLabel: (v) => '${v.toStringAsFixed(1)}s',
          activeColor: AppTheme.secondaryColor,
          onChanged: (v) => setState(() => _fadeOut = v),
        ),

        const SizedBox(height: 12),

        // Quick presets
        Row(
          children: [
            Expanded(
              child: PresetChip(
                label: 'Aucun',
                isSelected: _fadeIn == 0 && _fadeOut == 0,
                icon: const Icon(LucideIcons.x),
                onTap: () => setState(() {
                  _fadeIn = 0;
                  _fadeOut = 0;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PresetChip(
                label: '1s / 1s',
                isSelected: _fadeIn == 1 && _fadeOut == 1,
                onTap: () => setState(() {
                  _fadeIn = 1;
                  _fadeOut = 1;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PresetChip(
                label: '2s / 2s',
                isSelected: _fadeIn == 2 && _fadeOut == 2,
                onTap: () => setState(() {
                  _fadeIn = 2;
                  _fadeOut = 2;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Visual fade preview widget
class _FadePreview extends StatelessWidget {
  final double fadeIn;
  final double fadeOut;

  const _FadePreview({required this.fadeIn, required this.fadeOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CustomPaint(
          painter: _FadePainter(fadeIn: fadeIn, fadeOut: fadeOut),
        ),
      ),
    );
  }
}

class _FadePainter extends CustomPainter {
  final double fadeIn;
  final double fadeOut;

  _FadePainter({required this.fadeIn, required this.fadeOut});

  @override
  void paint(Canvas canvas, Size size) {

    final totalDuration = math.max(1.0, fadeIn + 2.0 + fadeOut);
    final fadeInRatio = fadeIn / totalDuration;
    const solidRatio = 0.5;
    final fadeOutRatio = fadeOut / totalDuration;
    final scale = 1.0 / (fadeInRatio + solidRatio + fadeOutRatio);

    final fadeInEnd = fadeInRatio * scale * size.width;
    final solidEnd = fadeInEnd + solidRatio * scale * size.width;
    final fadeOutEnd = solidEnd + fadeOutRatio * scale * size.width;

    // Draw fade in gradient
    if (fadeInEnd > 0) {
      final fadeInPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.0),
            AppTheme.primaryColor.withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromLTWH(0, 0, fadeInEnd, size.height));
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.15, fadeInEnd, size.height * 0.7), fadeInPaint);
    }

    // Draw solid
    if (solidEnd > fadeInEnd) {
      final solidPaint = Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: 0.6);
      canvas.drawRect(
        Rect.fromLTWH(fadeInEnd, size.height * 0.15, solidEnd - fadeInEnd, size.height * 0.7),
        solidPaint,
      );
    }

    // Draw fade out gradient
    if (fadeOutEnd > solidEnd) {
      final fadeOutPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.secondaryColor.withValues(alpha: 0.6),
            AppTheme.secondaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(solidEnd, 0, fadeOutEnd - solidEnd, size.height));
      canvas.drawRect(
        Rect.fromLTWH(solidEnd, size.height * 0.15, fadeOutEnd - solidEnd, size.height * 0.7),
        fadeOutPaint,
      );
    }

    // Draw labels
    final textStyle = TextStyle(
      color: AppTheme.onSurface.withValues(alpha: 0.4),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    if (fadeIn > 0) {
      _drawText(canvas, 'In ${fadeIn.toStringAsFixed(1)}s', textStyle, Offset(fadeInEnd / 2, size.height / 2 - 6));
    }
    if (fadeOut > 0) {
      _drawText(canvas, 'Out ${fadeOut.toStringAsFixed(1)}s', textStyle, Offset(solidEnd + (fadeOutEnd - solidEnd) / 2, size.height / 2 - 6));
    }
  }

  void _drawText(Canvas canvas, String text, TextStyle style, Offset offset) {
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, offset - Offset(painter.width / 2, 0));
  }

  @override
  bool shouldRepaint(_FadePainter old) => old.fadeIn != fadeIn || old.fadeOut != fadeOut;
}

/// ═══════════════════════════════════════════
/// Transition Dialog — Visual grid
/// ═══════════════════════════════════════════

class TransitionDialog extends StatefulWidget {
  final String initialTransition;
  final double initialDuration;
  const TransitionDialog({
    super.key,
    this.initialTransition = 'none',
    this.initialDuration = 1.0,
  });

  @override
  State<TransitionDialog> createState() => _TransitionDialogState();
}

class _TransitionDialogState extends State<TransitionDialog> {
  late String _transition;
  late double _duration;

  final _transitions = [
    {'value': 'none', 'label': 'Aucune', 'icon': Icons.block},
    {'value': 'fade', 'label': 'Fondu', 'icon': Icons.opacity},
    {'value': 'slide_left', 'label': 'Gauche', 'icon': Icons.arrow_back},
    {'value': 'slide_right', 'label': 'Droite', 'icon': Icons.arrow_forward},
    {'value': 'slide_up', 'label': 'Haut', 'icon': Icons.arrow_upward},
    {'value': 'slide_down', 'label': 'Bas', 'icon': Icons.arrow_downward},
    {'value': 'zoom_in', 'label': 'Zoom +', 'icon': Icons.zoom_in},
    {'value': 'zoom_out', 'label': 'Zoom -', 'icon': Icons.zoom_out},
    {'value': 'blur', 'label': 'Flou', 'icon': Icons.blur_on},
    {'value': 'spin', 'label': 'Rotation', 'icon': Icons.rotate_right},
    {'value': 'flip', 'label': 'Retourner', 'icon': Icons.flip},
    {'value': 'cube', 'label': 'Cube', 'icon': Icons.view_in_ar},
    {'value': 'page_turn', 'label': 'Page', 'icon': Icons.menu_book},
    {'value': 'dissolve', 'label': 'Dissoudre', 'icon': Icons.auto_fix_high},
    {'value': 'flash', 'label': 'Flash', 'icon': Icons.flash_on},
    {'value': 'swipe', 'label': 'Balayer', 'icon': Icons.swipe},
    {'value': 'squeeze', 'label': 'Compresser', 'icon': Icons.compress},
    {'value': 'drop', 'label': 'Tomber', 'icon': Icons.vertical_align_bottom},
    {'value': 'morph', 'label': 'Morpher', 'icon': Icons.transform},
    {'value': 'circle_wipe', 'label': 'Cercle', 'icon': Icons.circle_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _transition = widget.initialTransition;
    _duration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    final current = _transitions.firstWhere(
      (t) => t['value'] == _transition,
      orElse: () => _transitions.first,
    );

    return AppBottomSheet(
      title: 'Transition',
      subtitle: current['label'] as String,
      icon: Icon(current['icon'] as IconData, color: AppTheme.primaryColor, size: 22),
      footer: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context, {'transition': _transition, 'duration': _duration});
          ToastService.showSuccess(context, 'Transition: ${current['label']} (${_duration.toStringAsFixed(2)}s)');
        },
        icon: const Icon(LucideIcons.check, size: 18),
        label: const Text('Appliquer'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      children: [
        AppSliderRow(
          label: 'Durée',
          value: _duration,
          min: 0.25,
          max: 3,
          divisions: 11,
          valueLabel: (v) => '${v.toStringAsFixed(2)}s',
          onChanged: (v) => setState(() => _duration = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _transitions.map((t) {
            final isSelected = _transition == t['value'];
            return FilterChip(
              label: Text(t['label'] as String),
              selected: isSelected,
              avatar: Icon(t['icon'] as IconData, size: 16),
              onSelected: (_) => setState(() => _transition = t['value'] as String),
            );
          }).toList(),
        ),
      ],
    );
  }
}
