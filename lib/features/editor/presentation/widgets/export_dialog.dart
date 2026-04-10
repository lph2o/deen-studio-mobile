import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:deen_studio_01/core/theme.dart';
import 'package:deen_studio_01/core/services/video_export_service.dart';
import 'package:deen_studio_01/core/ui/design_system.dart';
import 'package:deen_studio_01/features/editor/presentation/editor_state.dart';
import 'package:deen_studio_01/core/utils/toast_service.dart';

/// Export dialog with resolution/quality settings and progress tracking.
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  String _resolution = '720p';
  int _fps = 30;
  int _videoBitrate = 5000;
  int _audioBitrate = 192;
  bool _isExporting = false;
  double _progress = 0.0;
  String _message = '';
  String? _exportedPath;

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _message = 'Preparation de l\'export...';
      _exportedPath = null;
    });

    final project = ref.read(editorProvider).currentProject;
    if (project == null) {
      setState(() {
        _message = 'Erreur: Aucun projet charge.';
        _isExporting = false;
      });
      return;
    }

    final service = VideoExportService(
      settings: ExportSettings(
        resolution: _resolution,
        fps: _fps,
        videoBitrate: _videoBitrate,
        audioBitrate: _audioBitrate,
      ),
    );

    final path = await service.exportProject(
      project: project,
      context: context,
      onProgress: (progress, message) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _message = message;
          });
        }
      },
    );

    if (mounted) {
      if (path != null) {
        setState(() {
          _exportedPath = path;
          _isExporting = false;
          _message = 'Export termine avec succes !';
        });
        ToastService.showSuccess(context, 'Video exportee avec succes !');
      } else {
        setState(() {
          _isExporting = false;
          _message = 'L\'export a echoue. Verifiez les logs pour plus de details.';
        });
        ToastService.showError(context, 'Erreur lors de l\'export video.');
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_exportedPath == null) return;
    await Share.shareXFiles([XFile(_exportedPath!)], text: 'Video creee avec Deen Studio');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(LucideIcons.download, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Exporter la video',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_isExporting && _exportedPath == null) ...[
                // Resolution
                _buildSectionTitle('Resolution'),
                _buildResolutionSelector(),
                const SizedBox(height: 6),
                Text(
                  'Ratio: ${ref.read(editorProvider).currentProject?.aspectRatio ?? "9:16"}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                ),
                const SizedBox(height: 16),

                // FPS
                _buildSectionTitle('Images par seconde (FPS)'),
                _buildFpsSelector(),
                const SizedBox(height: 16),

                // Quality
                _buildSectionTitle('Qualite'),
                _buildQualitySliders(),
                const SizedBox(height: 20),

                // Export button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startExport,
                    icon: const Icon(LucideIcons.video),
                    label: const Text('Exporter'),
                  ),
                ),
              ] else if (_isExporting) ...[
                // Progress
                _buildSectionTitle(_message),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Cela peut prendre plusieurs minutes selon la duree du projet.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else if (_exportedPath != null) ...[
                // Success
                ControlGroup(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Export termine !',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              Text(
                                'Video sauvegardee dans vos documents.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x),
                        label: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareVideo,
                        icon: const Icon(LucideIcons.share2),
                        label: const Text('Partager'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Error
                ControlGroup(
                  children: [
                    Text(
                      _message,
                      style: TextStyle(color: AppTheme.secondaryColor, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Widget _buildResolutionSelector() {
    return Row(
      children: ['480p', '720p', '1080p'].map((res) {
        final isSelected = _resolution == res;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PillButton(
              label: res,
              selected: isSelected,
              onTap: () => setState(() => _resolution = res),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFpsSelector() {
    return Row(
      children: [24, 30, 60].map((fps) {
        final isSelected = _fps == fps;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PillButton(
              label: '$fps fps',
              selected: isSelected,
              onTap: () => setState(() => _fps = fps),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQualitySliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderRow(
          label: 'Video',
          value: _videoBitrate.toDouble(),
          min: 1000,
          max: 10000,
          divisions: 9,
          onChanged: (v) => setState(() => _videoBitrate = v.toInt()),
          valueLabel: (v) => '${v.toInt()} kbps',
        ),
        SliderRow(
          label: 'Audio',
          value: _audioBitrate.toDouble(),
          min: 64,
          max: 320,
          divisions: 4,
          onChanged: (v) => setState(() => _audioBitrate = v.toInt()),
          valueLabel: (v) => '${v.toInt()} kbps',
        ),
      ],
    );
  }
}
