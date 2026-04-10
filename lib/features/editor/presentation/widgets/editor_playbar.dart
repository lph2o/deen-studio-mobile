import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deen_studio_01/core/theme.dart';
import 'package:deen_studio_01/core/ui/design_system.dart';
import '../editor_state.dart';

/// ════════════════════════════════════════════════════════════
/// EditorPlayBar — scrubber + timecode + play/pause + fullscreen
/// ════════════════════════════════════════════════════════════
class EditorPlayBar extends ConsumerWidget {
  const EditorPlayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final total = state.currentProject?.totalDuration ?? 1.0;
    final current = state.currentTime;
    final progress = (current / total).clamp(0.0, 1.0);

    String fmt(double s) {
      final m = (s / 60).floor();
      final sec = (s % 60).floor();
      return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Collapse/Expand timeline
          GlassIconButton(
            icon: state.isTimelineExpanded
                ? Icons.unfold_less_rounded
                : Icons.unfold_more_rounded,
            size: 18,
            onTap: () => ref.read(editorProvider.notifier).toggleTimelineExpansion(),
          ),
          const SizedBox(width: 8),

          // Current timecode
          SizedBox(
            width: 38,
            child: Text(
              fmt(current),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.65),
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),

          // Progress scrubber
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: AppTheme.outlineVariant.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: progress,
                onChanged: (v) {
                  ref.read(editorProvider.notifier).setCurrentTime(v * total);
                },
              ),
            ),
          ),

          // Total timecode
          SizedBox(
            width: 38,
            child: Text(
              fmt(total),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.onSurface.withValues(alpha: 0.35),
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),

          // Play/Pause button
          GestureDetector(
            onTap: () => ref.read(editorProvider.notifier).togglePlay(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Fullscreen toggle
          GlassIconButton(
            icon: state.isFullScreen ? LucideIcons.minimize : LucideIcons.maximize,
            size: 18,
            onTap: () => ref.read(editorProvider.notifier).toggleFullScreen(),
          ),
        ],
      ),
    );
  }
}
