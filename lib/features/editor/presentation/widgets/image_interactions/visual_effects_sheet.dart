import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../core/theme.dart';
import '../../../../../models/project.dart';
import '../color_grading_panel.dart';
import '../../editor_state.dart';

// ─── Public entry point ───────────────────────────────────────────────────────

Future<void> showVisualEffectsSheet(
  BuildContext context,
  String layerId, {
  int initialTab = 0,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VisualEffectsSheet(layerId: layerId, initialTab: initialTab),
  );
}

// ─── Main Sheet ───────────────────────────────────────────────────────────────

class VisualEffectsSheet extends ConsumerStatefulWidget {
  final String layerId;
  final int initialTab;

  const VisualEffectsSheet({super.key, required this.layerId, this.initialTab = 0});

  @override
  ConsumerState<VisualEffectsSheet> createState() => _VisualEffectsSheetState();
}

class _VisualEffectsSheetState extends ConsumerState<VisualEffectsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    ('Effets', LucideIcons.sparkles),
    ('Transform', LucideIcons.move),
    ('Masque', LucideIcons.scissors),
    ('Fusion', LucideIcons.layers),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final layer = state.currentProject?.layers.where((l) => l.id == widget.layerId).firstOrNull;

    if (layer == null) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Propriétés visuelles',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const Spacer(),
                // Color Grading shortcut
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showColorGradingPanel(context, widget.layerId, ref);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gradient_rounded, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Color Grading',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 2,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.onSurface.withValues(alpha: 0.4),
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
            tabs: _tabs.map((t) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.$2, size: 13),
                  const SizedBox(width: 6),
                  Text(t.$1),
                ],
              ),
            )).toList(),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EffectsTab(layer: layer),
                _TransformTab(layer: layer),
                _MaskTab(layer: layer),
                _BlendModeTab(layer: layer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Color Effects ─────────────────────────────────────────────────────

class _EffectsTab extends ConsumerWidget {
  final Layer layer;
  const _EffectsTab({required this.layer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read the latest layer to stay reactive
    final state = ref.watch(editorProvider);
    final live = state.currentProject?.layers.where((l) => l.id == layer.id).firstOrNull ?? layer;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _effectSlider(context, ref, live, 'Luminosité', 'brightness', -1, 1, 0,
            (v) => '${(v * 100).toInt()}%'),
        _effectSlider(context, ref, live, 'Contraste', 'contrast', -1, 1, 0,
            (v) => '${(v * 100).toInt()}%'),
        _effectSlider(context, ref, live, 'Saturation', 'saturation', 0, 2, 1,
            (v) => '${(v * 100).toInt()}%'),
        _effectSlider(context, ref, live, 'Flou (Gaussian)', 'blur', 0, 1, 0,
            (v) => '${(v * 20).toStringAsFixed(1)}σ'),
        const Divider(height: 28),
        Text('Effets avancés', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppTheme.onSurface.withValues(alpha: 0.4),
        )),
        const SizedBox(height: 12),
        _effectSlider(context, ref, live, 'Vignette', 'vignette', 0, 1, 0,
            (v) => '${(v * 100).toInt()}%'),
        _effectSlider(context, ref, live, 'Grain / Noise', 'noise', 0, 1, 0,
            (v) => '${(v * 100).toInt()}%'),
        _effectSlider(context, ref, live, 'Sharpen', 'sharpen', 0, 1, 0,
            (v) => '${(v * 100).toInt()}%'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réinitialiser tous les effets'),
          onPressed: () {
            ref.read(editorProvider.notifier).updateLayer(live.copyWith(effects: []));
          },
        ),
      ],
    );
  }

  Widget _effectSlider(
    BuildContext context,
    WidgetRef ref,
    Layer live,
    String label,
    String effectType,
    double min,
    double max,
    double defaultValue,
    String Function(double) displayFn,
  ) {
    final existing = live.effects.where((e) => e.type == effectType).firstOrNull;
    final enabled = existing?.enabled ?? false;
    final value = ((existing?.params['value'] as num?)?.toDouble() ?? defaultValue).clamp(min, max);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface.withValues(alpha: enabled ? 0.9 : 0.4),
                )),
              ),
              if (enabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(displayFn(value), style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  )),
                ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: enabled,
                activeTrackColor: AppTheme.primaryColor,
                onChanged: (on) {
                  final effect = ClipEffect(
                    id: effectType, type: effectType,
                    enabled: on,
                    params: {'value': on ? (effectType == 'saturation' ? 1.0 : defaultValue == 0 ? 0.3 : defaultValue) : value},
                  );
                  ref.read(editorProvider.notifier).applyEffect(live.id, effect);
                },
              ),
            ],
          ),
          if (enabled) ...[
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
                value: value, min: min, max: max,
                onChanged: (v) {
                  final effect = ClipEffect(
                    id: effectType, type: effectType,
                    enabled: true, params: {'value': v},
                  );
                  ref.read(editorProvider.notifier).applyEffect(live.id, effect);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 2: Transform ─────────────────────────────────────────────────────────

class _TransformTab extends ConsumerWidget {
  final Layer layer;
  const _TransformTab({required this.layer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final live = state.currentProject?.layers.where((l) => l.id == layer.id).firstOrNull ?? layer;
    final t = live.transform;

    void update(ClipTransform newT) =>
        ref.read(editorProvider.notifier).updateLayerTransform(live.id, newT);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSlider(context, 'Opacité', t.opacity, 0, 1,
            (v) => '${(v * 100).toInt()}%',
            (v) => update(t.copyWith(opacity: v))),
        _buildSlider(context, 'Rotation', t.rotation, -180, 180,
            (v) => '${v.toInt()}°',
            (v) => update(t.copyWith(rotation: v))),
        _buildSlider(context, 'Échelle X', t.scaleX, 0.1, 3.0,
            (v) => '${(v * 100).toInt()}%',
            (v) => update(t.copyWith(scaleX: v))),
        _buildSlider(context, 'Échelle Y', t.scaleY, 0.1, 3.0,
            (v) => '${(v * 100).toInt()}%',
            (v) => update(t.copyWith(scaleY: v))),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réinitialiser le transform'),
          onPressed: () => update(const ClipTransform()),
        ),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    String Function(double) displayFn,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.8),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(displayFn(value), style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                )),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.onSurface.withValues(alpha: 0.1),
              thumbColor: Colors.white,
            ),
            child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Mask ─────────────────────────────────────────────────────────────

class _MaskTab extends ConsumerWidget {
  final Layer layer;
  const _MaskTab({required this.layer});

  static const _maskLabels = <MaskType, String>{
    MaskType.none: 'Aucun',
    MaskType.rectangle: 'Rectangle',
    MaskType.circle: 'Cercle',
    MaskType.triangle: 'Triangle',
    MaskType.heart: 'Cœur',
    MaskType.star: 'Étoile',
    MaskType.splitHorizontal: 'Bande H',
    MaskType.splitVertical: 'Bande V',
  };

  static const _maskIcons = <MaskType, IconData>{
    MaskType.none: Icons.do_not_disturb_rounded,
    MaskType.rectangle: Icons.rectangle_rounded,
    MaskType.circle: Icons.circle_rounded,
    MaskType.triangle: Icons.change_history_rounded,
    MaskType.heart: Icons.favorite_rounded,
    MaskType.star: Icons.star_rounded,
    MaskType.splitHorizontal: Icons.horizontal_split_rounded,
    MaskType.splitVertical: Icons.vertical_split_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final live = state.currentProject?.layers.where((l) => l.id == layer.id).firstOrNull ?? layer;
    final mask = live.mask;

    void updateMask(LayerMask m) =>
        ref.read(editorProvider.notifier).updateLayerMask(live.id, m);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text('Forme du masque', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppTheme.onSurface.withValues(alpha: 0.4),
        )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MaskType.values.map((type) {
            final selected = mask.type == type;
            return GestureDetector(
              onTap: () => updateMask(mask.copyWith(type: type)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                      : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppTheme.primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _maskIcons[type] ?? Icons.rectangle_rounded,
                      size: 16,
                      color: selected ? AppTheme.primaryColor : AppTheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _maskLabels[type] ?? type.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? AppTheme.primaryColor : AppTheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (mask.type != MaskType.none) ...[
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildSlider(context, 'Taille', mask.value, 0, 1,
              (v) => '${(v * 100).toInt()}%',
              (v) => updateMask(mask.copyWith(value: v))),
          _buildSlider(context, 'Adoucissement', mask.feather, 0, 50,
              (v) => '${v.toInt()}px',
              (v) => updateMask(mask.copyWith(feather: v))),
          _buildSlider(context, 'Rotation', mask.rotation, -180, 180,
              (v) => '${v.toInt()}°',
              (v) => updateMask(mask.copyWith(rotation: v))),
        ],
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    String Function(double) displayFn,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.8),
              )),
              Text(displayFn(value), style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              )),
            ],
          ),
          Slider(
            value: value.clamp(min, max), min: min, max: max,
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: Blend Mode ────────────────────────────────────────────────────────

class _BlendModeTab extends ConsumerWidget {
  final Layer layer;
  const _BlendModeTab({required this.layer});

  static const _modes = [
    ('srcOver', 'Normal'),
    ('multiply', 'Multiply'),
    ('screen', 'Screen'),
    ('overlay', 'Overlay'),
    ('darken', 'Darken'),
    ('lighten', 'Lighten'),
    ('difference', 'Difference'),
    ('colorDodge', 'Color Dodge'),
    ('colorBurn', 'Color Burn'),
    ('hardLight', 'Hard Light'),
    ('softLight', 'Soft Light'),
    ('exclusion', 'Exclusion'),
  ];

  static const _modeColors = <String, List<Color>>{
    'srcOver':    [Color(0xFF667eea), Color(0xFF764ba2)],
    'multiply':   [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
    'screen':     [Color(0xFF1a1a2e), Color(0xFFe94560)],
    'overlay':    [Color(0xFF667eea), Color(0xFFe94560)],
    'darken':     [Color(0xFF2d3436), Color(0xFF636e72)],
    'lighten':    [Color(0xFFfdcb6e), Color(0xFFffeaa7)],
    'difference': [Color(0xFFe17055), Color(0xFF00b894)],
    'colorDodge': [Color(0xFFfd79a8), Color(0xFFfdcb6e)],
    'colorBurn':  [Color(0xFFd63031), Color(0xFFe17055)],
    'hardLight':  [Color(0xFF0984e3), Color(0xFF74b9ff)],
    'softLight':  [Color(0xFFa29bfe), Color(0xFF6c5ce7)],
    'exclusion':  [Color(0xFF55efc4), Color(0xFF00cec9)],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final live = state.currentProject?.layers.where((l) => l.id == layer.id).firstOrNull ?? layer;
    final current = live.blendMode;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text('Mode de fusion', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppTheme.onSurface.withValues(alpha: 0.4),
        )),
        const SizedBox(height: 12),
        ...(_modes.map((mode) {
          final isSelected = current == mode.$1;
          final colors = _modeColors[mode.$1] ?? [AppTheme.surfaceHigh, AppTheme.surfaceHigh];
          return GestureDetector(
            onTap: () => ref.read(editorProvider.notifier).updateBlendMode(live.id, mode.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mode.$2,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryColor),
                ],
              ),
            ),
          );
        }).toList()),
      ],
    );
  }
}
