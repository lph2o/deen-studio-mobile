import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import '../../../../models/project.dart';
import '../editor_state.dart';

/// A non-intrusive multi-cam switcher that appears in the preview area.
/// Shows angle buttons with live thumbnails for switching between camera angles.
class MultiCamSwitcher extends ConsumerStatefulWidget {
  const MultiCamSwitcher({super.key});

  @override
  ConsumerState<MultiCamSwitcher> createState() => _MultiCamSwitcherState();
}

class _MultiCamSwitcherState extends ConsumerState<MultiCamSwitcher> {
  bool _isExpanded = true;
  final Map<String, VideoPlayerController> _thumbnailControllers = {};

  @override
  void dispose() {
    for (final controller in _thumbnailControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final project = state.currentProject;
    if (project == null || project.multiCamGroups.isEmpty) return const SizedBox.shrink();

    // Show switcher for the first multi-cam group (can be extended for multiple groups)
    final group = project.multiCamGroups.first;

    return Positioned(
      bottom: 16,
      left: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(_isExpanded ? 12 : 24),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: _isExpanded ? _buildExpanded(group, context) : _buildMinimized(context),
      ),
    );
  }

  Widget _buildMinimized(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: const Icon(LucideIcons.split, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildExpanded(MultiCamGroup group, BuildContext context) {
    final notifier = ref.read(editorProvider.notifier);
    final state = ref.read(editorProvider);
    final project = state.currentProject!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(LucideIcons.split, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Minimize button
              IconButton(
                icon: const Icon(LucideIcons.minimize, size: 14, color: Colors.white70),
                onPressed: () => setState(() => _isExpanded = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              // Remove group button
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      title: const Text('Remove Multi-Cam Group'),
                      content: const Text(
                        'This will remove the multi-cam group but keep all video layers intact. Continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            notifier.removeMultiCamGroup(group.id);
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Angle buttons in a horizontal scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: group.angles.asMap().entries.map((entry) {
                final index = entry.key;
                final angle = entry.value;
                final isActive = index == group.activeAngleIndex;
                final layer = project.layers.where((l) => l.id == angle.layerId).firstOrNull;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _AngleButton(
                    angle: angle,
                    layer: layer,
                    isActive: isActive,
                    index: index,
                    groupId: group.id,
                    syncOffset: angle.syncOffset,
                    onSyncOffsetChanged: (offset) {
                      notifier.updateMultiCamSyncOffset(group.id, index, offset);
                    },
                    onSwitchAngle: () {
                      notifier.switchMultiCamAngle(group.id, index);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual angle button with thumbnail preview.
class _AngleButton extends StatefulWidget {
  final MultiCamAngle angle;
  final Layer? layer;
  final bool isActive;
  final int index;
  final String groupId;
  final double syncOffset;
  final Function(double) onSyncOffsetChanged;
  final VoidCallback onSwitchAngle;

  const _AngleButton({
    required this.angle,
    required this.layer,
    required this.isActive,
    required this.index,
    required this.groupId,
    required this.syncOffset,
    required this.onSyncOffsetChanged,
    required this.onSwitchAngle,
  });

  @override
  State<_AngleButton> createState() => _AngleButtonState();
}

class _AngleButtonState extends State<_AngleButton> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showSyncEditor = false;
  final TextEditingController _syncController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant _AngleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.angle.layerId != widget.angle.layerId) {
      _controller?.dispose();
      _isInitialized = false;
      _initializeController();
    }
  }

  void _initializeController() {
    final layer = widget.layer;
    if (layer == null || layer.content.isEmpty || !layer.content.startsWith('/')) return;

    _controller = VideoPlayerController.file(File(layer.content))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller?.setVolume(0);
          _controller?.setLooping(true);
          _controller?.play();
        }
      }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _syncController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.isActive) {
          widget.onSwitchAngle();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 80,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isActive ? const Color(0xFF3B82F6) : Colors.white24,
            width: widget.isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              child: SizedBox(
                width: 80,
                height: 45,
                child: _isInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(LucideIcons.video, size: 20, color: Colors.white54),
                        ),
                      ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                children: [
                  Text(
                    widget.angle.label,
                    style: TextStyle(
                      color: widget.isActive ? const Color(0xFF3B82F6) : Colors.white70,
                      fontSize: 10,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Sync offset indicator
                  if (widget.syncOffset != 0)
                    Text(
                      '${widget.syncOffset > 0 ? '+' : ''}${widget.syncOffset.toStringAsFixed(1)}s',
                      style: const TextStyle(color: Colors.white54, fontSize: 8),
                    ),
                ],
              ),
            ),
            // Sync edit button
            GestureDetector(
              onTap: () {
                setState(() => _showSyncEditor = !_showSyncEditor);
                if (_showSyncEditor) {
                  _syncController.text = widget.syncOffset.toStringAsFixed(2);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: _showSyncEditor ? Colors.white10 : Colors.transparent,
                child: _showSyncEditor
                    ? _buildSyncEditor()
                    : const Icon(LucideIcons.clock, size: 10, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _syncController,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            style: const TextStyle(fontSize: 10, color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              hintText: 'Offset',
              hintStyle: TextStyle(fontSize: 8, color: Colors.white38),
            ),
            onSubmitted: (value) {
              final offset = double.tryParse(value);
              if (offset != null) {
                widget.onSyncOffsetChanged(offset.clamp(-10.0, 10.0));
              }
              setState(() => _showSyncEditor = false);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _syncAdjustButton(-0.5),
              _syncAdjustButton(-0.1),
              _syncAdjustButton(0.1),
              _syncAdjustButton(0.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _syncAdjustButton(double delta) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final newOffset = (widget.syncOffset + delta).clamp(-10.0, 10.0);
          widget.onSyncOffsetChanged(newOffset);
          _syncController.text = newOffset.toStringAsFixed(2);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            delta > 0 ? '+${delta.toStringAsFixed(1)}' : delta.toStringAsFixed(1),
            style: const TextStyle(fontSize: 8, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
