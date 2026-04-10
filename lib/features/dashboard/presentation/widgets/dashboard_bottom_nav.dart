import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF121414).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _NavItem(icon: LucideIcons.home, label: 'HOME', isActive: currentIndex == 0, onTap: () => onTabChanged(0))),
                Expanded(child: _NavItem(icon: LucideIcons.sparkles, label: 'TEMPLATES', isActive: currentIndex == 1, onTap: () => onTabChanged(1))),
                Expanded(child: _NavItem(icon: LucideIcons.folderEdit, label: 'PROJECTS', isActive: currentIndex == 2, onTap: () => onTabChanged(2))),
                Expanded(child: _NavItem(icon: LucideIcons.user, label: 'PROFILE', isActive: currentIndex == 3, onTap: () => onTabChanged(3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.white54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isActive ? Theme.of(context).colorScheme.primary : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

