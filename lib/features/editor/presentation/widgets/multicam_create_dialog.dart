import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/project.dart';

/// Dialog for creating a multi-cam group by selecting video layers.
class MultiCamCreateDialog extends StatefulWidget {
  final Project project;

  const MultiCamCreateDialog({super.key, required this.project});

  @override
  State<MultiCamCreateDialog> createState() => _MultiCamCreateDialogState();
}

class _MultiCamCreateDialogState extends State<MultiCamCreateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedLayerIds = {};

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Multi-Cam Group ${widget.project.multiCamGroups.length + 1}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<Layer> get _videoLayers =>
      widget.project.layers.where((l) => l.type == 'video').toList();

  void _toggleLayer(String layerId) {
    setState(() {
      if (_selectedLayerIds.contains(layerId)) {
        _selectedLayerIds.remove(layerId);
      } else {
        _selectedLayerIds.add(layerId);
      }
    });
  }

  void _create() {
    if (_selectedLayerIds.length < 2) return;

    // Order layers by their original order in the project
    final orderedIds = _videoLayers
        .where((l) => _selectedLayerIds.contains(l.id))
        .map((l) => l.id)
        .toList();

    Navigator.of(context).pop({
      'layerIds': orderedIds,
      'name': _nameController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoLayers = _videoLayers;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.split, color: Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                const Text(
                  'Create Multi-Cam Group',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            Text(
              'Select 2 or more video layers to group:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Layer selection list
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: videoLayers.length,
                itemBuilder: (context, index) {
                  final layer = videoLayers[index];
                  final isSelected = _selectedLayerIds.contains(layer.id);
                  final angleNumber = index + 1;

                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$angleNumber',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Cam $angleNumber',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      layer.content.split('/').last,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      isSelected ? LucideIcons.checkSquare : LucideIcons.square,
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.white38,
                      size: 20,
                    ),
                    onTap: () => _toggleLayer(layer.id),
                    dense: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Selection count
            Text(
              '${_selectedLayerIds.length} layer${_selectedLayerIds.length == 1 ? '' : 's'} selected',
              style: TextStyle(
                color: _selectedLayerIds.length >= 2 ? Colors.greenAccent : Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedLayerIds.length >= 2 ? _create : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                  ),
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
