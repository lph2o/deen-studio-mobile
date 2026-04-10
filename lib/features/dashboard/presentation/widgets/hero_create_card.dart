import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deen_studio_01/core/models/template.dart';
import 'package:deen_studio_01/core/models/template_presets.dart';
import 'package:deen_studio_01/features/auth/presentation/auth_state.dart';

class HeroCreateCard extends ConsumerStatefulWidget {
  const HeroCreateCard({super.key});

  @override
  ConsumerState<HeroCreateCard> createState() => _HeroCreateCardState();
}

class _HeroCreateCardState extends ConsumerState<HeroCreateCard> {
  Future<void> _useTemplate(Template template) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour créer une vidéo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final projectId = 'proj_${DateTime.now().millisecondsSinceEpoch}';
      final project = template.toProject(userId: userId, projectId: projectId);

      await Supabase.instance.client
          .from('projects')
          .insert(project.toInsertMap())
          .select()
          .single();

      if (!mounted) return;
      Navigator.of(context).pop();

      // Launch the editor directly!
      context.push('/editor/$projectId');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Select top tier premium templates for the hero section
    final showcaseTemplates = [
      getTemplateById('quran_golden'),
      getTemplateById('verset_du_jour'),
      getTemplateById('nature_paix'),
      getTemplateById('cinematique'),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.zap, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'CREATION RAPIDE',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Commencez avec un style.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: showcaseTemplates.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final template = showcaseTemplates[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _HeroTemplateCard(
                  template: template,
                  theme: theme,
                  onTap: () => _useTemplate(template),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeroTemplateCard extends StatelessWidget {
  final Template template;
  final ThemeData theme;
  final VoidCallback onTap;

  const _HeroTemplateCard({
    required this.template,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              template.thumbnailUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.surface.withValues(alpha: 0.95),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
