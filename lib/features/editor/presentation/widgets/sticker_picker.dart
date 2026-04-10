import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/sticker.dart';
import '../editor_state.dart';

/// Bottom sheet that displays the built-in sticker library with category filters.
void showStickerPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _StickerPickerSheet(),
  );
}

class _StickerPickerSheet extends ConsumerStatefulWidget {
  const _StickerPickerSheet();

  @override
  ConsumerState<_StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends ConsumerState<_StickerPickerSheet> {
  String _selectedCategory = 'all';

  List<Sticker> get _filteredStickers {
    if (_selectedCategory == 'all') return kBuiltInStickers;
    return kBuiltInStickers.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Stickers & Emojis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kStickerCategories.length,
              itemBuilder: (context, index) {
                final cat = kStickerCategories[index];
                final isSelected = cat['value'] == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(right: index < kStickerCategories.length - 1 ? 8 : 0),
                  child: _FilterChip(
                    label: cat['label']!,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedCategory = cat['value']!),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Sticker grid
          SizedBox(
            height: 280,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _filteredStickers.length,
              itemBuilder: (context, index) {
                final sticker = _filteredStickers[index];
                return _StickerTile(sticker: sticker);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StickerTile extends ConsumerWidget {
  final Sticker sticker;
  const _StickerTile({required this.sticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(editorProvider.notifier).addStickerLayer(
          stickerId: sticker.id,
          emoji: sticker.emoji,
          size: sticker.defaultSize,
        );
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sticker.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              sticker.name,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
