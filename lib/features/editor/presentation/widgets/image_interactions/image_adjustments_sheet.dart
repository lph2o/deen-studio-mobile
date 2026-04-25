import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme.dart';
import '../../../../../models/project.dart';
import '../../editor_state.dart';

/// A reactive bottom-sheet that shows Brightness / Contrast / Saturation
/// sliders for an image layer. It watches the provider so the display value
/// updates live as you drag the slider.
class ImageAdjustmentsSheet extends ConsumerWidget {
  final String layerId;

  const ImageAdjustmentsSheet({super.key, required this.layerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final layer = state.currentProject?.layers.where((l) => l.id == layerId).firstOrNull;

    if (layer == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Réglages de l\'image',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajustements non destructifs appliqués en temps réel',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          _EffectSlider(
            layer: layer,
            label: 'Luminosité',
            effectType: 'brightness',
            min: -1.0,
            max: 1.0,
            defaultValue: 0.0,
            displayFn: (v) => '${(v * 100).toInt()}%',
          ),
          _EffectSlider(
            layer: layer,
            label: 'Contraste',
            effectType: 'contrast',
            min: -1.0,
            max: 1.0,
            defaultValue: 0.0,
            displayFn: (v) => '${(v * 100).toInt()}%',
          ),
          _EffectSlider(
            layer: layer,
            label: 'Saturation',
            effectType: 'saturation',
            min: 0.0,
            max: 2.0,
            defaultValue: 1.0,
            displayFn: (v) => '${(v * 100).toInt()}%',
          ),
          const SizedBox(height: 8),
          _EffectSlider(
            layer: layer,
            label: 'Flou',
            effectType: 'blur',
            min: 0.0,
            max: 1.0,
            defaultValue: 0.0,
            displayFn: (v) => '${(v * 20).toStringAsFixed(1)}σ',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface.withValues(alpha: 0.6),
                      side: BorderSide(color: AppTheme.onSurface.withValues(alpha: 0.12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _resetAll(ref, layer),
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _resetAll(WidgetRef ref, Layer layer) {
    final cleared = layer.copyWith(
      effects: layer.effects.where((e) =>
        e.type != 'brightness' && e.type != 'contrast' &&
        e.type != 'saturation' && e.type != 'blur'
      ).toList(),
    );
    ref.read(editorProvider.notifier).updateLayer(cleared);
  }
}

class _EffectSlider extends ConsumerWidget {
  final Layer layer;
  final String label;
  final String effectType;
  final double min;
  final double max;
  final double defaultValue;
  final String Function(double) displayFn;

  const _EffectSlider({
    required this.layer,
    required this.label,
    required this.effectType,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.displayFn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = layer.effects.where((e) => e.type == effectType).firstOrNull;
    final double value = ((existing?.params['value'] as num?)?.toDouble() ?? defaultValue).clamp(min, max);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayFn(value),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.onSurface.withValues(alpha: 0.1),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (v) {
                final effect = ClipEffect(
                  id: effectType,
                  type: effectType,
                  enabled: true,
                  params: {'value': v},
                );
                ref.read(editorProvider.notifier).applyEffect(layer.id, effect);
              },
            ),
          ),
        ],
      ),
    );
  }
}
