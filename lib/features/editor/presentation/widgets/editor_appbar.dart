import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deen_studio_01/core/theme.dart';
import 'package:deen_studio_01/core/ui/design_system.dart';
import '../editor_state.dart';

/// ════════════════════════════════════════════════════════════
/// EditorAppBar — glassmorphic app bar with undo/redo + export
/// ════════════════════════════════════════════════════════════
class EditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onHome;
  final VoidCallback onExport;

  const EditorAppBar({
    super.key,
    required this.onHome,
    required this.onExport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: AppTheme.backgroundDark.withValues(alpha: 0.75),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: Colors.transparent),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.home, size: 24),
        onPressed: onHome,
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                LucideIcons.undo2,
                size: 18,
                color: state.canUndo
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.24),
              ),
              onPressed: state.canUndo
                  ? () => ref.read(editorProvider.notifier).undo()
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                LucideIcons.redo2,
                size: 18,
                color: state.canRedo
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.24),
              ),
              onPressed: state.canRedo
                  ? () => ref.read(editorProvider.notifier).redo()
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      actions: [
        // Auto-save indicator
        AnimatedOpacity(
          opacity: state.isSaving ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sauvegarde...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
          child: PillButton(
            label: 'Exporter',
            icon: LucideIcons.download,
            onTap: onExport,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
