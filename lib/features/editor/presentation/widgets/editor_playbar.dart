import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deen_studio_01/core/theme.dart';
import 'package:deen_studio_01/core/ui/design_system.dart';
import '../editor_state.dart';

class EditorPlayBar extends ConsumerWidget {
  const EditorPlayBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
          editorProvider.select((s) => s.currentProject?.totalDuration ?? 1.0),
        );
    final isPlaying = ref.watch(editorProvider.select((s) => s.isPlaying));
    final isTimelineExpanded = ref.watch(
      editorProvider.select((s) => s.isTimelineExpanded),
    );
    final isFullScreen = ref.watch(editorProvider.select((s) => s.isFullScreen));
    final playbackNotifier = ref.read(playbackTimeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          GlassIconButton(
            icon: isTimelineExpanded
                ? Icons.unfold_less_rounded
                : Icons.unfold_more_rounded,
            size: 18,
            onTap: () =>
                ref.read(editorProvider.notifier).toggleTimelineExpansion(),
          ),
          const SizedBox(width: 8),

          ValueListenableBuilder<double>(
            valueListenable: playbackNotifier,
            builder: (context, current, _) {
              return SizedBox(
                width: 38,
                child: Text(
                  _fmt(current),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface.withValues(alpha: 0.65),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
          ),

          ValueListenableBuilder<double>(
            valueListenable: playbackNotifier,
            builder: (context, current, _) {
              final progress = (current / total).clamp(0.0, 1.0);
              return Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor:
                        AppTheme.outlineVariant.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor:
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (v) {
                      final newTime = v * total;
                      playbackNotifier.value = newTime;
                      ref
                          .read(editorProvider.notifier)
                          .setCurrentTime(newTime);
                    },
                  ),
                ),
              );
            },
          ),

          SizedBox(
            width: 38,
            child: Text(
              _fmt(total),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.onSurface.withValues(alpha: 0.35),
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),

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
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: isFullScreen ? LucideIcons.minimize : LucideIcons.maximize,
            size: 18,
            onTap: () => ref.read(editorProvider.notifier).toggleFullScreen(),
          ),
        ],
      ),
    );
  }

  static String _fmt(double s) {
    final m = (s / 60).floor();
    final sec = (s % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
