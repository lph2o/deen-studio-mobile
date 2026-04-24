import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorToHex;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/contrast_checker.dart';
import '../../../../core/theme.dart';
import '../../../../core/models/quran_text_animations.dart';
import '../../../../core/ui/design_system.dart';
import '../../../../models/text_layer_style.dart';
import '../../../../models/text_style_preset.dart';
import '../../../../models/project.dart';
import '../editor_state.dart';
import 'font_picker_widget.dart';
import 'quran_animation_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text Editor Panel
// ─────────────────────────────────────────────────────────────────────────────

class TextEditorPanel extends ConsumerStatefulWidget {
  final Layer layer;
  final int initialIndex;

  const TextEditorPanel({
    super.key,
    required this.layer,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends ConsumerState<TextEditorPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  late TextLayerStyle _style;
  String _presetCategory = 'tendance';

  static const _tabs = ['Clavier', 'Modèle', 'Style', 'Police', 'An.'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialIndex,
      length: _tabs.length,
      vsync: this,
    );
    _style = widget.layer.textStyle ?? const TextLayerStyle();
    _textController = TextEditingController(text: widget.layer.content);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref
        .read(editorProvider.notifier)
        .updateLayerContent(widget.layer.id, _textController.text);
  }

  void _updateStyle(TextLayerStyle newStyle) {
    setState(() => _style = newStyle);
    ref
        .read(editorProvider.notifier)
        .updateLayerTextStyle(widget.layer.id, newStyle);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.onSurface.withValues(alpha: 0.4),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKeyboardTab(),
                _buildModelsTab(theme),
                _buildStyleTab(theme),
                _buildFontTab(theme),
                _buildAnimationTab(theme),
              ],
            ),
          ),

          // Confirm button
          _buildConfirmBar(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 1: Clavier (Text Input)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKeyboardTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bold / Italic / Size row
          _buildQuickFormatRow(),
          const SizedBox(height: 12),

          // Alignment row
          _buildAlignmentRow(),
          const SizedBox(height: 12),

          // Text input field
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                minLines: 3,
                textDirection: _style.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(color: AppTheme.onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Saisissez votre texte...',
                  hintStyle: TextStyle(
                    color: AppTheme.onSurface.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onChanged: (v) {
                  // Auto-detect RTL
                  final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(v);
                  if (hasArabic != _style.isRTL) {
                    _updateStyle(_style.copyWith(isRTL: hasArabic));
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Character counter
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_textController.text.length} caractères',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFormatRow() {
    return Row(
      children: [
        PillButton(
          label: 'B',
          selected: _style.isBold,
          onTap: () => _updateStyle(_style.copyWith(isBold: !_style.isBold)),
        ),
        const SizedBox(width: 8),
        PillButton(
          label: 'I',
          selected: _style.isItalic,
          onTap: () =>
              _updateStyle(_style.copyWith(isItalic: !_style.isItalic)),
        ),
        const SizedBox(width: 8),
        PillButton(
          label: 'Tl',
          selected: _style.isUppercase,
          onTap: () =>
              _updateStyle(_style.copyWith(isUppercase: !_style.isUppercase)),
        ),
        const Spacer(),
        // RTL toggle
        GestureDetector(
          onTap: () => _updateStyle(_style.copyWith(isRTL: !_style.isRTL)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _style.isRTL
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : AppTheme.surfaceHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _style.isRTL
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : AppTheme.outlineVariant.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              _style.isRTL ? 'RTL' : 'LTR',
              style: GoogleFonts.inter(
                color: _style.isRTL
                    ? AppTheme.primaryColor
                    : AppTheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Alignement',
          style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            _alignBtn(Icons.format_align_left_rounded, TextAlign.left),
            _alignBtn(Icons.format_align_center_rounded, TextAlign.center),
            _alignBtn(Icons.format_align_right_rounded, TextAlign.right),
            _alignBtn(Icons.format_align_justify_rounded, TextAlign.justify),
          ],
        ),
      ],
    );
  }

  Widget _alignBtn(IconData icon, TextAlign align) {
    final isActive = _style.textAlign == align;
    return GestureDetector(
      onTap: () => _updateStyle(_style.copyWith(textAlign: align)),
      child: Container(
        width: 36,
        height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : AppTheme.surfaceHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : AppTheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? AppTheme.primaryColor
              : AppTheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 2: Modèle (Style Presets Grid)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModelsTab(ThemeData theme) {
    final categories = ['tendance', 'general', 'colore', 'musulman'];
    final categoryLabels = {
      'tendance': 'Tendance',
      'general': 'General',
      'colore': 'Colore',
      'musulman': 'Islamique',
    };

    final filtered = kBuiltInPresets
        .where((p) => p.category == _presetCategory)
        .toList();

    return Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: categories.map((cat) {
              final isSelected = cat == _presetCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillButton(
                  label: categoryLabels[cat] ?? cat,
                  selected: isSelected,
                  onTap: () => setState(() => _presetCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),

        // Preset grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final preset = filtered[i];
              return GestureDetector(
                onTap: () => _updateStyle(preset.style),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.15),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: PresetPreviewPainter(preset),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 3: Style (Color, Text properties, Position, Border)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStyleTab(ThemeData theme) {
    final isSpecialText = widget.layer.type == 'translation' ||
        widget.layer.type == 'phonetic' ||
        widget.layer.type == 'text';

    return DefaultTabController(
      length: isSpecialText ? 5 : 4,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.onSurface.withValues(alpha: 0.4),
            indicatorColor: AppTheme.primaryColor,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              const Tab(text: 'Couleur'),
              const Tab(text: 'Texte'),
              const Tab(text: 'Position'),
              const Tab(text: 'Bordure'),
              if (isSpecialText) const Tab(text: 'Captions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildColorSubTab(theme),
                _buildTextSubTab(theme),
                _buildPositionSubTab(theme),
                _buildBorderSubTab(theme),
                if (isSpecialText) _buildCaptionsSubTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSubTab(ThemeData theme) {
    final fgColor = TextLayerStyle.parseHexColor(_style.color);
    final bgColor = _style.backgroundColor != null
        ? TextLayerStyle.parseHexColor(_style.backgroundColor!)
        : null;
    final contrastInfo = bgColor != null
        ? ContrastChecker.complianceLabel(fgColor, bgColor)
        : null;
    final contrastColor = bgColor != null
        ? ContrastChecker.complianceColor(fgColor, bgColor)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Solid / Gradient toggle
        Row(
          children: [
            _subToggleBtn(
              'Couleur',
              _style.gradientStyle == null,
              onTap: () {
                _updateStyle(_style.copyWith(clearGradient: true));
              },
            ),
            const SizedBox(width: 8),
            _subToggleBtn(
              'Dégradé',
              _style.gradientStyle != null,
              onTap: () {
                if (_style.gradientStyle == null) {
                  _updateStyle(
                    _style.copyWith(gradientStyle: const GradientTextStyle()),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_style.gradientStyle == null) ...[
          // Solid color row
          const Text(
            'Couleur du texte',
            style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildColorSwatches(
            _style.color,
            (hex) => _updateStyle(_style.copyWith(color: hex)),
          ),
          const SizedBox(height: 8),
          _buildColorPickerRow(
            _style.color,
            'Couleur personnalisee',
            (hex) => _updateStyle(_style.copyWith(color: hex)),
          ),
        ] else ...[
          const Text(
            'Couleur de debut',
            style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildColorPickerRow(
            _style.gradientStyle!.colors.first,
            'Couleur 1',
            (hex) => _updateStyle(
              _style.copyWith(
                gradientStyle: _style.gradientStyle!.copyWith(
                  colors: [hex, _style.gradientStyle!.colors.last],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Couleur de fin',
            style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildColorPickerRow(
            _style.gradientStyle!.colors.last,
            'Couleur 2',
            (hex) => _updateStyle(
              _style.copyWith(
                gradientStyle: _style.gradientStyle!.copyWith(
                  colors: [_style.gradientStyle!.colors.first, hex],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildSliderRow(
            label: 'Angle',
            value: _style.gradientStyle!.angleRadians,
            min: 0,
            max: 6.28,
            onChanged: (v) => _updateStyle(
              _style.copyWith(
                gradientStyle: _style.gradientStyle!.copyWith(angleRadians: v),
              ),
            ),
            displayValue:
                '${(_style.gradientStyle!.angleRadians * 57.3).round()}°',
          ),
        ],

        const SizedBox(height: 14),

        // Opacity slider
        _buildSliderRow(
          label: 'Opacité',
          value: _style.opacity,
          min: 0,
          max: 1,
          onChanged: (v) => _updateStyle(_style.copyWith(opacity: v)),
          displayValue: '${(_style.opacity * 100).round()}',
        ),

        const SizedBox(height: 14),

        // Fond de texte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fond de texte',
              style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
            ),
            Switch(
              value: _style.backgroundColor != null,
              onChanged: (v) {
                if (v) {
                  _updateStyle(_style.copyWith(backgroundColor: '#000000'));
                } else {
                  _updateStyle(_style.copyWith(clearBackground: true));
                }
              },
            ),
          ],
        ),
        if (_style.backgroundColor != null)
          _buildColorPickerRow(
            _style.backgroundColor!,
            'Couleur fond',
            (hex) => _updateStyle(_style.copyWith(backgroundColor: hex)),
          ),

        // WCAG info
        if (contrastInfo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: contrastColor!.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: contrastColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.accessibility_new_rounded,
                  size: 14,
                  color: contrastColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Contraste WCAG: $contrastInfo',
                  style: TextStyle(color: contrastColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextSubTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bold / Italic / Underline / Strikethrough
        Row(
          children: [
            PillButton(
              label: 'B',
              selected: _style.isBold,
              onTap: () =>
                  _updateStyle(_style.copyWith(isBold: !_style.isBold)),
            ),
            const SizedBox(width: 8),
            PillButton(
              label: 'I',
              selected: _style.isItalic,
              onTap: () =>
                  _updateStyle(_style.copyWith(isItalic: !_style.isItalic)),
            ),
            const SizedBox(width: 8),
            PillButton(
              label: 'Tl',
              selected: _style.isUppercase,
              onTap: () => _updateStyle(
                _style.copyWith(isUppercase: !_style.isUppercase),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Font size
        _buildSliderRow(
          label: 'Taille du texte',
          value: _style.fontSize,
          min: 12,
          max: 200,
          onChanged: (v) => _updateStyle(_style.copyWith(fontSize: v)),
          displayValue: _style.fontSize.round().toString(),
        ),
        const SizedBox(height: 12),

        // Letter spacing
        _buildSliderRow(
          label: 'Espacement des caractères',
          value: _style.letterSpacing,
          min: -5,
          max: 50,
          onChanged: (v) => _updateStyle(_style.copyWith(letterSpacing: v)),
          displayValue: _style.letterSpacing.round().toString(),
        ),
        const SizedBox(height: 12),

        // Line height
        _buildSliderRow(
          label: 'Espacement des lignes',
          value: _style.lineHeight,
          min: 0.5,
          max: 3.0,
          onChanged: (v) => _updateStyle(_style.copyWith(lineHeight: v)),
          displayValue: _style.lineHeight.toStringAsFixed(1),
        ),
        const SizedBox(height: 12),

        // Word spacing
        _buildSliderRow(
          label: 'Espacement des mots',
          value: _style.wordSpacing,
          min: 0,
          max: 100,
          onChanged: (v) => _updateStyle(_style.copyWith(wordSpacing: v)),
          displayValue: _style.wordSpacing.round().toString(),
        ),

        const SizedBox(height: 16),
        // Font Weight chips
        const Text(
          'Graisse',
          style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _buildFontWeightChips(),

        // Shadow section
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ombre',
              style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
            ),
            Switch(
              value:
                  _style.shadowBlur > 0 ||
                  _style.shadowOffsetX != 0 ||
                  _style.shadowOffsetY != 0,
              onChanged: (v) {
                if (!v) {
                  _updateStyle(
                    _style.copyWith(
                      shadowBlur: 0.0,
                      shadowOffsetX: 0.0,
                      shadowOffsetY: 0.0,
                    ),
                  );
                } else {
                  _updateStyle(
                    _style.copyWith(shadowBlur: 10.0, shadowOffsetY: 4.0),
                  );
                }
              },
            ),
          ],
        ),
        if (_style.shadowBlur > 0 ||
            _style.shadowOffsetX != 0 ||
            _style.shadowOffsetY != 0) ...[
          _buildColorPickerRow(
            _style.shadowColor,
            'Couleur ombre',
            (hex) => _updateStyle(_style.copyWith(shadowColor: hex)),
          ),
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Flou',
            value: _style.shadowBlur,
            min: 0,
            max: 50,
            onChanged: (v) => _updateStyle(_style.copyWith(shadowBlur: v)),
            displayValue: _style.shadowBlur.round().toString(),
          ),
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Décal. X',
            value: _style.shadowOffsetX,
            min: -50,
            max: 50,
            onChanged: (v) => _updateStyle(_style.copyWith(shadowOffsetX: v)),
            displayValue: _style.shadowOffsetX.round().toString(),
          ),
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Décal. Y',
            value: _style.shadowOffsetY,
            min: -50,
            max: 50,
            onChanged: (v) => _updateStyle(_style.copyWith(shadowOffsetY: v)),
            displayValue: _style.shadowOffsetY.round().toString(),
          ),
        ],
      ],
    );
  }

  Widget _buildCaptionsSubTab(ThemeData theme) {
    final presets = [
      (id: 'none', label: 'Aucun', icon: Icons.text_fields),
      (id: 'bubble', label: 'Bulle', icon: Icons.chat_bubble_outline),
      (id: 'glow', label: 'Lueur', icon: Icons.wb_sunny_outlined),
      (id: 'neon', label: 'Néon', icon: Icons.flash_on),
      (id: 'outline', label: 'Bordure', icon: Icons.check_box_outline_blank),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Presets de Styles',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = presets[index];
              final isSelected = (_style.captionStyleId ?? 'none') == p.id;

              return GestureDetector(
                onTap: () => _applyCaptionPreset(p.id),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : AppTheme.surfaceHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.outlineVariant.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        p.icon,
                        size: 24,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        if (_style.captionStyleId != null &&
            _style.captionStyleId != 'none') ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          if (_style.captionStyleId == 'bubble') ...[
            _buildSliderRow(
              label: 'Padding',
              value: _style.backgroundPadding,
              min: 4,
              max: 40,
              onChanged: (v) =>
                  _updateStyle(_style.copyWith(backgroundPadding: v)),
              displayValue: _style.backgroundPadding.round().toString(),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'Arrondi',
              value: _style.borderRadius,
              min: 0,
              max: 40,
              onChanged: (v) => _updateStyle(_style.copyWith(borderRadius: v)),
              displayValue: _style.borderRadius.round().toString(),
            ),
          ],

          if (_style.captionStyleId == 'glow' || _style.captionStyleId == 'neon')
            _buildSliderRow(
              label: 'Intensité Lueur',
              value: _style.glowBlur,
              min: 0,
              max: 40,
              onChanged: (v) => _updateStyle(_style.copyWith(glowBlur: v)),
              displayValue: _style.glowBlur.round().toString(),
            ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Couleur de Fond',
                style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
              ),
              GestureDetector(
                onTap: () => _showColorPicker(
                  TextLayerStyle.parseHexColor(_style.backgroundColor ?? '#000000'),
                  (hex) => _updateStyle(_style.copyWith(backgroundColor: hex)),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: TextLayerStyle.parseHexColor(_style.backgroundColor ?? '#000000'),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _applyCaptionPreset(String id) {
    TextLayerStyle updated = _style;

    switch (id) {
      case 'none':
        updated = _style.copyWith(
          clearCaptionStyle: true,
          clearBackground: true,
          glowBlur: 0,
          strokeWidth: 0,
        );
        break;
      case 'bubble':
        updated = _style.copyWith(
          captionStyleId: 'bubble',
          backgroundColor: '#000000',
          backgroundPadding: 12,
          borderRadius: 12,
          color: '#FFFFFF',
        );
        break;
      case 'glow':
        updated = _style.copyWith(
          captionStyleId: 'glow',
          glowBlur: 8,
          glowColor: _style.color,
        );
        break;
      case 'neon':
        updated = _style.copyWith(
          captionStyleId: 'neon',
          glowBlur: 12,
          glowColor: _style.color,
          isBold: true,
        );
        break;
      case 'outline':
        updated = _style.copyWith(
          captionStyleId: 'outline',
          strokeWidth: 2.5,
          strokeColor: '#000000',
          shadowColor: '#000000',
          shadowBlur: 6,
          shadowOffsetX: 2,
          shadowOffsetY: 2,
        );
        break;
    }
    _updateStyle(updated);
  }

  Widget _buildPositionSubTab(ThemeData theme) {
    // Get the latest layer from editor state for current transform values
    final editorState = ref.watch(editorProvider);
    final currentLayer = editorState.currentProject?.layers
        .where((l) => l.id == widget.layer.id)
        .firstOrNull;
    final transform = currentLayer?.transform ?? widget.layer.transform;

    // Map normalized (0.0-1.0) to percentage (-100% to +100%, where 0.5 = center)
    final positionXPercent = (transform.x * 200 - 100).round();
    final positionYPercent = (transform.y * 200 - 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Alignement horizontal',
          style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _buildAlignmentRow(),
        const SizedBox(height: 20),

        // Position X slider
        _buildSliderRow(
          label: 'Position X',
          value: positionXPercent.toDouble(),
          min: -100,
          max: 100,
          onChanged: (v) {
            final normalizedX = (v + 100) / 200;
            ref
                .read(editorProvider.notifier)
                .updateLayerTransform(
                  widget.layer.id,
                  transform.copyWith(x: normalizedX),
                );
          },
          displayValue: '${positionXPercent > 0 ? '+' : ''}$positionXPercent%',
        ),
        const SizedBox(height: 12),

        // Position Y slider
        _buildSliderRow(
          label: 'Position Y',
          value: positionYPercent.toDouble(),
          min: -100,
          max: 100,
          onChanged: (v) {
            final normalizedY = (v + 100) / 200;
            ref
                .read(editorProvider.notifier)
                .updateLayerTransform(
                  widget.layer.id,
                  transform.copyWith(y: normalizedY),
                );
          },
          displayValue: '${positionYPercent > 0 ? '+' : ''}$positionYPercent%',
        ),
        const SizedBox(height: 20),

        const Text(
          'Direction du texte',
          style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _subToggleBtn(
              'LTR →',
              !_style.isRTL,
              onTap: () => _updateStyle(_style.copyWith(isRTL: false)),
            ),
            const SizedBox(width: 8),
            _subToggleBtn(
              '← RTL',
              _style.isRTL,
              onTap: () => _updateStyle(_style.copyWith(isRTL: true)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBorderSubTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Underline
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Souligné',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Switch(
              value: _style.underline,
              onChanged: (v) => _updateStyle(_style.copyWith(underline: v)),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Barré',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Switch(
              value: _style.strikethrough,
              onChanged: (v) => _updateStyle(_style.copyWith(strikethrough: v)),
            ),
          ],
        ),
        Divider(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
        const SizedBox(height: 8),

        // Stroke
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contour (Stroke)',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Switch(
              value: _style.strokeWidth > 0,
              onChanged: (v) {
                _updateStyle(_style.copyWith(strokeWidth: v ? 4.0 : 0.0));
              },
            ),
          ],
        ),
        if (_style.strokeWidth > 0) ...[
          _buildColorPickerRow(
            _style.strokeColor,
            'Couleur contour',
            (hex) => _updateStyle(_style.copyWith(strokeColor: hex)),
          ),
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Épaisseur contour',
            value: _style.strokeWidth,
            min: 0,
            max: 20,
            onChanged: (v) => _updateStyle(_style.copyWith(strokeWidth: v)),
            displayValue: _style.strokeWidth.round().toString(),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 4: Police (Font Picker)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFontTab(ThemeData theme) {
    return FontPickerWidget(
      selectedFont: _style.fontFamily,
      onFontSelected: (font) {
        final forceRTL = FontCatalogue.isArabic(font);
        _updateStyle(_style.copyWith(fontFamily: font, isRTL: forceRTL));
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tab 5: Animation
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAnimationTab(ThemeData theme) {
    final currentQuranAnim = _style.quranAnimationId.isNotEmpty
        ? getQuranAnimationById(_style.quranAnimationId)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // -- Animations Coraniques section --
        ControlGroup(
          title: 'Animations Coraniques',
          icon: Icons.auto_awesome,
          children: [
            if (currentQuranAnim != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${currentQuranAnim.icon} ${currentQuranAnim.name}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(editorProvider.notifier)
                          .applyAnimationToAllArabicLayers(currentQuranAnim.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Animation appliquée à tous les versets',
                          ),
                          backgroundColor: AppTheme.primaryColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.done_all, size: 14),
                    label: const Text(
                      'Appliquer à tous',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              'Plus de 40 animations exclusives pour le contenu coranique',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showQuranAnimationPicker(
                        context: context,
                        onSelected: (anim) {
                          _updateStyle(
                            _style.copyWith(
                              quranAnimationId: anim.id,
                              animationPreset: TextAnimationPreset.none,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        currentAnimationId: _style.quranAnimationId,
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text(
                      'Choisir une animation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                if (currentQuranAnim != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _updateStyle(_style.copyWith(quranAnimationId: ''));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Divider ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppTheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OU',
                style: TextStyle(
                  color: AppTheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppTheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Animations standards ─────────────────────────────────────────
        Text(
          'Preset d\'animation',
          style: TextStyle(
            color: AppTheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: DropdownButton<TextAnimationPreset>(
            value: _style.animationPreset,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.surfaceContainer,
            style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
            onChanged: (v) {
              if (v != null) _updateStyle(_style.copyWith(animationPreset: v));
            },
            items: TextAnimationPreset.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
          ),
        ),

        // -- Animation Config (Real-time controls) --
        if (_style.animationPreset != TextAnimationPreset.none ||
            _style.quranAnimationId.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Configuration Avancée',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (!_style.animationConfig.isDefault)
                TextButton(
                  onPressed: () => _updateStyle(
                    _style.copyWith(animationConfig: const AnimationConfig()),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Réinitialiser',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Speed
          _buildSliderRow(
            label: 'Vitesse',
            value: _style.animationConfig.durationMultiplier,
            min: 0.1,
            max: 10.0,
            onChanged: (v) => _updateStyle(
              _style.copyWith(
                animationConfig: _style.animationConfig.copyWith(
                  durationMultiplier: v,
                ),
              ),
            ),
            displayValue:
                '${_style.animationConfig.durationMultiplier.toStringAsFixed(1)}x',
          ),
          const SizedBox(height: 10),

          // Frequency
          _buildSliderRow(
            label: 'Fréquence',
            value: _style.animationConfig.frequency,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => _updateStyle(
              _style.copyWith(
                animationConfig: _style.animationConfig.copyWith(frequency: v),
              ),
            ),
            displayValue:
                '${(_style.animationConfig.frequency * 100).round()}%',
          ),
          const SizedBox(height: 10),

          // Intensity
          _buildSliderRow(
            label: 'Intensité',
            value: _style.animationConfig.intensity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => _updateStyle(
              _style.copyWith(
                animationConfig: _style.animationConfig.copyWith(intensity: v),
              ),
            ),
            displayValue:
                '${(_style.animationConfig.intensity * 100).round()}%',
          ),
          const SizedBox(height: 10),

          // Direction
          _buildSliderRow(
            label: 'Direction',
            value: _style.animationConfig.direction,
            min: 0,
            max: 360,
            onChanged: (v) => _updateStyle(
              _style.copyWith(
                animationConfig: _style.animationConfig.copyWith(direction: v),
              ),
            ),
            displayValue: '${_style.animationConfig.direction.round()}°',
          ),
          const SizedBox(height: 10),

          // Animation Color
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Couleur d\'effet',
                style: TextStyle(color: AppTheme.onSurface, fontSize: 12),
              ),
              GestureDetector(
                onTap: () => _showColorPicker(
                  TextLayerStyle.parseHexColor(_style.animationConfig.color),
                  (hex) => _updateStyle(
                    _style.copyWith(
                      animationConfig: _style.animationConfig.copyWith(
                        color: hex,
                      ),
                    ),
                  ),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: TextLayerStyle.parseHexColor(
                      _style.animationConfig.color,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_style.animationPreset != TextAnimationPreset.none) ...[
          const SizedBox(height: 24),
          const Text(
            'Durées de transition',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: 'Durée d\'entrée',
            value: _style.animationInDuration,
            min: 0.1,
            max: 5.0,
            onChanged: (v) =>
                _updateStyle(_style.copyWith(animationInDuration: v)),
            displayValue: '${_style.animationInDuration.toStringAsFixed(1)}s',
          ),
          const SizedBox(height: 10),
          _buildSliderRow(
            label: 'Durée de sortie',
            value: _style.animationOutDuration,
            min: 0.1,
            max: 5.0,
            onChanged: (v) =>
                _updateStyle(_style.copyWith(animationOutDuration: v)),
            displayValue: '${_style.animationOutDuration.toStringAsFixed(1)}s',
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Confirm Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildConfirmBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared UI Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static const _swatchColors = [
    '#FFFFFF',
    '#000000',
    '#ef4444',
    '#f97316',
    '#facc15',
    '#4ade80',
    '#38bdf8',
    '#818cf8',
    '#c084fc',
    '#f472b6',
    '#94a3b8',
    '#6ee7b7',
  ];

  Widget _buildColorSwatches(String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _swatchColors.map((hex) {
        final isSelected = hex.toLowerCase() == selected.toLowerCase();
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TextLayerStyle.parseHexColor(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.outlineVariant.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: AppTheme.onPrimaryColor,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPickerRow(
    String hexColor,
    String label,
    ValueChanged<String> onChanged,
  ) {
    final color = TextLayerStyle.parseHexColor(hexColor);
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showColorPicker(color, onChanged),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showColorPicker(color, onChanged),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                hexColor.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color initial, ValueChanged<String> onChanged) {
    Color pickerColor = initial;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (c) => pickerColor = c,
              enableAlpha: false,
              labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
              pickerAreaHeightPercent: 0.6,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                onChanged(colorToHex(pickerColor));
                Navigator.pop(context);
              },
              child: const Text('Confirmer'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String displayValue,
  }) {
    return SliderRow(
      label: label,
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChanged: onChanged,
      valueLabel: (_) => displayValue,
    );
  }

  Widget _buildFontWeightChips() {
    const weights = [
      ('Thin', FontWeight.w100),
      ('Light', FontWeight.w300),
      ('Regular', FontWeight.w400),
      ('Medium', FontWeight.w500),
      ('Bold', FontWeight.w700),
      ('Black', FontWeight.w900),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: weights.map(((String name, FontWeight weight) entry) {
        final isSelected = _style.fontWeight == entry.$2 && !_style.isBold;
        return GestureDetector(
          onTap: () => _updateStyle(
            _style.copyWith(fontWeight: entry.$2, isBold: false),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : AppTheme.surfaceHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : AppTheme.outlineVariant.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              entry.$1,
              style: TextStyle(
                fontWeight: entry.$2,
                fontSize: 11,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _subToggleBtn(
    String label,
    bool active, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryColor
              : AppTheme.surfaceHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : AppTheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? AppTheme.onPrimaryColor
                : AppTheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Show helper function
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showTextEditorPanel(
  BuildContext context,
  Layer layer, {
  int initialIndex = 0,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => TextEditorPanel(layer: layer, initialIndex: initialIndex),
  );
}
