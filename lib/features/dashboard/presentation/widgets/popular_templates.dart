import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PopularTemplates extends StatelessWidget {
  const PopularTemplates({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Templates',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
          ),
          child: Column(
            children: [
              _TemplateTile(
                icon: LucideIcons.sparkles,
                iconBgColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                iconColor: theme.colorScheme.primary,
                title: 'Quran Stories',
                subtitle: 'Cinematic vertical format',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white.withValues(alpha: 0.02), height: 1),
              ),
              _TemplateTile(
                icon: LucideIcons.penTool,
                iconBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                iconColor: theme.colorScheme.tertiary,
                title: 'Daily Reminders',
                subtitle: 'Minimal typography focus',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white.withValues(alpha: 0.02), height: 1),
              ),
              _TemplateTile(
                icon: LucideIcons.moreHorizontal,
                iconBgColor: Colors.white.withValues(alpha: 0.03),
                iconColor: Colors.white54,
                title: 'Browse Library',
                subtitle: '50+ custom layouts',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _TemplateTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template library is coming soon!')),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
