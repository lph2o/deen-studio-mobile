import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deen_studio_01/core/models/template.dart';
import 'package:deen_studio_01/core/models/template_presets.dart';
import 'package:deen_studio_01/features/auth/presentation/auth_state.dart';

class TemplatesView extends ConsumerStatefulWidget {
  const TemplatesView({super.key});

  @override
  ConsumerState<TemplatesView> createState() => _TemplatesViewState();
}

class _TemplatesViewState extends ConsumerState<TemplatesView> {
  String _selectedCategory = 'All';

  List<Template> get _filteredTemplates {
    if (_selectedCategory == 'All') return kBuiltInTemplates;
    return kBuiltInTemplates.where((t) {
      switch (_selectedCategory.toLowerCase()) {
        case 'quran':
          return t.category == 'quran';
        case 'reminders':
          return t.category == 'reminder';
        case 'story':
          return t.category == 'cinematic' || t.category == 'nature';
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _useTemplate(Template template) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour utiliser un template'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Convert template to project
      final projectId = 'proj_${DateTime.now().millisecondsSinceEpoch}';
      final project = template.toProject(userId: userId, projectId: projectId);

      // Save to Supabase
      await Supabase.instance.client
          .from('projects')
          .insert(project.toInsertMap())
          .select()
          .single();

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      // Navigate to editor
      context.push('/editor/$projectId');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la creation du projet: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = _filteredTemplates;
    final featuredTemplate = templates.isNotEmpty ? templates.first : null;
    final gridTemplates = templates.length > 1 ? templates.sublist(1) : [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                            color: theme.colorScheme.onSurface,
                          ),
                          children: [
                            const TextSpan(text: 'Creative\n'),
                            TextSpan(
                              text: 'Templates',
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.filter),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Curated visual landscapes for Quranic expression. Each template is designed to honor the sacred text through cinematic artistry.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip(theme, 'All', isSelected: _selectedCategory == 'All'),
                      const SizedBox(width: 8),
                      _buildChip(theme, 'Quran', isSelected: _selectedCategory == 'Quran'),
                      const SizedBox(width: 8),
                      _buildChip(theme, 'Reminders', isSelected: _selectedCategory == 'Reminders'),
                      const SizedBox(width: 8),
                      _buildChip(theme, 'Story', isSelected: _selectedCategory == 'Story'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Featured Template (Large)
                if (featuredTemplate != null)
                  _FeaturedTemplateCard(
                    theme: theme,
                    template: featuredTemplate,
                    onTap: () => _useTemplate(featuredTemplate),
                  ),
              ],
            ),
          ),
        ),

        // Grid for remaining templates
        if (gridTemplates.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final template = gridTemplates[index];
                  return _GridTemplateCard(
                    theme: theme,
                    template: template,
                    onTap: () => _useTemplate(template),
                  );
                },
                childCount: gridTemplates.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? null : theme.colorScheme.surfaceContainerHigh,
          gradient: isSelected
              ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer])
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _FeaturedTemplateCard extends StatelessWidget {
  final ThemeData theme;
  final Template template;
  final VoidCallback onTap;

  const _FeaturedTemplateCard({
    required this.theme,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
          image: DecorationImage(
            image: NetworkImage(template.thumbnailUrl),
            fit: BoxFit.cover,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.colorScheme.surface.withValues(alpha: 0.9),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      template.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${template.aspectRatio} Resolution',
                    style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridTemplateCard extends StatelessWidget {
  final ThemeData theme;
  final Template template;
  final VoidCallback onTap;

  const _GridTemplateCard({
    required this.theme,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              template.thumbnailUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Center(
                    child: Icon(LucideIcons.image, color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.surface.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.play, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      template.aspectRatio,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
