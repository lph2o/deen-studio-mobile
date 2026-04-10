import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deen_studio_01/core/models/voice_effect.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/features/editor/presentation/editor_state.dart';

/// Bottom sheet that displays voice effect presets in a grid.
/// Tapping an effect applies it to the given audio layer and closes the sheet.
class VoiceEffectPicker extends ConsumerWidget {
  final String layerId;

  const VoiceEffectPicker({super.key, required this.layerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.read(editorProvider);
    final layer = state.currentProject?.layers.firstWhere(
      (l) => l.id == layerId,
      orElse: () => Layer(
        id: '',
        type: 'audio',
        content: '',
        startTime: 0,
        duration: 0,
        style: {},
        voiceEffectId: 'none',
      ),
    );
    final currentEffectId = layer?.voiceEffectId ?? 'none';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Effets vocaux',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: kVoiceEffects.length,
            itemBuilder: (context, index) {
              final effect = kVoiceEffects[index];
              final isSelected = effect.id == currentEffectId;
              return _VoiceEffectButton(
                effect: effect,
                isSelected: isSelected,
                onTap: () {
                  ref.read(editorProvider.notifier).applyVoiceEffect(layerId, effect.id);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VoiceEffectButton extends StatelessWidget {
  final VoiceEffect effect;
  final bool isSelected;
  final VoidCallback onTap;

  const _VoiceEffectButton({
    required this.effect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                effect.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                effect.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show the voice effect picker as a modal bottom sheet.
void showVoiceEffectPicker(BuildContext context, String layerId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Material(
      color: Colors.transparent,
      child: VoiceEffectPicker(layerId: layerId),
    ),
  );
}
