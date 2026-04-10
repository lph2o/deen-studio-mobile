import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../editor_state.dart';
import '../../../../models/project.dart';
import '../../../../core/theme.dart';
import 'text_editor_panel.dart';
import 'auto_subtitle_sheet.dart';
import 'text_to_speech_sheet.dart';
import 'sticker_picker.dart';
import 'reframe_panel.dart';
import 'inspector_panel.dart';
import '../../../pixabay/presentation/widgets/pixabay_gallery_widget.dart';
import '../../../pixabay/presentation/state/pixabay_notifier.dart';
import '../../../pixabay/data/models/pixabay_models.dart';

class ContextualToolPanel extends ConsumerWidget {
  const ContextualToolPanel({super.key});

  void _dismiss(BuildContext context, WidgetRef ref) {
    ref.read(editorProvider.notifier).setActiveToolbarCategory(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final category = state.activeToolbarCategory;

    if (category == null) return const SizedBox.shrink();

    final grid = _buildGrid(context, ref, category);

    // Return empty if grid is empty
    if (grid is SizedBox && grid.height == 0) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with category + close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.grip, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _dismiss(context, ref),
                  icon: const Icon(LucideIcons.x, size: 14),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            grid,
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref, String category) {
    List<_ToolData> tools = [];

    switch (category) {
      case 'Audio':
        tools = [
          _ToolData(
            LucideIcons.music, 'Musique',
            onTap: (ctx, r) async {
              final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
              if (result != null && ctx.mounted) {
                final path = result.files.single.path;
                if (path != null) r.read(editorProvider.notifier).addMediaLayer(type: 'audio', content: path);
              }
            },
          ),
          _ToolData(
            LucideIcons.mic2, 'Texte en voix', statusColor: Colors.red,
            onTap: (ctx, r) {
              final state = r.read(editorProvider);
              final layer = state.currentProject?.layers
                  .where((l) => l.type == 'text').firstOrNull
                  ?? Layer(id: 'dummy', type: 'text', content: '', startTime: 0, duration: 5, style: const {});
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TextToSpeechSheet(targetLayer: layer),
              );
            },
          ),
          _ToolData(
            LucideIcons.fileAudio, 'Mes fichiers',
            onTap: (ctx, r) async {
              final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
              if (result != null && ctx.mounted) {
                final path = result.files.single.path;
                if (path != null) r.read(editorProvider.notifier).addMediaLayer(type: 'audio', content: path);
              }
            },
          ),
          _ToolData(
            LucideIcons.subtitles, 'Sous-titres', statusColor: Colors.cyan,
            onTap: (ctx, r) {
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AutoSubtitleSheet(),
              );
            },
          ),
          _ToolData(LucideIcons.sparkles, 'Créateur IA', isNew: true, statusColor: Colors.cyan),
          _ToolData(LucideIcons.cpu, 'Changeur voix IA', isNew: true, statusColor: Colors.cyan),
        ];
        break;
      case 'Effets':
        tools = [
          _ToolData(
            LucideIcons.sliders, 'Régler',
            onTap: (ctx, r) {
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const InspectorPanel(),
              );
            },
          ),
          _ToolData(
            LucideIcons.filter, 'Filtre',
            onTap: (ctx, r) {
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const InspectorPanel(),
              );
            },
          ),
          _ToolData(LucideIcons.grid, 'Mosaïque'),
          _ToolData(LucideIcons.sparkles, 'Effets vidéo', isNew: true, statusColor: Colors.cyan),
          _ToolData(LucideIcons.user, 'Effets corps', isNew: true, statusColor: Colors.cyan),
          _ToolData(LucideIcons.sun, 'Surbrillance', isNew: true, statusColor: Colors.cyan),
        ];
        break;
      case 'Mixage Audio':
        tools = [
          _ToolData(
            LucideIcons.sliders, 'Mixeur',
            onTap: (ctx, r) {
              final state = r.read(editorProvider);
              final audioLayer = state.currentProject?.layers
                  .where((l) => l.type == 'audio').firstOrNull;
              if (audioLayer != null) r.read(editorProvider.notifier).setSelectedLayer(audioLayer.id);
              r.read(editorProvider.notifier).setActiveToolbarCategory(null);
            },
          ),
          _ToolData(
            LucideIcons.volume2, 'Normaliser',
            onTap: (ctx, r) {
              // Select any audio layer to open mixer automatically
              final state = r.read(editorProvider);
              final audioLayer = state.currentProject?.layers
                  .where((l) => l.type == 'audio').firstOrNull;
              if (audioLayer != null) r.read(editorProvider.notifier).setSelectedLayer(audioLayer.id);
              r.read(editorProvider.notifier).setActiveToolbarCategory(null);
            },
          ),
          _ToolData(LucideIcons.music, 'Équilibreur', isNew: true, statusColor: Colors.cyan),
        ];
        break;
      case 'Format':
        tools = [
          _ToolData(
            LucideIcons.crop, 'Reframe',
            onTap: (ctx, r) {
              showReframePanel(ctx);
            },
          ),
          _ToolData(LucideIcons.monitorSmartphone, '9:16',
            onTap: (ctx, r) {
              r.read(editorProvider.notifier).setActiveToolbarCategory(null);
              // Aspect ratio change handled via Reframe panel
              showReframePanel(ctx);
            },
          ),
          _ToolData(LucideIcons.monitor, '16:9',
            onTap: (ctx, r) {
              r.read(editorProvider.notifier).setActiveToolbarCategory(null);
              showReframePanel(ctx);
            },
          ),
          _ToolData(LucideIcons.square, '1:1',
            onTap: (ctx, r) {
              r.read(editorProvider.notifier).setActiveToolbarCategory(null);
              showReframePanel(ctx);
            },
          ),
        ];
        break;
      case 'Texte':
        tools = [
          _ToolData(
            LucideIcons.type, 'Ajouter un\ntexte',
            onTap: (ctx, r) {
              r.read(editorProvider.notifier).addTextLayer();
              // Open text editor immediately for the new layer
              final state = r.read(editorProvider);
              final selectedId = state.selectedLayerId;
              final layer = state.currentProject?.layers
                  .where((l) => l.id == selectedId).firstOrNull;
              if (layer != null && ctx.mounted) {
                showTextEditorPanel(ctx, layer);
              }
            },
          ),
          _ToolData(
            LucideIcons.subtitles, 'Sous-titres\nauto', statusColor: Colors.cyan,
            onTap: (ctx, r) {
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AutoSubtitleSheet(),
              );
            },
          ),
          _ToolData(
            LucideIcons.mic2, 'Conversion\ntexte en voix', statusColor: Colors.red,
            onTap: (ctx, r) {
              final state = r.read(editorProvider);
              final layer = state.currentProject?.layers
                  .where((l) => l.type == 'text').firstOrNull ?? Layer(id: 'dummy', type: 'text', content: '', startTime: 0, duration: 5, style: const {});
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TextToSpeechSheet(targetLayer: layer),
              );
            },
          ),
        ];
        break;
      case 'Superposition':
        tools = [
          _ToolData(
            LucideIcons.image, 'Photo',
            onTap: (ctx, r) {
              // Ensure Pixabay is in image mode
              r.read(pixabayProvider.notifier).switchMediaType(PixabayMediaType.images);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => PixabayGalleryWidget(
                  onMediaImported: (filePath, isVideo) {
                    Navigator.of(ctx).pop();
                    r.read(editorProvider.notifier).addMediaLayer(
                      type: isVideo ? 'video' : 'image',
                      content: filePath,
                    );
                  },
                ),
              );
            },
          ),
          _ToolData(
            LucideIcons.video, 'Vidéo',
            onTap: (ctx, r) {
              // Ensure Pixabay is in video mode
              r.read(pixabayProvider.notifier).switchMediaType(PixabayMediaType.videos);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => PixabayGalleryWidget(
                  onMediaImported: (filePath, isVideo) {
                    Navigator.of(ctx).pop();
                    r.read(editorProvider.notifier).addMediaLayer(
                      type: isVideo ? 'video' : 'image',
                      content: filePath,
                    );
                  },
                ),
              );
            },
          ),
          _ToolData(
            LucideIcons.folderOpen, 'Ma galerie',
            onTap: (ctx, r) async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.media,
                allowMultiple: false,
              );
              if (result != null && ctx.mounted) {
                final path = result.files.single.path;
                if (path != null) {
                  final ext = path.split('.').last.toLowerCase();
                  final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'].contains(ext);
                  r.read(editorProvider.notifier).addMediaLayer(
                    type: isVideo ? 'video' : 'image',
                    content: path,
                  );
                }
              }
            },
          ),
        ];
        break;
      case 'Magique IA':
        tools = [
          _ToolData(LucideIcons.clapperboard, 'Image en vidéo', isNew: true, statusColor: Colors.cyan),
          _ToolData(LucideIcons.palette, 'Art IA', isNew: true, statusColor: Colors.cyan),
          _ToolData(LucideIcons.sparkles, 'Génération images', isNew: true, statusColor: Colors.cyan),
          _ToolData(
            LucideIcons.mic2, 'Texte en voix', statusColor: Colors.red,
            onTap: (ctx, r) {
              final state = r.read(editorProvider);
              final layer = state.currentProject?.layers
                  .where((l) => l.type == 'text').firstOrNull
                  ?? Layer(id: 'dummy', type: 'text', content: '', startTime: 0, duration: 5, style: const {});
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TextToSpeechSheet(targetLayer: layer),
              );
            },
          ),
          _ToolData(LucideIcons.music, 'Créateur IA Musique', isNew: true, statusColor: Colors.cyan),
          _ToolData(LucideIcons.userCheck, 'Avatar vocal', isNew: true, statusColor: Colors.cyan),
        ];
        break;
      case 'Stickers':
        tools = [
          _ToolData(LucideIcons.smile, 'Stickers', onTap: (ctx, r) => showStickerPicker(ctx)),
          _ToolData(LucideIcons.heart, 'Favoris', onTap: (ctx, r) => showStickerPicker(ctx)),
          _ToolData(LucideIcons.sparkles, 'Emojis IA', isNew: true, statusColor: Colors.cyan),
        ];
        break;
    }

    if (tools.isEmpty) return const SizedBox.shrink();

    if (category == 'Magique IA') {
      return Container(
        height: 160,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: tools.map((t) => SizedBox(width: 65, child: _ToolItem(tool: t))).toList(),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: tools.length <= 4
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: tools.map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 60,
                  child: _ToolItem(tool: t),
                ),
              )).toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: tools.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 60,
                    child: _ToolItem(tool: t),
                  ),
                )).toList(),
              ),
            ),
    );
  }
}

class _ToolData {
  final IconData icon;
  final String label;
  final bool isNew;
  final Color? statusColor;
  final void Function(BuildContext ctx, WidgetRef ref)? onTap;

  _ToolData(this.icon, this.label, {this.isNew = false, this.statusColor, this.onTap});
}

class _ToolItem extends ConsumerWidget {
  final _ToolData tool;
  const _ToolItem({required this.tool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: tool.onTap != null ? () => tool.onTap!(context, ref) : null,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: Colors.white, size: 24),
            ),
            if (tool.statusColor != null)
              Positioned(
                top: -2,
                left: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tool.statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A1A2E), width: 1.5),
                  ),
                ),
              ),
            if (tool.isNew)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tool.label,
          style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.1),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
      ],
    ),   // Column
    );   // GestureDetector
  }
}
