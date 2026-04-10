import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../editor_state.dart';

/// Bottom sheet panel for selecting the reframe mode when changing aspect ratios.
///
/// Provides options for how to crop/reposition video when the project aspect ratio
/// differs from the source video (e.g., 16:9 source -> 9:16 output).
class ReframePanel extends ConsumerWidget {
  const ReframePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final currentReframeMode = state.currentProject?.reframeMode ?? 'none';
    final theme = Theme.of(context);

    final modes = [
      _ReframeModeOption(
        mode: 'none',
        icon: LucideIcons.crop,
        label: 'Original',
        description: 'No reframe, keep source framing',
      ),
      _ReframeModeOption(
        mode: 'center',
        icon: LucideIcons.focus,
        label: 'Center',
        description: 'Keep subject centered in frame',
      ),
      _ReframeModeOption(
        mode: 'left',
        icon: LucideIcons.alignHorizontalDistributeStart,
        label: 'Left',
        description: 'Position to the left side',
      ),
      _ReframeModeOption(
        mode: 'right',
        icon: LucideIcons.alignHorizontalDistributeEnd,
        label: 'Right',
        description: 'Position to the right side',
      ),
      _ReframeModeOption(
        mode: 'top',
        icon: LucideIcons.alignVerticalDistributeStart,
        label: 'Top',
        description: 'Position to the top',
      ),
      _ReframeModeOption(
        mode: 'bottom',
        icon: LucideIcons.alignVerticalDistributeEnd,
        label: 'Bottom',
        description: 'Position to the bottom',
      ),
      _ReframeModeOption(
        mode: 'auto',
        icon: LucideIcons.sparkles,
        label: 'Auto (AI)',
        description: 'AI detects and tracks the subject',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(LucideIcons.crop, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reframe',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          // Preview showing crop overlay
          _buildPreviewOverlay(context, currentReframeMode),
          const Divider(height: 1),
          // Mode options grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: modes.map((option) {
                final isSelected = currentReframeMode == option.mode;
                return _ReframeModeChip(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(editorProvider.notifier).setReframeMode(option.mode);
                  },
                );
              }).toList(),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  /// Visual preview showing the crop area overlay on a simulated canvas.
  Widget _buildPreviewOverlay(BuildContext context, String reframeMode) {
    // Simulated 16:9 source with 9:16 crop overlay
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          // Source frame (wide, simulating 16:9)
          Positioned.fill(
            child: CustomPaint(
              painter: _SourceFramePainter(),
            ),
          ),
          // Crop overlay (tall, simulating 9:16)
          Positioned.fill(
            child: CustomPaint(
              painter: _CropOverlayPainter(reframeMode: reframeMode),
            ),
          ),
          // Label
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getModeLabel(reframeMode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'none':
        return 'Original framing';
      case 'center':
        return 'Crop: centered on subject';
      case 'left':
        return 'Crop: left side';
      case 'right':
        return 'Crop: right side';
      case 'top':
        return 'Crop: top area';
      case 'bottom':
        return 'Crop: bottom area';
      case 'auto':
        return 'Auto: AI subject detection';
      default:
        return 'Original framing';
    }
  }
}

class _ReframeModeOption {
  final String mode;
  final IconData icon;
  final String label;
  final String description;

  const _ReframeModeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.description,
  });
}

class _ReframeModeChip extends StatelessWidget {
  final _ReframeModeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReframeModeChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : Colors.white70,
            ),
            const SizedBox(height: 4),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a simulated source video frame with a gradient.
class _SourceFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a gradient to simulate a video frame
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withValues(alpha: 0.3),
          Colors.purple.withValues(alpha: 0.2),
          Colors.orange.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw some simulated content (a centered "subject" circle)
    final subjectPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.height * 0.25,
      subjectPaint,
    );
  }

  @override
  bool shouldRepaint(_SourceFramePainter old) => false;
}

/// Paints the crop overlay rectangle based on the reframe mode.
class _CropOverlayPainter extends CustomPainter {
  final String reframeMode;

  const _CropOverlayPainter({required this.reframeMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate crop rect: 9:16 ratio within the 16:9 source frame
    // Source is wider than target, so we crop horizontally
    final targetRatio = 9 / 16;
    final sourceRatio = size.width / size.height;

    double cropW, cropH, cropX, cropY;

    if (sourceRatio > targetRatio) {
      // Source is wider - crop width
      cropH = size.height;
      cropW = cropH * targetRatio;
      cropY = 0;
      cropX = _getHorizontalOffset(size.width, cropW);
    } else {
      // Source is taller - crop height
      cropW = size.width;
      cropH = cropW / targetRatio;
      cropX = 0;
      cropY = _getVerticalOffset(size.height, cropH);
    }

    // Draw dimmed area outside crop
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    // Left dim
    if (cropX > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, cropX, size.height), dimPaint);
    }
    // Right dim
    if (cropX + cropW < size.width) {
      canvas.drawRect(Rect.fromLTWH(cropX + cropW, 0, size.width - cropX - cropW, size.height), dimPaint);
    }
    // Top dim
    if (cropY > 0) {
      canvas.drawRect(Rect.fromLTWH(cropX, 0, cropW, cropY), dimPaint);
    }
    // Bottom dim
    if (cropY + cropH < size.height) {
      canvas.drawRect(Rect.fromLTWH(cropX, cropY + cropH, cropW, size.height - cropY - cropH), dimPaint);
    }

    // Draw crop border
    final borderPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(cropX, cropY, cropW, cropH),
      borderPaint,
    );

    // Draw rule-of-thirds grid inside crop
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(cropX + cropW * i / 3, cropY),
        Offset(cropX + cropW * i / 3, cropY + cropH),
        gridPaint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(cropX, cropY + cropH * i / 3),
        Offset(cropX + cropW, cropY + cropH * i / 3),
        gridPaint,
      );
    }
  }

  double _getHorizontalOffset(double parentWidth, double childWidth) {
    switch (reframeMode) {
      case 'left':
        return 0;
      case 'right':
        return parentWidth - childWidth;
      case 'center':
      case 'auto':
        return (parentWidth - childWidth) / 2;
      default:
        return (parentWidth - childWidth) / 2;
    }
  }

  double _getVerticalOffset(double parentHeight, double childHeight) {
    switch (reframeMode) {
      case 'top':
        return 0;
      case 'bottom':
        return parentHeight - childHeight;
      case 'center':
      case 'auto':
        return (parentHeight - childHeight) / 2;
      default:
        return (parentHeight - childHeight) / 2;
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.reframeMode != reframeMode;
}

/// Show the reframe panel as a modal bottom sheet.
void showReframePanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ReframePanel(),
  );
}
