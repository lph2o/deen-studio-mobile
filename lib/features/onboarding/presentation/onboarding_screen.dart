import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Hero(
                tag: 'logo_full',
                child: SvgPicture.asset(
                  'assets/svg/Logo_Deen_Studio_avec_nom.svg',
                  height: 48,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
                  
                  // Phone Mockup
                  Transform.rotate(
                    angle: -0.05,
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white10, width: 6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('9:41', style: TextStyle(fontSize: 10, color: Colors.white24)),
                                    Row(
                                      children: [
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle)),
                                        const SizedBox(width: 4),
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                    style: GoogleFonts.amiri(
                                      color: theme.colorScheme.primary,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(height: 4, width: 100, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 6),
                              Container(height: 4, width: 60, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('00:12 / 00:45', style: TextStyle(fontSize: 10, color: Colors.white38)),
                                        Icon(LucideIcons.sparkles, size: 12, color: theme.colorScheme.secondary),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            margin: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                              border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 2)),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).moveY(begin: 20, end: 0),
                  
                  // Floating Badges
                  Positioned(
                    top: 80,
                    right: 40,
                    child: _FloatingBadge(
                      icon: LucideIcons.sparkles,
                      label: 'EFFECTS',
                      value: 'Golden Glow',
                      color: theme.colorScheme.secondary,
                    ),
                  ).animate().fadeIn(delay: 500.ms).moveX(begin: 20, end: 0),
                  
                  Positioned(
                    bottom: 120,
                    left: 20,
                    child: _FloatingBadge(
                      icon: LucideIcons.bookOpen,
                      label: 'SOURCE',
                      value: 'Surah Al-Fatihah',
                      color: theme.colorScheme.primary,
                    ),
                  ).animate().fadeIn(delay: 700.ms).moveX(begin: -20, end: 0),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                   Text(
                    'Create Quranic\nvideos easily.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A professional studio for spiritual content creators, designed for focus and inspiration.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () => context.push('/onboarding-features'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('NEXT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 32, height: 6, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
