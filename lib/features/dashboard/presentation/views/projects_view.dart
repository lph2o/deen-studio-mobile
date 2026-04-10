import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:deen_studio_01/models/project.dart';

final dashboardProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('projects')
      .select()
      .order('updated_at', ascending: false);
  return (response as List<dynamic>).map((m) => Project.fromMap(m)).toList();
});

class ProjectsView extends ConsumerWidget {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(dashboardProjectsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Projects',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.invalidate(dashboardProjectsProvider);
                },
                icon: const Icon(LucideIcons.refreshCw, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading projects', style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.folderOpen, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text('No projects found', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white54)),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/select-surah'),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('Create Project'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _ProjectGridCard(project: project);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectGridCard extends ConsumerWidget {
  final Project project;

  const _ProjectGridCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => context.go('/editor/${project.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://picsum.photos/seed/spiritual/400/300'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Container(
                     padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.play, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Text(
                          project.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                        ),
                       ),
                       InkWell(
                         onTap: () async {
                           try {
                             await Supabase.instance.client.from('projects').delete().eq('id', project.id);
                             ref.invalidate(dashboardProjectsProvider);
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: const Text('Project deleted'),
                                   behavior: SnackBarBehavior.floating,
                                   backgroundColor: theme.colorScheme.primary,
                                 )
                               );
                             }
                           } catch (e) {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                             }
                           }
                         },
                         child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white38),
                       )
                     ],
                   ),
                  const SizedBox(height: 4),
                  Text(
                    'Edited ${_formatDate(project.updatedAt)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
