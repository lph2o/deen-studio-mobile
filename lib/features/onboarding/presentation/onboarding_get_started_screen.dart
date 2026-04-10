import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingGetStartedScreen extends StatelessWidget {
  const OnboardingGetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Check Icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        children: [
                          const TextSpan(text: 'Ready to '),
                          TextSpan(
                            text: 'Share',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cinematic Quranic creation is ready. Export for TikTok / Reels in stunning high definition.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Platform Bento Box Grid
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(child: _PlatformBox(icon: Icons.music_note, title: 'TikTok')),
                          const SizedBox(width: 16),
                          Expanded(child: _PlatformBox(icon: Icons.camera_alt, title: 'Reels')),
                          const SizedBox(width: 16),
                          Expanded(child: _PlatformBox(icon: Icons.smart_display, title: 'Shorts')),
                          const SizedBox(width: 16),
                          Expanded(child: _PlatformBox(icon: Icons.download, title: 'Download')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Preview Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 260,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuC8oY7LiEP3SncwphhgMhLImx83nbsm1jqEsoLab-7eH1T39uMKNu3Yf_yPrDZTDv_dBD--NgLy6VARvyLDPgL38IK-muWBgzMYBOX7qis-sJp6ZwWr8yeNSi_EPOz5ycJ6QROVmH732ErYOyPexxCDBCl_gQPdnmjz3FgYduguJjJihKXLu-zbynlk7bEDRZe1NEB97fxwic_1kBO5kWCVvQYSljlkDXJDvK4-Tn04X7vEpUS4cADxJQPRB7hRLyB-GG20xSao049n',
                          ),
                          fit: BoxFit.cover,
                          opacity: 0.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'PREVIEW RENDERED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Start Creating CTA
                    InkWell(
                      onTap: () => context.go('/login'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.secondary,
                              theme.colorScheme.secondaryContainer,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start Creating',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.arrowRight, color: theme.colorScheme.onSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'JOIN 10,000+ DIGITAL CREATORS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformBox extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PlatformBox({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121414).withValues(alpha: 0.6), // Glass look
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
