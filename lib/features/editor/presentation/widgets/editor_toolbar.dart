import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/core/services/video_tool_service.dart';
import 'package:deen_studio_01/core/services/persistent_media_store.dart';
import 'package:deen_studio_01/core/theme.dart';
import '../editor_state.dart';
import 'color_grading_panel.dart';
import 'text_editor_panel.dart';
import 'text_to_speech_sheet.dart';
import 'layer_tools_dialogs.dart';
import 'auto_subtitle_sheet.dart';
import 'voice_effect_picker.dart';
import 'sticker_picker.dart';
import 'inline_audio_mixer.dart';
import 'inspector_panel.dart';
import 'multicam_switcher.dart';

import 'image_interactions/image_filters_sheet.dart';
import 'image_interactions/visual_effects_sheet.dart';
import 'multicam_create_dialog.dart';
import 'reframe_panel.dart';
import 'export_dialog.dart';
import '../../../pixabay/presentation/widgets/pixabay_gallery_widget.dart';
import '../../../quran_studio/presentation/widgets/quran_selection_sheet.dart';

/// ════════════════════════════════════════════════════════════
/// EditorToolbar — Smart bottom navigation bar
///
/// Switches automatically between:
/// • Default toolbar (no layer selected)
/// • Audio mixer toolbar (audio layer selected)
/// • Selection toolbar (any other layer selected)
///
/// All dialog/sheet logic lives here — editor_screen.dart only
/// needs one import to get the complete toolbar.
/// ════════════════════════════════════════════════════════════
class EditorToolbar extends ConsumerStatefulWidget {
  const EditorToolbar({super.key});

  @override
  ConsumerState<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends ConsumerState<EditorToolbar> {
  // ─── Dialog Helpers ─────────────────────────────────────────────────────

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openVolumeDialog(String layerId) async {
    final layer = ref
        .read(editorProvider)
        .currentProject
        ?.layers
        .firstWhere(
          (l) => l.id == layerId,
          orElse: () => Layer(
            id: '',
            type: '',
            content: '',
            startTime: 0,
            duration: 0,
            style: {},
          ),
        );
    if (layer == null || layer.id.isEmpty) return;

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VolumeDialog(
        initialVolume: (layer.style['volume'] as num?)?.toDouble() ?? 1.0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(
            layer.copyWith(style: {...layer.style, 'volume': result}),
          );
    }
  }

  Future<void> _openSpeedDialog(String layerId) async {
    final layer = ref
        .read(editorProvider)
        .currentProject
        ?.layers
        .firstWhere(
          (l) => l.id == layerId,
          orElse: () => Layer(
            id: '',
            type: '',
            content: '',
            startTime: 0,
            duration: 0,
            style: {},
          ),
        );
    if (layer == null || layer.id.isEmpty) return;

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpeedDialog(
        initialSpeed: (layer.style['speed'] as num?)?.toDouble() ?? 1.0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(
            layer.copyWith(style: {...layer.style, 'speed': result}),
          );
    }
  }

  Future<void> _openFadeDialog(String layerId) async {
    final layer = ref
        .read(editorProvider)
        .currentProject
        ?.layers
        .firstWhere(
          (l) => l.id == layerId,
          orElse: () => Layer(
            id: '',
            type: '',
            content: '',
            startTime: 0,
            duration: 0,
            style: {},
          ),
        );
    if (layer == null || layer.id.isEmpty) return;

    final result = await showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FadeDialog(
        initialFadeIn: (layer.style['fadeIn'] as num?)?.toDouble() ?? 0.0,
        initialFadeOut: (layer.style['fadeOut'] as num?)?.toDouble() ?? 0.0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(
            layer.copyWith(
              style: {
                ...layer.style,
                'fadeIn': result['fadeIn'] ?? 0.0,
                'fadeOut': result['fadeOut'] ?? 0.0,
              },
            ),
          );
    }
  }

  Future<void> _openTransitionDialog(String layerId) async {
    final layer = ref
        .read(editorProvider)
        .currentProject
        ?.layers
        .firstWhere(
          (l) => l.id == layerId,
          orElse: () => Layer(
            id: '',
            type: '',
            content: '',
            startTime: 0,
            duration: 0,
            style: {},
          ),
        );
    if (layer == null || layer.id.isEmpty) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransitionDialog(
        initialTransition: layer.style['transition'] as String? ?? 'none',
        initialDuration:
            (layer.style['transitionDuration'] as num?)?.toDouble() ?? 1.0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(
            layer.copyWith(
              style: {
                ...layer.style,
                'transition': result['transition'],
                'transitionDuration': result['duration'],
              },
            ),
          );
    }
  }

  Future<void> _openStickerSizeDialog(Layer layer) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StickerSizeSheet(
        initialSize: (layer.style['size'] as num?)?.toDouble() ?? 48.0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(layer.copyWith(style: {...layer.style, 'size': result}));
      _showSnack('Taille: ${result.toInt()}px');
    }
  }

  Future<void> _openStickerOpacityDialog(Layer layer) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StickerOpacitySheet(
        initialOpacity: (layer.style['opacity'] as num?)?.toDouble() ?? 1.0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(
            layer.copyWith(style: {...layer.style, 'opacity': result}),
          );
      _showSnack('Opacité: ${(result * 100).toInt()}%');
    }
  }

  Future<void> _replaceImage(Layer layer) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null && mounted) {
      final persistentPath = await PersistentMediaStore.persistFile(result.files.single.path!);
      if (mounted) {
        ref.read(editorProvider.notifier).updateLayer(
          layer.copyWith(content: persistentPath),
        );
      }
    }
  }


  Future<void> _openImageFilters(Layer layer) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageFiltersSheet(
        layerId: layer.id,
        imagePath: layer.content,
      ),
    );
  }

  Future<void> _openImageOpacityDialog(Layer layer) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StickerOpacitySheet(
        initialOpacity: (layer.style['opacity'] as num?)?.toDouble() ?? 1.0,
        title: 'Opacité de l\'image',
      ),
    );
    if (result != null && mounted) {
      ref.read(editorProvider.notifier).updateLayer(
        layer.copyWith(style: {...layer.style, 'opacity': result}),
      );
    }
  }

  Future<void> _openStickerAnimationPicker(Layer layer) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StickerAnimationSheet(
        initialAnimation: (layer.style['animation'] as int?) ?? 0,
      ),
    );
    if (result != null && mounted) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(
            layer.copyWith(style: {...layer.style, 'animation': result}),
          );
      const names = [
        'Aucune',
        'Apparition',
        'Rebond',
        'Rotation',
        'Zoom',
        'Glissement',
      ];
      _showSnack('Animation: ${names[result]}');
    }
  }

  Future<void> _stabilizeVideo(Layer layer) async {
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProcessingDialog(label: 'Stabilisation de la vidéo...'),
    );
    final success = await ref
        .read(editorProvider.notifier)
        .stabilizeVideo(layer.id, onProgress: (_, _) {});
    if (!mounted) return;
    Navigator.of(context).pop();
    _showSnack(
      success ? 'Vidéo stabilisée avec succès' : 'Erreur ou vidéo déjà stable',
    );
  }

  Future<void> _freezeFrame(Layer layer) async {
    final state = ref.read(editorProvider);
    final timestamp =
        (state.currentTime - layer.startTime) + (layer.inPoint ?? 0);
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProcessingDialog(label: 'Extraction de l\'image...'),
    );
    final framePath = await VideoToolService.freezeFrame(
      videoPath: layer.content,
      timestamp: timestamp,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (framePath != null) {
      ref
          .read(editorProvider.notifier)
          .addMediaLayer(
            type: 'image',
            content: framePath,
            startTime: state.currentTime,
            duration: 3.0,
          );
      _showSnack('Image freeze ajoutée (3s)');
    } else {
      _showSnack('Erreur lors de l\'extraction');
    }
  }

  Future<void> _reverseVideo(Layer layer) async {
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProcessingDialog(label: 'Inversion de la vidéo...'),
    );
    final reversedPath = await VideoToolService.reverseVideo(
      videoPath: layer.content,
      onProgress: (_, _) {},
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (reversedPath != null) {
      ref
          .read(editorProvider.notifier)
          .updateLayer(layer.copyWith(content: reversedPath));
      _showSnack('Vidéo inversée avec succès');
    } else {
      _showSnack('Erreur lors de l\'inversion');
    }
  }

  void _showCreateMultiCamDialog() {
    final project = ref.read(editorProvider).currentProject;
    if (project == null) return;
    showDialog(
      context: context,
      builder: (_) => MultiCamCreateDialog(project: project),
    ).then((result) {
      if (result is Map<String, dynamic> && mounted) {
        final layerIds = result['layerIds'] as List<String>;
        final name = result['name'] as String;
        if (layerIds.length >= 2 && name.isNotEmpty) {
          ref.read(editorProvider.notifier).createMultiCamGroup(layerIds, name);
          _showSnack('Multi-Cam "$name" créé');
        }
      }
    });
  }

  void _showMediaImportPicker({required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 8,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Ajouter ${isVideo ? "une vidéo" : "une image"}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MediaSourceButton(
                      icon: LucideIcons.folder,
                      label: 'Mes fichiers',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final result = await FilePicker.platform.pickFiles(
                          type: isVideo ? FileType.video : FileType.image,
                        );
                        if (result != null &&
                            result.files.single.path != null &&
                            mounted) {
                          final persistentPath =
                              await PersistentMediaStore.persistFile(
                                result.files.single.path!,
                              );
                          if (mounted) {
                            ref
                                .read(editorProvider.notifier)
                                .addMediaLayer(
                                  type: isVideo ? 'video' : 'image',
                                  content: persistentPath,
                                );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MediaSourceButton(
                      icon: LucideIcons.search,
                      label: 'Pixabay',
                      onTap: () {
                        Navigator.pop(ctx);
                        showPixabayPicker(
                          context,
                          isVideo: isVideo,
                          onImported: (path, isVid) {
                            if (mounted) {
                              ref
                                  .read(editorProvider.notifier)
                                  .addMediaLayer(
                                    type: isVid ? 'video' : 'image',
                                    content: path,
                                  );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedLayerId = ref.watch(
      editorProvider.select((s) => s.selectedLayerId),
    );
    final project = ref.watch(editorProvider.select((s) => s.currentProject));
    final selectedLayer = selectedLayerId != null
        ? project?.layers.firstWhere(
            (l) => l.id == selectedLayerId,
            orElse: () => Layer(
              id: '',
              type: 'none',
              content: '',
              startTime: 0,
              duration: 0,
              style: {},
            ),
          )
        : null;

    final bool hasSelection =
        selectedLayer != null && selectedLayer.type != 'none';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            top: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLowest.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppTheme.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: hasSelection
              ? (selectedLayer.isAudio
                    ? _buildAudioMixerToolbar(project!, selectedLayer)
                    : _buildSelectionToolbar(project!, selectedLayer))
              : _buildDefaultToolbar(project!),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DEFAULT TOOLBAR — shown when nothing is selected
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDefaultToolbar(Project project) {
    final videoCount = project.layers.where((l) => l.type == 'video').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ToolbarItem(
            icon: LucideIcons.sparkles,
            label: 'Coran Magique',
            onTap: () => QuranSelectionSheet.show(context),
            color: AppTheme.accentColor,
            isPrimary: true, // Makes it pop visually
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.type,
            label: 'Texte',
            onTap: () => ref
                .read(editorProvider.notifier)
                .addTextLayer(content: 'Votre texte'),
            color: AppTheme.trackText,
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.music,
            label: 'Audio',
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.audio,
                allowMultiple: false,
              );
              if (result != null &&
                  result.files.single.path != null &&
                  mounted) {
                ref
                    .read(editorProvider.notifier)
                    .addMediaLayer(
                      type: 'audio',
                      content: result.files.single.path!,
                    );
              }
            },
            color: AppTheme.trackAudio,
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.image,
            label: 'Image',
            onTap: () => _showMediaImportPicker(isVideo: false),
            color: AppTheme.trackImage,
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.video,
            label: 'Vidéo',
            onTap: () => _showMediaImportPicker(isVideo: true),
            color: AppTheme.trackVideo,
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.sticker,
            label: 'Sticker',
            onTap: () => showStickerPicker(context),
            color: AppTheme.secondaryColor,
          ),
          if (videoCount >= 2) ...[
            const SizedBox(width: 8),
            _ToolbarItem(
              icon: LucideIcons.split,
              label: 'Multi-Cam',
              onTap: _showCreateMultiCamDialog,
              color: AppTheme.accentColor,
            ),
          ],
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 32,
            color: AppTheme.outlineVariant.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.monitorSmartphone,
            label: 'Format',
            onTap: () => showReframePanel(context),
            color: AppTheme.onSurface,
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.sliders,
            label: 'Mixage',
            onTap: () => ref
                .read(editorProvider.notifier)
                .setActiveToolbarCategory('Mixage Audio'),
            color: AppTheme.onSurface,
          ),
          const SizedBox(width: 8),
          _ToolbarItem(
            icon: LucideIcons.download,
            label: 'Exporter',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ExportDialog(),
            ),
            color: AppTheme.primaryColor,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIO MIXER TOOLBAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAudioMixerToolbar(Project project, Layer layer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(editorProvider.notifier).setSelectedLayer(null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.trackAudio.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.trackAudio.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12,
                    color: AppTheme.trackAudio,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.trackAudio,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      layer.content.contains('/') ||
                              layer.content.contains('\\')
                          ? layer.content.split(Platform.pathSeparator).last
                          : (layer.content.length > 30
                                ? '${layer.content.substring(0, 30)}...'
                                : layer.content),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.onSurface.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openVolumeDialog(layer.id),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.expand,
                    size: 14,
                    color: AppTheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(editorProvider.notifier).removeLayer(layer.id);
                  ref.read(editorProvider.notifier).setSelectedLayer(null);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.trash2,
                    size: 14,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        InlineAudioMixer(
          audioLayer: layer,
          editorState: ref.read(editorProvider),
          onStyleUpdated: (styleUpdates) {
            ref
                .read(editorProvider.notifier)
                .updateLayer(
                  layer.copyWith(style: {...layer.style, ...styleUpdates}),
                );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION TOOLBAR — shown when a non-audio layer is selected
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSelectionToolbar(Project project, Layer layer) {
    final state = ref.read(editorProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () =>
                ref.read(editorProvider.notifier).setSelectedLayer(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Retour',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Context-specific action chips
          ..._buildSelectionChips(layer, state),

          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 32,
            color: AppTheme.outlineVariant.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),

          // Text-specific tools
          if (layer.isTextType) ...[
            _ToolbarItem(
              icon: LucideIcons.type,
              label: 'Éditer',
              onTap: () => showTextEditorPanel(context, layer, initialIndex: 0),
              color: AppTheme.onSurface,
            ),
            const SizedBox(width: 8),
            _ToolbarItem(
              icon: LucideIcons.palette,
              label: 'Style',
              onTap: () => showTextEditorPanel(context, layer, initialIndex: 2),
              color: AppTheme.onSurface,
            ),
            const SizedBox(width: 8),
            _ToolbarItem(
              icon: Icons.sync_alt_rounded,
              label: 'Sync Pos.',
              onTap: () {
                ref
                    .read(editorProvider.notifier)
                    .applyMetricsToSameTypeLayers(layer.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Position synchronisée sur tous les textes de ce type',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
          ],

          // Video-specific tools
          if (layer.isVisual && layer.type == 'video') ...[
            _ToolbarItem(
              icon: LucideIcons.shieldCheck,
              label: 'Stabiliser',
              onTap: () => _stabilizeVideo(layer),
              color: AppTheme.onSurface,
            ),
            const SizedBox(width: 8),
            _ToolbarItem(
              icon: LucideIcons.splitSquareVertical,
              label: 'Multi-Cam',
              onTap: () {
                final project = ref.read(editorProvider).currentProject;
                if (project == null) return;
                final hasGroup = project.multiCamGroups.any(
                  (g) => g.angles.any((a) => a.layerId == layer.id),
                );
                if (hasGroup) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const MultiCamSwitcher(),
                  );
                } else {
                  _showCreateMultiCamDialog();
                }
              },
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 8),
          ],

          // Audio layer tools
          if (layer.isAudio) ...[
            _ToolbarItem(
              icon: LucideIcons.fileAudio,
              label: 'Voix',
              onTap: () => showVoiceEffectPicker(context, layer.id),
              color: AppTheme.onSurface,
            ),
            const SizedBox(width: 8),
          ],

          // Properties — opens InspectorPanel
          _ToolbarItem(
            icon: LucideIcons.settings,
            label: 'Propriétés',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const InspectorPanel(),
            ),
            color: AppTheme.onSurface,
          ),
          const SizedBox(width: 8),

          // Delete
          _ToolbarItem(
            icon: LucideIcons.trash2,
            label: 'Supprimer',
            onTap: () {
              ref.read(editorProvider.notifier).removeLayer(layer.id);
              ref.read(editorProvider.notifier).setSelectedLayer(null);
            },
            color: Colors.red,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION CHIPS — context-sensitive quick actions
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _buildSelectionChips(Layer layer, EditorState state) {
    final chips = <Widget>[];

    // Always: Split + Duplicate
    chips.add(
      _ActionChip(
        icon: LucideIcons.splitSquareHorizontal,
        label: 'Couper',
        onTap: () => ref
            .read(editorProvider.notifier)
            .splitLayer(layer.id, state.currentTime),
      ),
    );
    chips.add(const SizedBox(width: 6));

    chips.add(
      _ActionChip(
        icon: LucideIcons.copy,
        label: 'Dupliquer',
        onTap: () => ref.read(editorProvider.notifier).duplicateLayer(layer.id),
      ),
    );
    chips.add(const SizedBox(width: 6));

    // Visual layers — shared chips for ALL visual types (image, video, sticker)
    if (layer.isVisual) {
      chips.add(
        _ActionChip(
          icon: LucideIcons.moveRight,
          label: 'Transition',
          onTap: () => _openTransitionDialog(layer.id),
        ),
      );
      chips.add(const SizedBox(width: 6));

      // Effets (brightness, contrast, blur, vignette, etc.)
      chips.add(
        _ActionChip(
          icon: LucideIcons.sparkles,
          label: 'Effets',
          onTap: () => showVisualEffectsSheet(context, layer.id, initialTab: 0),
        ),
      );
      chips.add(const SizedBox(width: 6));

      // Transform (opacity, rotation, scale)
      chips.add(
        _ActionChip(
          icon: LucideIcons.move,
          label: 'Transform',
          onTap: () => showVisualEffectsSheet(context, layer.id, initialTab: 1),
        ),
      );
      chips.add(const SizedBox(width: 6));

      // Mask
      chips.add(
        _ActionChip(
          icon: LucideIcons.scissors,
          label: 'Masque',
          onTap: () => showVisualEffectsSheet(context, layer.id, initialTab: 2),
        ),
      );
      chips.add(const SizedBox(width: 6));

      // Blend mode
      chips.add(
        _ActionChip(
          icon: LucideIcons.layers,
          label: 'Fusion',
          onTap: () => showVisualEffectsSheet(context, layer.id, initialTab: 3),
        ),
      );
      chips.add(const SizedBox(width: 6));

      // Color Grading
      chips.add(
        _ActionChip(
          icon: Icons.gradient_rounded,
          label: 'Colorimétrie',
          onTap: () => showColorGradingPanel(context, layer.id, ref),
        ),
      );
      chips.add(const SizedBox(width: 6));

      if (layer.type == 'video') {
        chips.add(
          _ActionChip(
            icon: LucideIcons.volume2,
            label: 'Volume',
            onTap: () => _openVolumeDialog(layer.id),
          ),
        );
        chips.add(const SizedBox(width: 6));
        chips.add(
          _ActionChip(
            icon: LucideIcons.clock,
            label: 'Vitesse',
            onTap: () => _openSpeedDialog(layer.id),
          ),
        );
        chips.add(const SizedBox(width: 6));
        chips.add(
          _ActionChip(
            icon: LucideIcons.image,
            label: 'Freeze',
            onTap: () => _freezeFrame(layer),
          ),
        );
        chips.add(const SizedBox(width: 6));
        chips.add(
          _ActionChip(
            icon: LucideIcons.rotateCcw,
            label: 'Inverser',
            onTap: () => _reverseVideo(layer),
          ),
        );
        chips.add(const SizedBox(width: 6));
      }

      if (layer.type == 'image') {
        chips.add(
          _ActionChip(
            icon: Icons.find_replace_rounded,
            label: 'Remplacer',
            onTap: () => _replaceImage(layer),
          ),
        );
        chips.add(const SizedBox(width: 6));
      }
    }

    // Text layers
    if (layer.isTextType) {
      chips.add(
        _ActionChip(
          icon: LucideIcons.focus,
          label: 'Animation',
          onTap: () => showTextEditorPanel(context, layer, initialIndex: 4),
        ),
      );
      chips.add(const SizedBox(width: 6));

      chips.add(
        _ActionChip(
          icon: LucideIcons.mic,
          label: 'Voix',
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TextToSpeechSheet(targetLayer: layer),
          ),
        ),
      );
      chips.add(const SizedBox(width: 6));
    }

    // Audio layers
    if (layer.isAudio) {
      chips.add(
        _ActionChip(
          icon: LucideIcons.volume2,
          label: 'Volume',
          onTap: () => _openVolumeDialog(layer.id),
        ),
      );
      chips.add(const SizedBox(width: 6));
      chips.add(
        _ActionChip(
          icon: LucideIcons.clock,
          label: 'Vitesse',
          onTap: () => _openSpeedDialog(layer.id),
        ),
      );
      chips.add(const SizedBox(width: 6));
      chips.add(
        _ActionChip(
          icon: LucideIcons.skipForward,
          label: 'Estomper',
          onTap: () => _openFadeDialog(layer.id),
        ),
      );
      chips.add(const SizedBox(width: 6));
      chips.add(
        _ActionChip(
          icon: LucideIcons.type,
          label: 'Sous-titres',
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AutoSubtitleSheet(),
          ),
        ),
      );
      chips.add(const SizedBox(width: 6));
    }

    // Sticker layers
    if (layer.isSticker) {
      chips.add(
        _ActionChip(
          icon: LucideIcons.maximize2,
          label: 'Taille',
          onTap: () => _openStickerSizeDialog(layer),
        ),
      );
      chips.add(const SizedBox(width: 6));
      chips.add(
        _ActionChip(
          icon: LucideIcons.eye,
          label: 'Opacité',
          onTap: () => _openStickerOpacityDialog(layer),
        ),
      );
      chips.add(const SizedBox(width: 6));
      chips.add(
        _ActionChip(
          icon: LucideIcons.sparkles,
          label: 'Animation',
          onTap: () => _openStickerAnimationPicker(layer),
        ),
      );
      chips.add(const SizedBox(width: 6));
    }

    return chips;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Primary quick-add button — icon + label in a rounded pill
class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;
  final bool isDestructive;

  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive ? Colors.red : color;
    final alpha = isDestructive
        ? 0.8
        : isPrimary
        ? 1.0
        : 0.7;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, // Keep width uniform
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(
                  alpha: isPrimary || isDestructive ? 0.15 : 0.1,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: effectiveColor.withValues(
                    alpha: isPrimary || isDestructive ? 0.4 : 0.2,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: effectiveColor.withValues(alpha: alpha),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                color: effectiveColor.withValues(alpha: alpha),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact action chip for the selection toolbar
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, // Keep width uniform to fit more on screen
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Import source button used in media picker sheet
class _MediaSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pixabay Picker ──────────────────────────────────────────────────────────

void showPixabayPicker(
  BuildContext context, {
  required bool isVideo,
  required void Function(String path, bool isVideo) onImported,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: PixabayGalleryWidget(onMediaImported: onImported),
          );
        },
      );
    },
  );
}

// ─── Processing Dialog (replaces 3 separate loading dialogs) ─────────────────

class _ProcessingDialog extends StatelessWidget {
  final String label;
  const _ProcessingDialog({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(label, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              'Cela peut prendre quelques instants',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sticker Tool Sheets ──────────────────────────────────────────────────────

class _StickerSizeSheet extends StatefulWidget {
  final double initialSize;
  const _StickerSizeSheet({required this.initialSize});
  @override
  State<_StickerSizeSheet> createState() => _StickerSizeSheetState();
}

class _StickerSizeSheetState extends State<_StickerSizeSheet> {
  late double _size;
  @override
  void initState() {
    super.initState();
    _size = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: 'Taille du sticker',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_size.toInt()}px',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _size,
            min: 20,
            max: 200,
            divisions: 36,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _size = v),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [20.0, 48.0, 80.0, 120.0, 200.0]
                .map(
                  (v) => _QuickPill(
                    label: '${v.toInt()}',
                    isSelected: (_size - v).abs() < 1,
                    onTap: () => setState(() => _size = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, _size),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerOpacitySheet extends StatefulWidget {
  final double initialOpacity;
  final String title;
  const _StickerOpacitySheet({required this.initialOpacity, this.title = 'Opacité du sticker'});
  @override
  State<_StickerOpacitySheet> createState() => _StickerOpacitySheetState();
}

class _StickerOpacitySheetState extends State<_StickerOpacitySheet> {
  late double _opacity;
  @override
  void initState() {
    super.initState();
    _opacity = widget.initialOpacity;
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(_opacity * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _opacity,
            min: 0,
            max: 1,
            divisions: 20,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _opacity = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, _opacity),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerAnimationSheet extends StatefulWidget {
  final int initialAnimation;
  const _StickerAnimationSheet({required this.initialAnimation});
  @override
  State<_StickerAnimationSheet> createState() => _StickerAnimationSheetState();
}

class _StickerAnimationSheetState extends State<_StickerAnimationSheet> {
  late int _selected;
  static final _animations = [
    (0, 'Aucune', LucideIcons.x),
    (1, 'Apparition', LucideIcons.sparkles),
    (2, 'Rebond', LucideIcons.arrowUpDown),
    (3, 'Rotation', LucideIcons.rotateCw),
    (4, 'Zoom', LucideIcons.maximize2),
    (5, 'Glissement', LucideIcons.moveRight),
  ];
  @override
  void initState() {
    super.initState();
    _selected = widget.initialAnimation;
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: 'Animation du sticker',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _animations.map((anim) {
              final (idx, label, icon) = anim;
              final isSelected = _selected == idx;
              return GestureDetector(
                onTap: () => setState(() => _selected = idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                        : AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.4)
                          : AppTheme.outlineVariant.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, _selected),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheetContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _QuickPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : AppTheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
