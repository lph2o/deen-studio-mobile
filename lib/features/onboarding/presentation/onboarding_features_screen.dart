import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingFeaturesScreen extends StatefulWidget {
  const OnboardingFeaturesScreen({super.key});

  @override
  State<OnboardingFeaturesScreen> createState() => _OnboardingFeaturesScreenState();
}

class _OnboardingFeaturesScreenState extends State<OnboardingFeaturesScreen> {
  final Set<String> _selectedReciters = {'alafasy'};

  void _toggleReciter(String id) {
    setState(() {
      if (_selectedReciters.contains(id)) {
        _selectedReciters.remove(id);
      } else {
        _selectedReciters.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(child: _ProgressSegment(color: theme.colorScheme.secondary)),
                  const SizedBox(width: 8),
                  Expanded(child: _ProgressSegment(color: theme.colorScheme.secondary)),
                  const SizedBox(width: 8),
                  Expanded(child: _ProgressSegment(color: theme.colorScheme.surfaceContainerHighest)),
                  const SizedBox(width: 8),
                  Expanded(child: _ProgressSegment(color: theme.colorScheme.surfaceContainerHighest)),
                ],
              ),
              const SizedBox(height: 48),
              
              // Header
              Text(
                'Choose reciters and verses.',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Personalize your experience by selecting the voices that move you and the chapters that inspire you.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              
              // Reciter Grid
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Audio Waveform Feature Card
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 16,
                            left: 24,
                            child: Row(
                              children: [
                                Icon(LucideIcons.barChart2, size: 16, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'AUDIO PRECISION',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _AudioBar(height: 16, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                                _AudioBar(height: 30, color: theme.colorScheme.primaryContainer),
                                _AudioBar(height: 50, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                                _AudioBar(height: 35, color: theme.colorScheme.secondary),
                                _AudioBar(height: 60, color: theme.colorScheme.primary),
                                _AudioBar(height: 40, color: theme.colorScheme.primaryContainer),
                                _AudioBar(height: 20, color: theme.colorScheme.secondary),
                                _AudioBar(height: 50, color: theme.colorScheme.primary),
                                _AudioBar(height: 30, color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6)),
                                _AudioBar(height: 10, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Reciters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'World-Renowned Reciters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.secondary),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ReciterTile(
                      id: 'alafasy',
                      name: 'Mishary Rashid Alafasy',
                      description: 'Melodic & Soulful',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC6AyjdM5MjMVGp1f0zVxtnsP3WmWNrCbv5EwzYib_7uUyXewBcjXL7KfhgKPQMeCtFzHgeE0eyzcZ2u6uJXGdPKQbqGk7V2qtvApSC1STE7PhUsl_Z5gtQtfdTAqkgAX2eCaxlH3X1jrOCDySduevD0h0ulAYQvW_ILqlKDg_HAR-0yZbL1bUr6DWxvhoapolX4_aVlf4ef52uT1l3Z0dPoZrondh0Qrnfygg67bh4PeWwHZPtNbLIi7TFuXY6L-nXoJtCJ1oCtoVK',
                      isSelected: _selectedReciters.contains('alafasy'),
                      onTap: () => _toggleReciter('alafasy'),
                    ),
                    const SizedBox(height: 12),
                    _ReciterTile(
                      id: 'sudais',
                      name: 'Abdul Rahman Al-Sudais',
                      description: 'Powerful & Rhythmic',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDD37eipG_B1KJKaoJC-DEimv0WhrLE-Br_mWqW3kDuF_uLhZvu5QAQzw9FIaHu82FzwO8CR5IxxO-oFREuf6nE0bdYEx6IWBR0CyLuGyl2hRicqHu_YOrH0h3jNiJspgN2BmpgpQ7t13FyO-2pmGt2PpKRS-w25leNyFeTD4fb4kK5R9SuRRFvBCG51xs21ylx6ouUIM2hNK5-W6CdiA3lefc9Yl4RePH3SDJaEzAFaOQiC77ePZiRP1aF-y-WbCSu75ZwbWWJRABb',
                      isSelected: _selectedReciters.contains('sudais'),
                      onTap: () => _toggleReciter('sudais'),
                    ),
                    const SizedBox(height: 12),
                    _ReciterTile(
                      id: 'muaiqly',
                      name: 'Maher Al-Muaiqly',
                      description: 'Calm & Clear',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAEYAVOe_L5-xTURsBwdeJOulTnKhAHtf4nlHAfxxgykLkrvTOIDN9-4FcwnJwbqe3-r3ytK6A_iW3c8fBXkVZ4wURjZB0dL_Jt_b6FKm_hP4NWc2SOL9F7UbuHhKMl0YNGkx-kstIJuvFGmiz2jz5h1MXY4gRIDi1qaczXvJiI6oAB5RpWKNEChMvk_B1hj4X_llmXKb_dSSrzCpnO0HiRBRP4WrjQe3Hs2e6V6yoxMvZgwwszuFilEqqWUBz1g2vz8ub9bgCN2Lzt',
                      isSelected: _selectedReciters.contains('muaiqly'),
                      onTap: () => _toggleReciter('muaiqly'),
                    ),
                    const SizedBox(height: 32),
                    
                    // Favorite Verses Preview
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Favorite Verses',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(LucideIcons.bookOpen, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ChipItem(label: 'Al-Fatihah', isPrimary: true),
                              _ChipItem(label: 'Al-Baqarah'),
                              _ChipItem(label: 'Ar-Rahman', isPrimary: true),
                              _ChipItem(label: 'Ya-Sin'),
                            ],
                          ),
                        ],
                      ),
                    ),
                     const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Footer CTA
              InkWell(
                onTap: () => context.push('/onboarding-get-started'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, color: theme.colorScheme.onPrimary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'STEP 2 OF 4',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 2.0,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final Color color;
  const _ProgressSegment({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  final double height;
  final Color color;
  const _AudioBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReciterTile({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.secondary.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.outlineVariant,
                  width: 2,
                ),
                color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: theme.colorScheme.surface)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _ChipItem({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
