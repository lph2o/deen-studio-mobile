import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/color_filters.dart';
import '../../editor_state.dart';

/// Filter preset descriptor — display only.
class _FilterPreset {
  final String id;
  final String label;

  const _FilterPreset({required this.id, required this.label});
}

const _presets = [
  _FilterPreset(id: 'none',      label: 'Original'),
  _FilterPreset(id: 'grayscale', label: 'N\u0026B'),
  _FilterPreset(id: 'sepia',     label: 'Sépia'),
  _FilterPreset(id: 'warm',      label: 'Chaleur'),
  _FilterPreset(id: 'cool',      label: 'Froid'),
  _FilterPreset(id: 'vintage',   label: 'Vintage'),
  _FilterPreset(id: 'vivid',     label: 'Vivid'),
  _FilterPreset(id: 'fade',      label: 'Faded'),
];

class ImageFiltersSheet extends ConsumerWidget {
  final String layerId;
  final String imagePath;

  const ImageFiltersSheet({
    super.key,
    required this.layerId,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final layer = state.currentProject?.layers.where((l) => l.id == layerId).firstOrNull;
    final currentFilterId = layer?.filterId ?? 'none';

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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Filtres',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.onSurface.withValues(alpha: 0.5),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _presets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = currentFilterId == preset.id;
                return _FilterTile(
                  preset: preset,
                  imagePath: imagePath,
                  isSelected: isSelected,
                  onTap: () {
                    if (layer == null) return;
                    ref.read(editorProvider.notifier).updateLayer(
                      layer.copyWith(filterId: preset.id),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final _FilterPreset preset;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.preset,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = ColorMatrixUtils.forId(preset.id);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix),
                child: Image.file(
                  File(imagePath),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppTheme.surfaceHigh,
                    child: Icon(
                      Icons.image_rounded,
                      color: AppTheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preset.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
