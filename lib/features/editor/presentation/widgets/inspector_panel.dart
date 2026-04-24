import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/project.dart';
import '../../../../models/text_layer_style.dart';
import '../../../../core/models/video_filter.dart';
import '../../../../core/models/speed_curve.dart';
import '../../../../core/theme.dart';
import '../../../../core/ui/design_system.dart';
import '../editor_state.dart';
import 'color_grading_panel.dart';

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final selectedId = state.selectedLayerId;
    if (selectedId == null) return const SizedBox.shrink();

    final layer = state.currentProject?.layers
        .where((l) => l.id == selectedId)
        .firstOrNull;
    if (layer == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.25, 0.45, 0.85],
      builder: (context, scrollController) {
        return _InspectorSheet(
          layer: layer,
          scrollController: scrollController,
          ref: ref,
        );
      },
    );
  }
}

class _InspectorSheet extends StatelessWidget {
  final Layer layer;
  final ScrollController scrollController;
  final WidgetRef ref;

  const _InspectorSheet({
    required this.layer,
    required this.scrollController,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurface.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _TypeBadge(type: layer.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _layerTitle(layer),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GlassIconButton(
                      icon: LucideIcons.trash2,
                      onTap: () {
                        ref.read(editorProvider.notifier).removeLayer(layer.id);
                        ref
                            .read(editorProvider.notifier)
                            .setSelectedLayer(null);
                      },
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    GlassIconButton(
                      icon: LucideIcons.x,
                      onTap: () => ref
                          .read(editorProvider.notifier)
                          .setSelectedLayer(null),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader('Timing'),
                _InlineRow('Start', '${layer.startTime.toStringAsFixed(2)}s'),
                _InlineRow('Duration', '${layer.duration.toStringAsFixed(2)}s'),
                const SizedBox(height: 16),

                _SectionHeader('Transform'),
                _SliderTile(
                  label: 'Opacity',
                  value: layer.transform.opacity,
                  min: 0,
                  max: 1,
                  onChanged: (v) => ref
                      .read(editorProvider.notifier)
                      .updateLayerTransform(
                        layer.id,
                        layer.transform.copyWith(opacity: v),
                      ),
                ),
                _SliderTile(
                  label: 'Scale X',
                  value: layer.transform.scaleX,
                  min: 0.1,
                  max: 3.0,
                  onChanged: (v) => ref
                      .read(editorProvider.notifier)
                      .updateLayerTransform(
                        layer.id,
                        layer.transform.copyWith(scaleX: v),
                      ),
                ),
                _SliderTile(
                  label: 'Scale Y',
                  value: layer.transform.scaleY,
                  min: 0.1,
                  max: 3.0,
                  onChanged: (v) => ref
                      .read(editorProvider.notifier)
                      .updateLayerTransform(
                        layer.id,
                        layer.transform.copyWith(scaleY: v),
                      ),
                ),
                _SliderTile(
                  label: 'Rotation',
                  value: layer.transform.rotation,
                  min: -180,
                  max: 180,
                  onChanged: (v) => ref
                      .read(editorProvider.notifier)
                      .updateLayerTransform(
                        layer.id,
                        layer.transform.copyWith(rotation: v),
                      ),
                ),
                const SizedBox(height: 16),

                // Keyframes
                _KeyframeSection(layer: layer, ref: ref),
                const SizedBox(height: 16),

                // Mask
                if (layer.isVisual) ...[
                  _SectionHeader('Mask'),
                  _MaskSection(layer: layer, ref: ref),
                  const SizedBox(height: 16),

                  // Blend Mode
                  _SectionHeader('Blend Mode'),
                  _BlendModeSection(layer: layer, ref: ref),
                  const SizedBox(height: 16),

                  // Filters
                  _SectionHeader('Filtres'),
                  _FilterSection(layer: layer, ref: ref),
                  const SizedBox(height: 16),

                  // Color Grading
                  _ColorGradingButton(layer: layer, ref: ref),
                  const SizedBox(height: 16),

                  // Chroma Key
                  _SectionHeader('Chroma Key (Fond Vert)'),
                  _ChromaKeySection(layer: layer, ref: ref),
                  const SizedBox(height: 16),
                ],

                // Effects
                _SectionHeader('Color Effects'),
                _EffectToggle(
                  label: 'Brightness',
                  effectType: 'brightness',
                  layer: layer,
                  ref: ref,
                ),
                _EffectToggle(
                  label: 'Contrast',
                  effectType: 'contrast',
                  layer: layer,
                  ref: ref,
                ),
                _EffectToggle(
                  label: 'Saturation',
                  effectType: 'saturation',
                  layer: layer,
                  ref: ref,
                ),
                _EffectToggle(
                  label: 'Grayscale',
                  effectType: 'grayscale',
                  layer: layer,
                  ref: ref,
                ),
                _EffectToggle(
                  label: 'Hue',
                  effectType: 'hue',
                  layer: layer,
                  ref: ref,
                ),
                const SizedBox(height: 16),

                // Advanced Effects
                _SectionHeader('Advanced Effects'),
                _EffectToggle(
                  label: 'Blur',
                  effectType: 'blur',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.1,
                  sliderLabel: 'Sigma',
                  valueDisplay: (v) => (v * 20.0).toStringAsFixed(1),
                ),
                _EffectToggle(
                  label: 'Sharpen',
                  effectType: 'sharpen',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.5,
                  sliderLabel: 'Amount',
                  valueDisplay: (v) => '${(v * 200).toStringAsFixed(0)}%',
                ),
                _EffectToggle(
                  label: 'Pixelate',
                  effectType: 'pixelate',
                  layer: layer,
                  ref: ref,
                  min: 2,
                  max: 64.0,
                  defaultValue: 16,
                  sliderLabel: 'Block Size',
                  valueDisplay: (v) => '${v.toStringAsFixed(0)}px',
                ),
                _EffectToggle(
                  label: 'Noise / Grain',
                  effectType: 'noise',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.3,
                  sliderLabel: 'Amount',
                  valueDisplay: (v) => '${(v * 100).toStringAsFixed(0)}%',
                ),
                _EffectToggle(
                  label: 'Vignette',
                  effectType: 'vignette',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.5,
                  sliderLabel: 'Intensity',
                  valueDisplay: (v) => '${(v * 100).toStringAsFixed(0)}%',
                ),
                _EffectToggle(
                  label: 'VHS',
                  effectType: 'vhs',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.5,
                  sliderLabel: 'Intensity',
                  valueDisplay: (v) => '${(v * 100).toStringAsFixed(0)}%',
                ),
                _EffectToggle(
                  label: 'Glitch',
                  effectType: 'glitch',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.3,
                  sliderLabel: 'Intensity',
                  valueDisplay: (v) => '${(v * 100).toStringAsFixed(0)}%',
                ),
                _EffectToggle(
                  label: 'Old Film',
                  effectType: 'oldFilm',
                  layer: layer,
                  ref: ref,
                  min: 0,
                  max: 1.0,
                  defaultValue: 0.5,
                  sliderLabel: 'Intensity',
                  valueDisplay: (v) => '${(v * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 16),

                // Speed Curve (for video/audio layers)
                if (layer.type == 'video' || layer.type == 'audio') ...[
                  _SectionHeader('Speed Curve'),
                  _SpeedCurveSection(layer: layer, ref: ref),
                  const SizedBox(height: 16),
                ],

                // Audio-specific: Beat Sync, Noise Gate
                if (layer.type == 'audio') ...[
                  _SectionHeader('Audio'),
                  _BeatSyncSection(layer: layer, ref: ref),
                  const SizedBox(height: 12),
                  _NoiseGateSection(layer: layer, ref: ref),
                  const SizedBox(height: 16),
                ],

                // Project-level: Ducking toggle (shown on any audio layer)
                if (layer.type == 'audio') ...[
                  _DuckingSection(ref: ref),
                  const SizedBox(height: 16),
                ],

                // Text-specific
                if (layer.isTextType) ...[
                  _SectionHeader('Text Style'),
                  if (layer.type == 'translation' ||
                      layer.type == 'phonetic' ||
                      layer.type == 'text') ...[
                    _CaptionStyleSelector(layer: layer, ref: ref),
                    const SizedBox(height: 16),
                  ],
                  _AnimationPicker(layer: layer, ref: ref),
                  const SizedBox(height: 12),
                  _AnimationConfigSection(layer: layer, ref: ref),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _layerTitle(Layer layer) {
    if (layer.content.isNotEmpty) {
      return layer.content.length > 40
          ? '${layer.content.substring(0, 40)}…'
          : layer.content;
    }
    return layer.type.toUpperCase();
  }
}

// ─── Sub-components ────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final colorMap = {
      'text': AppTheme.trackText,
      'audio': AppTheme.trackAudio,
      'video': AppTheme.trackVideo,
      'image': AppTheme.trackImage,
    };
    final color = colorMap[type] ?? AppTheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
      ),
    );
  }
}

class _InlineRow extends StatelessWidget {
  final String label;
  final String value;
  const _InlineRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderRow(
      label: label,
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChanged: onChanged,
    );
  }
}

class _EffectToggle extends StatelessWidget {
  final String label;
  final String effectType;
  final Layer layer;
  final WidgetRef ref;
  final double min;
  final double max;
  final double defaultValue;
  final String? sliderLabel;
  final String Function(double)? valueDisplay;

  const _EffectToggle({
    required this.label,
    required this.effectType,
    required this.layer,
    required this.ref,
    this.min = 0,
    this.max = 2.0,
    this.defaultValue = 1.0,
    this.sliderLabel,
    this.valueDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final existing = layer.effects
        .where((e) => e.type == effectType)
        .firstOrNull;
    final isActive = existing?.enabled ?? false;
    final value = existing?.params['value'] ?? defaultValue;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ),
            Switch(
              value: isActive,
              onChanged: (v) {
                final effect = ClipEffect(
                  id: effectType,
                  type: effectType,
                  enabled: v,
                  params: {'value': value},
                );
                ref.read(editorProvider.notifier).applyEffect(layer.id, effect);
              },
            ),
          ],
        ),
        if (isActive)
          _SliderTile(
            label: sliderLabel ?? '',
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
        if (isActive && valueDisplay != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Text(
              valueDisplay!(value),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.onSurface.withValues(alpha: 0.3),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _CaptionStyleSelector extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _CaptionStyleSelector({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final style = layer.textStyle ?? const TextLayerStyle();

    final presets = [
      (id: 'none', label: 'Aucun', icon: LucideIcons.type),
      (id: 'bubble', label: 'Bulle', icon: LucideIcons.messageSquare),
      (id: 'glow', label: 'Lueur', icon: LucideIcons.sun),
      (id: 'neon', label: 'Néon', icon: LucideIcons.zap),
      (id: 'outline', label: 'Bordure', icon: LucideIcons.square),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Styles de Caption',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface.withValues(alpha: 0.54),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = presets[index];
              final isSelected = (style.captionStyleId ?? 'none') == p.id;

              return GestureDetector(
                onTap: () {
                  _applyPreset(p.id, style);
                },
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.outlineVariant.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        p.icon,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.onSurface.withValues(alpha: 0.54),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (style.captionStyleId != null && style.captionStyleId != 'none') ...[
          const SizedBox(height: 16),
          if (style.captionStyleId == 'bubble') ...[
            _SliderTile(
              label: 'Padding',
              value: style.backgroundPadding,
              min: 4,
              max: 32,
              onChanged: (v) {
                ref
                    .read(editorProvider.notifier)
                    .updateLayerTextStyle(
                      layer.id,
                      style.copyWith(backgroundPadding: v),
                    );
              },
            ),
            const SizedBox(height: 8),
            _SliderTile(
              label: 'Arrondi',
              value: style.borderRadius,
              min: 0,
              max: 40,
              onChanged: (v) {
                ref
                    .read(editorProvider.notifier)
                    .updateLayerTextStyle(
                      layer.id,
                      style.copyWith(borderRadius: v),
                    );
              },
            ),
          ],
          if (style.captionStyleId == 'glow' || style.captionStyleId == 'neon')
            _SliderTile(
              label: 'Intensité Lueur',
              value: style.glowBlur,
              min: 0,
              max: 30,
              onChanged: (v) {
                ref
                    .read(editorProvider.notifier)
                    .updateLayerTextStyle(
                      layer.id,
                      style.copyWith(glowBlur: v),
                    );
              },
            ),
        ],
      ],
    );
  }

  void _applyPreset(String id, TextLayerStyle current) {
    TextLayerStyle updated = current;

    switch (id) {
      case 'none':
        updated = current.copyWith(
          clearCaptionStyle: true,
          clearBackground: true,
          glowBlur: 0,
          strokeWidth: 0,
        );
        break;
      case 'bubble':
        updated = current.copyWith(
          captionStyleId: 'bubble',
          backgroundColor: '#000000',
          backgroundPadding: 12,
          borderRadius: 12,
          color: '#FFFFFF',
        );
        break;
      case 'glow':
        updated = current.copyWith(
          captionStyleId: 'glow',
          glowBlur: 8,
          glowColor: current.color,
        );
        break;
      case 'neon':
        updated = current.copyWith(
          captionStyleId: 'neon',
          glowBlur: 12,
          glowColor: current.color,
          isBold: true,
        );
        break;
      case 'outline':
        updated = current.copyWith(
          captionStyleId: 'outline',
          strokeWidth: 2.0,
          strokeColor: '#000000',
          shadowColor: '#000000',
          shadowBlur: 4,
          shadowOffsetX: 2,
          shadowOffsetY: 2,
        );
        break;
    }

    ref.read(editorProvider.notifier).updateLayerTextStyle(layer.id, updated);
  }
}

class _AnimationPicker extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _AnimationPicker({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    const options = [
      TextAnimationPreset.none,
      TextAnimationPreset.fadeIn,
      TextAnimationPreset.fadeOut,
      TextAnimationPreset.fadeInOut,
      TextAnimationPreset.typewriter,
      TextAnimationPreset.wordByWord,
      TextAnimationPreset.wordHighlight,
      TextAnimationPreset.karaokeRTL,
    ];
    final currentStyle = layer.textStyle ?? const TextLayerStyle();

    return Row(
      children: [
        Text(
          'Animation',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.onSurface.withValues(alpha: 0.54),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<TextAnimationPreset>(
            value: currentStyle.animationPreset,
            isExpanded: true,
            dropdownColor: AppTheme.surfaceHigh,
            underline: const SizedBox(),
            style: TextStyle(
              color: AppTheme.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            items: options
                .map(
                  (preset) => DropdownMenuItem(
                    value: preset,
                    child: Text(preset.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              ref
                  .read(editorProvider.notifier)
                  .updateLayerTextStyle(
                    layer.id,
                    currentStyle.copyWith(animationPreset: v),
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimationConfigSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _AnimationConfigSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentStyle = layer.textStyle ?? const TextLayerStyle();
    final config = currentStyle.animationConfig;
    final isNone =
        currentStyle.animationPreset == TextAnimationPreset.none &&
        currentStyle.quranAnimationId.isEmpty;

    if (isNone) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Animation Config',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (!config.isDefault)
              InkWell(
                onTap: () {
                  ref
                      .read(editorProvider.notifier)
                      .updateLayerTextStyle(
                        layer.id,
                        currentStyle.copyWith(
                          animationConfig: const AnimationConfig(),
                        ),
                      );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Duration Multiplier
        _SliderTile(
          label: 'Speed (${config.durationMultiplier.toStringAsFixed(1)}x)',
          value: config.durationMultiplier,
          min: 0.1,
          max: 10.0,
          onChanged: (v) {
            ref
                .read(editorProvider.notifier)
                .updateLayerTextStyle(
                  layer.id,
                  currentStyle.copyWith(
                    animationConfig: config.copyWith(durationMultiplier: v),
                  ),
                );
          },
        ),
        const SizedBox(height: 8),
        // Primary Color
        Row(
          children: [
            Text(
              'Color',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (ctx) =>
                      _ChromaKeyColorPicker(initialColor: config.color),
                );
                if (color != null) {
                  final hex =
                      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                  ref
                      .read(editorProvider.notifier)
                      .updateLayerTextStyle(
                        layer.id,
                        currentStyle.copyWith(
                          animationConfig: config.copyWith(color: hex),
                        ),
                      );
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: TextLayerStyle.parseHexColor(config.color),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              config.color,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.onSurface.withValues(alpha: 0.38),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Frequency
        _SliderTile(
          label: 'Frequency',
          value: config.frequency,
          min: 0.0,
          max: 1.0,
          onChanged: (v) {
            ref
                .read(editorProvider.notifier)
                .updateLayerTextStyle(
                  layer.id,
                  currentStyle.copyWith(
                    animationConfig: config.copyWith(frequency: v),
                  ),
                );
          },
        ),
        const SizedBox(height: 8),
        // Intensity
        _SliderTile(
          label: 'Intensity',
          value: config.intensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) {
            ref
                .read(editorProvider.notifier)
                .updateLayerTextStyle(
                  layer.id,
                  currentStyle.copyWith(
                    animationConfig: config.copyWith(intensity: v),
                  ),
                );
          },
        ),
        const SizedBox(height: 8),
        // Direction
        _SliderTile(
          label: 'Direction (${config.direction.round()}°)',
          value: config.direction,
          min: 0,
          max: 360,
          onChanged: (v) {
            ref
                .read(editorProvider.notifier)
                .updateLayerTextStyle(
                  layer.id,
                  currentStyle.copyWith(
                    animationConfig: config.copyWith(direction: v),
                  ),
                );
          },
        ),
      ],
    );
  }
}

// ─── Keyframe Section ────────────────────────────────────────────────────────

class _KeyframeSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _KeyframeSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final keyframes = layer.keyframes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionHeader('Keyframes'),
            const Spacer(),
            // Add Keyframe button
            InkWell(
              onTap: () {
                final notifier = ref.read(editorProvider.notifier);
                notifier.addKeyframe(
                  layer.id,
                  state.currentTime,
                  layer.transform,
                  easing: 'linear',
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.diamond,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Mini timeline
        if (keyframes.isNotEmpty)
          _KeyframeTimeline(
            keyframes: keyframes,
            layerId: layer.id,
            currentTime: state.currentTime,
            ref: ref,
          ),

        // Keyframe list
        if (keyframes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No keyframes yet. Move the playhead and click Add.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          )
        else
          ...keyframes.asMap().entries.map(
            (entry) => _KeyframeTile(
              index: entry.key,
              keyframe: entry.value,
              layerId: layer.id,
              ref: ref,
            ),
          ),
      ],
    );
  }
}

class _KeyframeTimeline extends StatelessWidget {
  final List<Keyframe> keyframes;
  final String layerId;
  final double currentTime;
  final WidgetRef ref;

  const _KeyframeTimeline({
    required this.keyframes,
    required this.layerId,
    required this.currentTime,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final project = ref.read(editorProvider).currentProject;
    final totalDuration = project?.totalDuration ?? 30.0;

    return Container(
      height: 24,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.06),
        ),
      ),
      child: Stack(
        children: [
          // Playhead indicator
          if (totalDuration > 0)
            Positioned(
              left: (currentTime / totalDuration).clamp(0.0, 1.0) * (300.0 - 8),
              child: Container(
                width: 2,
                height: 24,
                color: AppTheme.playheadColor.withValues(alpha: 0.6),
              ),
            ),
          // Keyframe dots
          ...keyframes.asMap().entries.map((entry) {
            final kf = entry.value;
            final position = totalDuration > 0
                ? (kf.time / totalDuration).clamp(0.0, 1.0)
                : 0.0;
            return Positioned(
              left: position * (300.0 - 8),
              top: 6,
              child: Tooltip(
                message: '${kf.time.toStringAsFixed(2)}s - ${kf.easing}',
                child: GestureDetector(
                  onTap: () {
                    ref.read(editorProvider.notifier).setCurrentTime(kf.time);
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.onSurface.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.diamond,
                        size: 6,
                        color: AppTheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KeyframeTile extends StatelessWidget {
  final int index;
  final Keyframe keyframe;
  final String layerId;
  final WidgetRef ref;

  const _KeyframeTile({
    required this.index,
    required this.keyframe,
    required this.layerId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final easingOptions = ['linear', 'easeIn', 'easeOut', 'easeInOut'];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Diamond icon
          Icon(LucideIcons.diamond, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 8),

          // Time
          SizedBox(
            width: 52,
            child: Text(
              '${keyframe.time.toStringAsFixed(2)}s',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Easing dropdown
          Expanded(
            child: DropdownButton<String>(
              value: keyframe.easing,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceHigh,
              underline: const SizedBox(),
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.54),
                fontSize: 10,
              ),
              items: easingOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(editorProvider.notifier)
                      .updateKeyframeEasing(layerId, index, v);
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Transform summary
          SizedBox(
            width: 60,
            child: Text(
              'S:${keyframe.transform.scaleX.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.onSurface.withValues(alpha: 0.38),
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 4),

          // Delete button
          GlassIconButton(
            icon: LucideIcons.x,
            onTap: () => ref
                .read(editorProvider.notifier)
                .removeKeyframe(layerId, index),
            size: 14,
          ),
        ],
      ),
    );
  }
}

// ─── Mask Section ────────────────────────────────────────────────────────

class _MaskSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _MaskSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final mask = layer.mask;
    final maskOptions = MaskType.values
        .where((t) => t != MaskType.none)
        .toList();
    final maskLabels = <MaskType, String>{
      MaskType.rectangle: 'Rectangle',
      MaskType.circle: 'Circle',
      MaskType.triangle: 'Triangle',
      MaskType.heart: 'Heart',
      MaskType.star: 'Star',
      MaskType.splitHorizontal: 'Split H',
      MaskType.splitVertical: 'Split V',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mask type dropdown
        Row(
          children: [
            Expanded(
              child: DropdownButton<MaskType>(
                value: mask.type == MaskType.none ? null : mask.type,
                isExpanded: true,
                hint: Text(
                  'None',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
                dropdownColor: AppTheme.surfaceHigh,
                underline: const SizedBox(),
                style: TextStyle(
                  color: AppTheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                items: [
                  DropdownMenuItem<MaskType>(
                    value: null,
                    child: Text(
                      'None',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  ...maskOptions.map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        maskLabels[t] ?? t.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  ref
                      .read(editorProvider.notifier)
                      .updateLayerMask(
                        layer.id,
                        mask.copyWith(type: v ?? MaskType.none),
                      );
                },
              ),
            ),
          ],
        ),
        if (mask.type != MaskType.none) ...[
          const SizedBox(height: 8),
          // Value slider
          _SliderTile(
            label: 'Value',
            value: mask.value,
            min: 0,
            max: 1,
            onChanged: (v) => ref
                .read(editorProvider.notifier)
                .updateLayerMask(layer.id, mask.copyWith(value: v)),
          ),
          // Feather slider
          _SliderTile(
            label: 'Feather',
            value: mask.feather,
            min: 0,
            max: 1,
            onChanged: (v) => ref
                .read(editorProvider.notifier)
                .updateLayerMask(layer.id, mask.copyWith(feather: v)),
          ),
          // Rotation slider
          _SliderTile(
            label: 'Rotation',
            value: mask.rotation,
            min: 0,
            max: 360,
            onChanged: (v) => ref
                .read(editorProvider.notifier)
                .updateLayerMask(layer.id, mask.copyWith(rotation: v)),
          ),
        ],
      ],
    );
  }
}

// ─── Blend Mode Section ──────────────────────────────────────────────────

const kBlendModeLabels = {
  'srcOver': 'Normal',
  'multiply': 'Multiply',
  'screen': 'Screen',
  'overlay': 'Overlay',
  'darken': 'Darken',
  'lighten': 'Lighten',
  'difference': 'Difference',
  'colorDodge': 'Color Dodge',
  'colorBurn': 'Color Burn',
  'hardLight': 'Hard Light',
  'softLight': 'Soft Light',
};

class _BlendModeSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _BlendModeSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blend mode dropdown with preview swatches
        DropdownButton<String>(
          value: layer.blendMode,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceHigh,
          underline: const SizedBox(),
          style: TextStyle(
            color: AppTheme.onSurface.withValues(alpha: 0.7),
            fontSize: 13,
          ),
          items: kBlendModes.map((mode) {
            return DropdownMenuItem<String>(
              value: mode,
              child: Row(
                children: [
                  // Small preview swatch
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: _blendModePreview(mode),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kBlendModeLabels[mode] ?? mode,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(editorProvider.notifier).updateBlendMode(layer.id, v);
            }
          },
        ),
      ],
    );
  }

  Gradient _blendModePreview(String mode) {
    switch (mode) {
      case 'srcOver':
        return const LinearGradient(colors: [Colors.white, Colors.white]);
      case 'multiply':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
        );
      case 'screen':
        return const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFFe94560)],
        );
      case 'overlay':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      case 'darken':
        return const LinearGradient(
          colors: [Color(0xFF2d3436), Color(0xFF636e72)],
        );
      case 'lighten':
        return const LinearGradient(
          colors: [Color(0xFFfdcb6e), Color(0xFFffeaa7)],
        );
      case 'difference':
        return const LinearGradient(
          colors: [Color(0xFFe17055), Color(0xFF00b894)],
        );
      case 'colorDodge':
        return const LinearGradient(
          colors: [Color(0xFFfd79a8), Color(0xFFfdcb6e)],
        );
      case 'colorBurn':
        return const LinearGradient(
          colors: [Color(0xFFd63031), Color(0xFFe17055)],
        );
      case 'hardLight':
        return const LinearGradient(
          colors: [Color(0xFF0984e3), Color(0xFF74b9ff)],
        );
      case 'softLight':
        return const LinearGradient(
          colors: [Color(0xFFa29bfe), Color(0xFF6c5ce7)],
        );
      default:
        return const LinearGradient(colors: [Colors.white, Colors.white]);
    }
  }
}

// ─── Filter Section ──────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _FilterSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentFilterId = layer.filterId;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kBuiltInFilters.length,
        itemBuilder: (context, index) {
          final filter = kBuiltInFilters[index];
          final isSelected = filter.id == currentFilterId;

          return GestureDetector(
            onTap: () {
              ref
                  .read(editorProvider.notifier)
                  .applyFilter(layer.id, filter.id);
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter preview thumbnail
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _filterGradient(filter),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.outlineVariant.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter.name.length > 6
                            ? '${filter.name.substring(0, 5)}.'
                            : filter.name,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface.withValues(alpha: 0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.54),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.name,
                    style: TextStyle(
                      fontSize: 8,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.onSurface.withValues(alpha: 0.54),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Generate a gradient that visually represents the filter's look.
  Gradient _filterGradient(VideoFilter filter) {
    // Base colors modified by filter characteristics
    Color startColor = _applyFilterParams(const Color(0xFF1a1a2e), filter);
    Color endColor = _applyFilterParams(const Color(0xFFe94560), filter);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [startColor, endColor],
    );
  }

  Color _applyFilterParams(Color base, VideoFilter filter) {
    var r = base.r;
    var g = base.g;
    var b = base.b;

    // Apply warmth (shift red channel)
    if (filter.warmth > 0) {
      r = (r + filter.warmth * 0.3).clamp(0.0, 1.0);
    } else if (filter.warmth < 0) {
      b = (b - filter.warmth * 0.3).clamp(0.0, 1.0);
    }

    // Apply saturation boost/desaturation
    final gray = 0.299 * r + 0.587 * g + 0.114 * b;
    final s = filter.saturation.clamp(0.0, 2.0);
    r = (gray + s * (r - gray)).clamp(0.0, 1.0);
    g = (gray + s * (g - gray)).clamp(0.0, 1.0);
    b = (gray + s * (b - gray)).clamp(0.0, 1.0);

    // Apply brightness
    final adjustedR = (r * filter.brightness).clamp(0.0, 1.0);
    final adjustedG = (g * filter.brightness).clamp(0.0, 1.0);
    final adjustedB = (b * filter.brightness).clamp(0.0, 1.0);

    return Color.fromRGBO(
      (adjustedR * 255).round(),
      (adjustedG * 255).round(),
      (adjustedB * 255).round(),
      1.0,
    );
  }
}

// ─── Speed Curve Section ─────────────────────────────────────────────────

class _SpeedCurveSection extends StatefulWidget {
  final Layer layer;
  final WidgetRef ref;

  const _SpeedCurveSection({required this.layer, required this.ref});

  @override
  State<_SpeedCurveSection> createState() => _SpeedCurveSectionState();
}

class _SpeedCurveSectionState extends State<_SpeedCurveSection> {
  SpeedCurve? _editingCurve;

  SpeedCurve get _currentCurve =>
      _editingCurve ?? widget.layer.speedCurve ?? SpeedCurve();

  void _setCurve(SpeedCurve curve) {
    setState(() => _editingCurve = curve);
    widget.ref
        .read(editorProvider.notifier)
        .applySpeedCurve(widget.layer.id, curve);
  }

  void _applyPreset(String preset) {
    switch (preset) {
      case 'montage':
        _setCurve(SpeedCurve.curveMontage);
        break;
      case 'slowmo':
        _setCurve(SpeedCurve.curveSlowMo);
        break;
      case 'rampup':
        _setCurve(SpeedCurve.curveRampUp);
        break;
      case 'custom':
        _setCurve(
          SpeedCurve(
            points: [
              const SpeedPoint(position: 0.0, speed: 1.0),
              const SpeedPoint(position: 1.0, speed: 1.0),
            ],
          ),
        );
        break;
    }
  }

  void _resetCurve() {
    setState(() => _editingCurve = null);
    widget.ref
        .read(editorProvider.notifier)
        .applySpeedCurve(widget.layer.id, SpeedCurve(points: []));
    // Also clear from layer
    final layer = widget.layer;
    widget.ref
        .read(editorProvider.notifier)
        .updateLayer(layer.copyWith(speedCurve: null));
  }

  @override
  Widget build(BuildContext context) {
    final curve = _currentCurve;
    final points = curve.points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset buttons
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PresetButton(
              label: 'Montage',
              icon: Icons.flash_on,
              isActive: _pointsMatch(points, SpeedCurve.curveMontage.points),
              onTap: () => _applyPreset('montage'),
            ),
            _PresetButton(
              label: 'Slow Motion',
              icon: Icons.slow_motion_video,
              isActive: _pointsMatch(points, SpeedCurve.curveSlowMo.points),
              onTap: () => _applyPreset('slowmo'),
            ),
            _PresetButton(
              label: 'Ramp Up',
              icon: Icons.trending_up,
              isActive: _pointsMatch(points, SpeedCurve.curveRampUp.points),
              onTap: () => _applyPreset('rampup'),
            ),
            _PresetButton(
              label: 'Custom',
              icon: Icons.edit,
              isActive:
                  points.isNotEmpty &&
                  !_pointsMatch(points, SpeedCurve.curveMontage.points) &&
                  !_pointsMatch(points, SpeedCurve.curveSlowMo.points) &&
                  !_pointsMatch(points, SpeedCurve.curveRampUp.points),
              onTap: () => _applyPreset('custom'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Curve graph
        if (points.isNotEmpty)
          GestureDetector(
            onTapDown: (details) => _addPointFromTap(details, context),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              child: Stack(
                children: [
                  // Grid lines
                  Positioned.fill(
                    child: CustomPaint(painter: _SpeedGridPainter()),
                  ),
                  // Curve line and points
                  Positioned.fill(
                    child: CustomPaint(painter: _SpeedCurvePainter(points)),
                  ),
                  // Draggable points
                  ...points.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final x =
                        point.position * (context.size?.width ?? 300 - 16) + 8;
                    final y = 100 - (_speedToY(point.speed) * 100);

                    return Positioned(
                      left: x - 8,
                      top: y - 8,
                      child: GestureDetector(
                        onPanUpdate: (d) => _movePoint(index, d.delta, context),
                        onDoubleTap: () {
                          if (points.length > 2) {
                            final newPoints = List<SpeedPoint>.from(points)
                              ..removeAt(index);
                            newPoints.sort(
                              (a, b) => a.position.compareTo(b.position),
                            );
                            _setCurve(SpeedCurve(points: newPoints));
                          }
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.onSurface.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${point.speed.toStringAsFixed(1)}x',
                              style: TextStyle(
                                fontSize: 6,
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Info text
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            points.isEmpty
                ? 'No speed curve. Using constant speed.'
                : 'Tap to add point. Double-tap point to remove.',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.onSurface.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        // Reset button if curve is active
        if (points.isNotEmpty)
          TextButton.icon(
            onPressed: _resetCurve,
            icon: const Icon(Icons.clear, size: 14),
            label: Text(
              'Reset to constant speed',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              foregroundColor: AppTheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  bool _pointsMatch(List<SpeedPoint> a, List<SpeedPoint> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i].position - b[i].position).abs() > 0.01 ||
          (a[i].speed - b[i].speed).abs() > 0.01) {
        return false;
      }
    }
    return true;
  }

  double _speedToY(double speed) {
    // Map speed (0.1 - 10.0) to Y (0.0 - 1.0), using log scale
    final minLog = math.log(0.1);
    final maxLog = math.log(10.0);
    final logSpeed = math.log(speed.clamp(0.1, 10.0));
    return ((logSpeed - minLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  }

  double _yToSpeed(double y) {
    final minLog = math.log(0.1);
    final maxLog = math.log(10.0);
    final logSpeed = minLog + y * (maxLog - minLog);
    return math.exp(logSpeed).clamp(0.1, 10.0);
  }

  void _addPointFromTap(TapDownDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = details.localPosition;
    final width = box.size.width;
    final position = ((localPos.dx - 8) / (width - 16)).clamp(0.0, 1.0);
    final speed = _yToSpeed(localPos.dy / 100);

    final newPoints = List<SpeedPoint>.from(_currentCurve.points)
      ..add(SpeedPoint(position: position, speed: speed));
    newPoints.sort((a, b) => a.position.compareTo(b.position));
    _setCurve(SpeedCurve(points: newPoints));
  }

  void _movePoint(int index, Offset delta, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final width = box.size.width;
    final point = _currentCurve.points[index];

    final newPosition = (point.position + delta.dx / (width - 16)).clamp(
      0.0,
      1.0,
    );
    final newSpeed = _yToSpeed(_speedToY(point.speed) - delta.dy / 100);

    final newPoints = List<SpeedPoint>.from(_currentCurve.points);
    newPoints[index] = SpeedPoint(
      position: newPosition,
      speed: newSpeed.clamp(0.1, 10.0),
    );
    newPoints.sort((a, b) => a.position.compareTo(b.position));
    _setCurve(SpeedCurve(points: newPoints));
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor
                : AppTheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive
                  ? AppTheme.primaryColor
                  : AppTheme.onSurface.withValues(alpha: 0.54),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.onSurface.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    // Horizontal grid lines at key speeds
    const speeds = [0.25, 0.5, 1.0, 2.0, 4.0];
    for (final speed in speeds) {
      final y = _speedToY(speed) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical grid lines at positions
    for (double pos = 0.0; pos <= 1.0; pos += 0.25) {
      final x = pos * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  double _speedToY(double speed) {
    final minLog = math.log(0.1);
    final maxLog = math.log(10.0);
    final logSpeed = math.log(speed.clamp(0.1, 10.0));
    return ((logSpeed - minLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _SpeedGridPainter old) => false;
}

class _SpeedCurvePainter extends CustomPainter {
  final List<SpeedPoint> points;

  _SpeedCurvePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final sortedPoints = List<SpeedPoint>.from(points)
      ..sort((a, b) => a.position.compareTo(b.position));

    for (int i = 0; i < sortedPoints.length; i++) {
      final x = sortedPoints[i].position * size.width;
      final y = (1 - _speedToY(sortedPoints[i].speed)) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  double _speedToY(double speed) {
    final minLog = math.log(0.1);
    final maxLog = math.log(10.0);
    final logSpeed = math.log(speed.clamp(0.1, 10.0));
    return ((logSpeed - minLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _SpeedCurvePainter old) {
    if (old.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (old.points[i].position != points[i].position ||
          old.points[i].speed != points[i].speed) {
        return true;
      }
    }
    return false;
  }
}

// ─── Color Grading Button ────────────────────────────────────────────────

class _ColorGradingButton extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _ColorGradingButton({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final grading = layer.colorGrading;
    final hasChanges = !grading.isDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Color Grading'),
        InkWell(
          onTap: () => showColorGradingPanel(context, layer.id, ref),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasChanges
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : AppTheme.surfaceContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasChanges
                    ? AppTheme.primaryColor.withValues(alpha: 0.4)
                    : AppTheme.outlineVariant.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.palette,
                  size: 20,
                  color: hasChanges
                      ? AppTheme.primaryColor
                      : AppTheme.onSurface.withValues(alpha: 0.38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Etalonnage des couleurs',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasChanges
                              ? AppTheme.primaryColor
                              : AppTheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        'Courbes RGB, HSL, Roues de couleurs',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppTheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chroma Key Section ──────────────────────────────────────────────────

class _ChromaKeySection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _ChromaKeySection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final chroma = layer.chromaKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle
        Row(
          children: [
            Text(
              'Activer',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
            const Spacer(),
            Switch(
              value: chroma.enabled,
              onChanged: (v) {
                ref
                    .read(editorProvider.notifier)
                    .updateChromaKey(layer.id, chroma.copyWith(enabled: v));
              },
            ),
          ],
        ),
        if (chroma.enabled) ...[
          const SizedBox(height: 8),
          // Color picker
          Row(
            children: [
              Text(
                'Couleur cle',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final color = await showDialog<Color>(
                    context: context,
                    builder: (ctx) =>
                        _ChromaKeyColorPicker(initialColor: chroma.keyColor),
                  );
                  if (color != null) {
                    final hex =
                        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                    ref
                        .read(editorProvider.notifier)
                        .updateChromaKey(
                          layer.id,
                          chroma.copyWith(keyColor: hex),
                        );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parseHexColor(chroma.keyColor),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                chroma.keyColor,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurface.withValues(alpha: 0.38),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Similarity
          _ChromaSlider(
            label: 'Similarite',
            value: chroma.similarity,
            min: 0,
            max: 1,
            onChanged: (v) => ref
                .read(editorProvider.notifier)
                .updateChromaKey(layer.id, chroma.copyWith(similarity: v)),
          ),
          // Smoothness
          _ChromaSlider(
            label: 'Lissage',
            value: chroma.smoothness,
            min: 0,
            max: 1,
            onChanged: (v) => ref
                .read(editorProvider.notifier)
                .updateChromaKey(layer.id, chroma.copyWith(smoothness: v)),
          ),
          // Spill
          _ChromaSlider(
            label: 'Reduction de reflets',
            value: chroma.spill,
            min: 0,
            max: 1,
            onChanged: (v) => ref
                .read(editorProvider.notifier)
                .updateChromaKey(layer.id, chroma.copyWith(spill: v)),
          ),
        ],
      ],
    );
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF00FF00);
    }
  }
}

class _ChromaSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ChromaSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderRow(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      valueLabel: (v) => v.toStringAsFixed(2),
    );
  }
}

class _ChromaKeyColorPicker extends StatefulWidget {
  final String initialColor;
  const _ChromaKeyColorPicker({required this.initialColor});

  @override
  State<_ChromaKeyColorPicker> createState() => _ChromaKeyColorPickerState();
}

class _ChromaKeyColorPickerState extends State<_ChromaKeyColorPicker> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    try {
      _selectedColor = Color(
        int.parse(widget.initialColor.replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      _selectedColor = const Color(0xFF00FF00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      title: Text(
        'Choisir la couleur cle',
        style: TextStyle(color: AppTheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Common chroma key colors
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _colorChip('Vert', const Color(0xFF00FF00)),
              _colorChip('Bleu', const Color(0xFF0000FF)),
              _colorChip('Rouge', const Color(0xFFFF0000)),
              _colorChip('Cyan', const Color(0xFF00FFFF)),
              _colorChip('Magenta', const Color(0xFFFF00FF)),
              _colorChip('Jaune', const Color(0xFFFFFF00)),
            ],
          ),
          const SizedBox(height: 12),
          // Fine-tune with color picker
          Row(
            children: [
              Text(
                'R',
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _selectedColor.r,
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(
                    () => _selectedColor = _selectedColor.withRed(
                      (v * 255).round(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'G',
                style: TextStyle(color: Colors.green.shade400, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _selectedColor.g,
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(
                    () => _selectedColor = _selectedColor.withGreen(
                      (v * 255).round(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'B',
                style: TextStyle(color: Colors.blue.shade400, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _selectedColor.b,
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(
                    () => _selectedColor = _selectedColor.withBlue(
                      (v * 255).round(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.54)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
        ),
      ],
    );
  }

  Widget _colorChip(String label, Color color) {
    final isSelected = _selectedColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.onSurface
                : color.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppTheme.onSurface
                : AppTheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ─── Beat Sync Section ─────────────────────────────────────────────────

class _BeatSyncSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _BeatSyncSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final hasBeats = state.beatMarkers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Beat Sync',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ),
            // Detect beats button
            if (!hasBeats)
              TextButton.icon(
                onPressed: () =>
                    ref.read(editorProvider.notifier).detectBeats(),
                icon: const Icon(LucideIcons.music, size: 14),
                label: Text(
                  'Detect',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  foregroundColor: AppTheme.secondaryColor,
                ),
              ),
            // Toggle beat sync for this layer
            Switch(
              value: layer.beatSync,
              onChanged: hasBeats
                  ? (v) => ref
                        .read(editorProvider.notifier)
                        .toggleLayerBeatSync(layer.id)
                  : null,
            ),
          ],
        ),
        if (hasBeats)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${state.beatMarkers.length} beats detected',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Noise Gate Section ────────────────────────────────────────────────

class _NoiseGateSection extends StatelessWidget {
  final Layer layer;
  final WidgetRef ref;

  const _NoiseGateSection({required this.layer, required this.ref});

  @override
  Widget build(BuildContext context) {
    final threshold = layer.noiseGateThreshold;
    final isActive = threshold > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Noise Gate',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ),
            Text(
              isActive ? '${(threshold * 100).round()}%' : 'Off',
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.onSurface.withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderRow(
          label: '',
          value: threshold,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (v) =>
              ref.read(editorProvider.notifier).updateNoiseGate(layer.id, v),
          valueLabel: (v) => '${(v * 100).round()}%',
        ),
      ],
    );
  }
}

// ─── Ducking Section ──────────────────────────────────────────────────

class _DuckingSection extends StatelessWidget {
  final WidgetRef ref;

  const _DuckingSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final project = state.currentProject;
    if (project == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Mixage Audio'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: project.duckingEnabled
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : AppTheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: project.duckingEnabled
                  ? AppTheme.primaryColor.withValues(alpha: 0.4)
                  : AppTheme.outlineVariant.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.volume2,
                size: 20,
                color: project.duckingEnabled
                    ? AppTheme.primaryColor
                    : AppTheme.onSurface.withValues(alpha: 0.38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Ducking',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Lower music when speech is present',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: project.duckingEnabled,
                onChanged: (v) =>
                    ref.read(editorProvider.notifier).toggleDucking(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
