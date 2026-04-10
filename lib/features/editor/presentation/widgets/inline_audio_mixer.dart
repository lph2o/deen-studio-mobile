import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme.dart';
import '../../../../models/project.dart';
import '../editor_state.dart';

/// ═══════════════════════════════════════════
/// Inline Audio Mixer Panel
/// ═══════════════════════════════════════════
///
/// A compact, tab-based audio adjustment panel
/// that appears directly in the bottom bar
/// when an audio layer is selected.
/// No dialogs, no "Apply" button — changes are live.

enum _MixerTab { volume, speed, fade }

class InlineAudioMixer extends StatefulWidget {
  final Layer audioLayer;
  final EditorState editorState;
  final Function(Map<String, dynamic> styleUpdates) onStyleUpdated;

  const InlineAudioMixer({
    super.key,
    required this.audioLayer,
    required this.editorState,
    required this.onStyleUpdated,
  });

  @override
  State<InlineAudioMixer> createState() => _InlineAudioMixerState();
}

class _InlineAudioMixerState extends State<InlineAudioMixer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _volume;
  late double _speed;
  late double _fadeIn;
  late double _fadeOut;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadValues();
  }

  @override
  void didUpdateWidget(InlineAudioMixer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioLayer.id != widget.audioLayer.id) {
      _loadValues();
    }
  }

  void _loadValues() {
    final layer = widget.audioLayer;
    _volume = (layer.style['volume'] as num?)?.toDouble() ?? 1.0;
    _speed = (layer.style['speed'] as num?)?.toDouble() ?? 1.0;
    _fadeIn = (layer.style['fadeIn'] as num?)?.toDouble() ?? 0.0;
    _fadeOut = (layer.style['fadeOut'] as num?)?.toDouble() ?? 0.0;
  }

  void _updateLayer() {
    widget.onStyleUpdated({
      'volume': _volume,
      'speed': _speed,
      'fadeIn': _fadeIn,
      'fadeOut': _fadeOut,
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab bar
        _TabBarWidget(
          controller: _tabController,
          tabs: const [
            _MixerTab.volume,
            _MixerTab.speed,
            _MixerTab.fade,
          ],
        ),
        const SizedBox(height: 12),
        // Tab content
        SizedBox(
          height: 100,
          child: TabBarView(
            controller: _tabController,
            children: [
              _VolumeTab(
                volume: _volume,
                onChanged: (v) {
                  setState(() => _volume = v);
                  _updateLayer();
                },
              ),
              _SpeedTab(
                speed: _speed,
                onChanged: (v) {
                  setState(() => _speed = v);
                  _updateLayer();
                },
              ),
              _FadeTab(
                fadeIn: _fadeIn,
                fadeOut: _fadeOut,
                onFadeInChanged: (v) {
                  setState(() => _fadeIn = v);
                  _updateLayer();
                },
                onFadeOutChanged: (v) {
                  setState(() => _fadeOut = v);
                  _updateLayer();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════
/// Tab Bar — compact icon+label tabs
/// ═══════════════════════════════════════════

class _TabBarWidget extends StatelessWidget {
  final TabController controller;
  final List<_MixerTab> tabs;

  const _TabBarWidget({
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.animateTo(index),
            child: _TabIndicator(
              tab: tab,
              isSelected: controller.index == index,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TabIndicator extends StatelessWidget {
  final _MixerTab tab;
  final bool isSelected;

  const _TabIndicator({
    required this.tab,
    required this.isSelected,
  });

  IconData get _icon {
    switch (tab) {
      case _MixerTab.volume:
        return LucideIcons.volume2;
      case _MixerTab.speed:
        return LucideIcons.gauge;
      case _MixerTab.fade:
        return LucideIcons.sun;
    }
  }

  String get _label {
    switch (tab) {
      case _MixerTab.volume:
        return 'Volume';
      case _MixerTab.speed:
        return 'Vitesse';
      case _MixerTab.fade:
        return 'Estomper';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 16,
            color: isSelected ? AppTheme.primaryColor : AppTheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 2),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primaryColor : AppTheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════
/// Volume Tab
/// ═══════════════════════════════════════════

class _VolumeTab extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _VolumeTab({required this.volume, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isMuted = volume == 0;
    final isLoud = volume > 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMuted ? LucideIcons.volumeX : isLoud ? LucideIcons.volume2 : LucideIcons.volume1,
              size: 14,
              color: isMuted ? Colors.red : AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${(volume * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isMuted ? Colors.red : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Slider
        _CompactSlider(
          value: volume,
          min: 0,
          max: 2,
          divisions: 20,
          activeColor: isMuted ? Colors.red : AppTheme.primaryColor,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        // Quick presets
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PresetButton(label: '0%', value: 0, current: volume, onTap: onChanged),
            _PresetButton(label: '50%', value: 0.5, current: volume, onTap: onChanged),
            _PresetButton(label: '100%', value: 1.0, current: volume, onTap: onChanged),
            _PresetButton(label: '150%', value: 1.5, current: volume, onTap: onChanged),
            _PresetButton(label: '200%', value: 2.0, current: volume, onTap: onChanged),
          ],
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════
/// Speed Tab
/// ═══════════════════════════════════════════

class _SpeedTab extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;

  const _SpeedTab({required this.speed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSlow = speed < 1.0;
    final isFast = speed > 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSlow ? LucideIcons.clock : isFast ? LucideIcons.zap : LucideIcons.gauge,
              size: 14,
              color: isSlow ? Colors.amber : isFast ? AppTheme.secondaryColor : AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${speed.toStringAsFixed(1)}x',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSlow ? Colors.amber : isFast ? AppTheme.secondaryColor : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Slider
        _CompactSlider(
          value: speed,
          min: 0.25,
          max: 4,
          divisions: 15,
          activeColor: isSlow ? Colors.amber : isFast ? AppTheme.secondaryColor : AppTheme.primaryColor,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        // Quick presets
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PresetButton(label: '0.5x', value: 0.5, current: speed, onTap: onChanged),
            _PresetButton(label: '0.75x', value: 0.75, current: speed, onTap: onChanged),
            _PresetButton(label: '1x', value: 1.0, current: speed, onTap: onChanged),
            _PresetButton(label: '1.5x', value: 1.5, current: speed, onTap: onChanged),
            _PresetButton(label: '2x', value: 2.0, current: speed, onTap: onChanged),
          ],
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════
/// Fade Tab
/// ═══════════════════════════════════════════

class _FadeTab extends StatelessWidget {
  final double fadeIn;
  final double fadeOut;
  final ValueChanged<double> onFadeInChanged;
  final ValueChanged<double> onFadeOutChanged;

  const _FadeTab({
    required this.fadeIn,
    required this.fadeOut,
    required this.onFadeInChanged,
    required this.onFadeOutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fade In
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'In',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: _CompactSlider(
                value: fadeIn,
                min: 0,
                max: 5,
                divisions: 10,
                activeColor: AppTheme.primaryColor,
                onChanged: onFadeInChanged,
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${fadeIn.toStringAsFixed(1)}s',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Fade Out
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'Out',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: _CompactSlider(
                value: fadeOut,
                min: 0,
                max: 5,
                divisions: 10,
                activeColor: AppTheme.secondaryColor,
                onChanged: onFadeOutChanged,
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${fadeOut.toStringAsFixed(1)}s',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════
/// Compact Slider
/// ═══════════════════════════════════════════

class _CompactSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _CompactSlider({
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: activeColor,
        inactiveTrackColor: activeColor.withValues(alpha: 0.12),
        thumbColor: activeColor,
        overlayColor: activeColor.withValues(alpha: 0.1),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// ═══════════════════════════════════════════
/// Preset Button
/// ═══════════════════════════════════════════

class _PresetButton extends StatelessWidget {
  final String label;
  final double value;
  final double current;
  final ValueChanged<double> onTap;

  const _PresetButton({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (current - value).abs() < 0.01;

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppTheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
