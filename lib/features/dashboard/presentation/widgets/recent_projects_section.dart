import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:deen_studio_01/models/project.dart';

class RecentProjectsSection extends StatelessWidget {
  const RecentProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supabase = Supabase.instance.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Recent Projects',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'View all',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('projects').stream(primaryKey: ['id']).order('updated_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error loading projects', style: TextStyle(color: theme.colorScheme.error)));
            }
            if (!snapshot.hasData) {
              return const Center(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
            }

            final projects = snapshot.data!.map((m) => Project.fromMap(m)).toList();

            if (projects.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.folderOpen, size: 32, color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text('No projects found', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length > 4 ? 4 : projects.length, // Limit to 4 for dashboard
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _ProjectTile(project: projects[index]),
            );
          },
        ),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;

  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => context.go('/editor/${project.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: NetworkImage('https://picsum.photos/seed/spiritual/300/200'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.play, color: Colors.white, size: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 10, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Edited ${_formatDate(project.updatedAt)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                // Delete project from database
                await Supabase.instance.client.from('projects').delete().eq('id', project.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Project "${project.title}" deleted')),
                  );
                }
              }, 
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.white38)
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
