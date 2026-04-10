import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/canvas_background.dart';
import '../editor_state.dart';

/// Bottom sheet that displays canvas background presets.
void showCanvasBackgroundPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CanvasBackgroundPickerSheet(),
  );
}

class _CanvasBackgroundPickerSheet extends ConsumerWidget {
  const _CanvasBackgroundPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(editorProvider.select((s) => s.currentProject));
    final currentBgId = project?.canvasBackgroundId ?? 'black';

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
              'Canvas Background',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Grid of backgrounds
          SizedBox(
            height: 240,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: kCanvasBackgrounds.length,
              itemBuilder: (context, index) {
                final bg = kCanvasBackgrounds[index];
                final isSelected = bg.id == currentBgId;
                return _BackgroundTile(
                  background: bg,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(editorProvider.notifier).setCanvasBackground(bg.id);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final CanvasBackground background;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackgroundTile({
    required this.background,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildPreview(),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            background.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    switch (background.type) {
      case 'solid':
        return Container(color: background.getColor1());
      case 'gradient':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [background.getColor1(), background.getColor2()],
            ),
          ),
        );
      case 'blur':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[800]!, Colors.grey[600]!],
            ),
          ),
          child: const Center(
            child: Icon(Icons.blur_on, color: Colors.white54, size: 24),
          ),
        );
      default:
        return Container(color: Colors.black);
    }
  }
}
