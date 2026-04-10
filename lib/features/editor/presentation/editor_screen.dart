import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deen_studio_01/core/theme.dart';
import 'widgets/timeline.dart';
import 'widgets/video_preview.dart';
import 'widgets/export_dialog.dart';
import 'widgets/contextual_tool_panel.dart';
import 'widgets/editor_appbar.dart';
import 'widgets/editor_playbar.dart';
import 'widgets/editor_toolbar.dart';
import 'editor_state.dart';

// ════════════════════════════════════════════════════════════
// EditorScreen — Main video editor entry point
//
// This file is intentionally thin. All UI sub-components live
// in dedicated widget files:
//   • editor_appbar.dart   — glassmorphic AppBar
//   • editor_playbar.dart  — scrubber + play controls
//   • editor_toolbar.dart  — bottom nav (default / selection / audio)
//   • contextual_tool_panel.dart — overlay category panel
// ════════════════════════════════════════════════════════════

class EditorScreen extends ConsumerStatefulWidget {
  final String projectId;
  const EditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _hasSuggestedMultiCam = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).loadProject(widget.projectId);
    });
  }

  @override
  void dispose() {
    ref.read(editorProvider.notifier).resetEditorOnExit();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    await ref.read(editorProvider.notifier).resetEditorOnExit();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) context.go('/dashboard');
  }

  void _openExport() {
    showDialog(context: context, builder: (_) => const ExportDialog());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);

    // Landscape ↔ Portrait when entering / exiting fullscreen
    ref.listen(editorProvider.select((s) => s.isFullScreen), (_, isFull) {
      if (isFull) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });

    // Auto-suggest Multi-Cam when 2+ video layers are detected
    ref.listen(
      editorProvider.select((s) {
        final project = s.currentProject;
        if (project == null) return null;
        return (
          project.layers.where((l) => l.type == 'video').length,
          project.multiCamGroups.isNotEmpty,
        );
      }),
      (prev, next) {
        if (next == null) return;
        final (videoCount, hasMultiCam) = next;
        if (videoCount >= 2 && !hasMultiCam && !_hasSuggestedMultiCam && mounted) {
          _hasSuggestedMultiCam = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.split, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$videoCount pistes vidéo détectées. Créer un groupe Multi-Cam ?',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Créer',
                  textColor: AppTheme.primaryColor,
                  onPressed: () {
                    // Trigger from toolbar state via provider
                    ref.read(editorProvider.notifier).setActiveToolbarCategory(null);
                  },
                ),
              ),
            );
          });
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveAndExit();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: state.isFullScreen
            ? null
            : EditorAppBar(
                onHome: _saveAndExit,
                onExport: _openExport,
              ),
        body: state.currentProject == null
            ? _buildLoading()
            : ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        if (!state.isFullScreen)
                          Expanded(
                            flex: state.isTimelineExpanded ? 2 : 5,
                            child: const VideoPreview(),
                          ),
                        if (state.isFullScreen)
                          const Expanded(child: VideoPreview()),

                        // ── Scrubber + play controls ──
                        const EditorPlayBar(),

                        if (!state.isFullScreen)
                          Expanded(
                            flex: state.isTimelineExpanded ? 5 : 2,
                            child: const Timeline(),
                          ),
                      ],
                    ),

                    // ── Contextual category panel (slides above timeline) ──
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ContextualToolPanel(),
                    ),
                  ],
                ),
              ),

        // ── Smart bottom toolbar ──
        bottomNavigationBar: const EditorToolbar(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text(
              'Chargement du projet...',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
