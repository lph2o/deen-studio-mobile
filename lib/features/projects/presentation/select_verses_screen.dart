import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../quran_studio/presentation/state/quran_studio_notifier.dart';

class SelectVersesScreen extends ConsumerStatefulWidget {
  const SelectVersesScreen({super.key});

  @override
  ConsumerState<SelectVersesScreen> createState() => _SelectVersesScreenState();
}

class _SelectVersesScreenState extends ConsumerState<SelectVersesScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quranStateAsync = ref.watch(quranStudioProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Deen Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.user, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: quranStateAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (state) {
          final surah = state.selectedSurah;
          if (surah == null) {
            return const Center(child: Text('No Surah selected.'));
          }

          final startAyah = state.startAyah;
          final endAyah = state.endAyah;
          final totalSelected = endAyah - startAyah + 1;
          final isWarning = totalSelected > 10;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT VERSES',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            surah.englishName,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${surah.englishNameTranslation} • ${surah.numberOfAyahs} Verses',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Range Slider Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: isWarning ? Border.all(color: theme.colorScheme.error) : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Range Selection', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                                    Text('$startAyah — $endAyah', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                RangeSlider(
                                  values: RangeValues(startAyah.toDouble(), endAyah.toDouble()),
                                  min: 1,
                                  max: surah.numberOfAyahs.toDouble(),
                                  divisions: surah.numberOfAyahs > 1 ? surah.numberOfAyahs - 1 : 1,
                                  activeColor: isWarning ? theme.colorScheme.error : theme.colorScheme.primary,
                                  inactiveColor: theme.colorScheme.surfaceContainerHighest,
                                  labels: RangeLabels('$startAyah', '$endAyah'),
                                  onChanged: (RangeValues values) {
                                    ref.read(quranStudioProvider.notifier).updateVersesRange(
                                      values.start.round(), 
                                      values.end.round()
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('VERSE 1', style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                                    Text('VERSE ${surah.numberOfAyahs}', style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                                  ],
                                ),
                                if (isWarning)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.alertTriangle, size: 14, color: theme.colorScheme.error),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Warning: Generating more than 10 verses may result in long processing times.',
                                            style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Quick Action Pills
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  label: const Text('First 3', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    final end = surah.numberOfAyahs >= 3 ? 3 : surah.numberOfAyahs;
                                    ref.read(quranStudioProvider.notifier).updateVersesRange(1, end);
                                  },
                                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                  side: BorderSide.none,
                                ),
                                ActionChip(
                                  label: const Text('First 5', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    final end = surah.numberOfAyahs >= 5 ? 5 : surah.numberOfAyahs;
                                    ref.read(quranStudioProvider.notifier).updateVersesRange(1, end);
                                  },
                                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                  side: BorderSide.none,
                                ),
                                ActionChip(
                                  label: Text('All (${surah.numberOfAyahs})', style: const TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    ref.read(quranStudioProvider.notifier).updateVersesRange(1, surah.numberOfAyahs);
                                  },
                                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                  side: BorderSide.none,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                      ),
                    ),
                  ),
                  
                  // Verses Preview (Real text)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 140),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final currentVerse = startAyah + index;
                          final textIndex = currentVerse - 1;

                          final arabicText = (state.selectedSurahText != null && textIndex < state.selectedSurahText!.length)
                              ? state.selectedSurahText![textIndex]
                              : 'Loading...';
                          
                          final transText = (state.selectedSurahTranslation != null && textIndex < state.selectedSurahTranslation!.length)
                              ? state.selectedSurahTranslation![textIndex]
                              : 'Fetching translation...';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(16),
                                border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Number Badge (Using generic asset)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage('assets/icon_no.png'),
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 10)],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$currentVerse',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          arabicText, 
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontFamily: 'serif',
                                            fontSize: 24,
                                            height: 2.0,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          transText,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            height: 1.5,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: totalSelected,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom CTA
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
                    border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalSelected Ayahs Selected', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                color: isWarning ? theme.colorScheme.error : null,
                              )
                            ),
                            Text('Preparing timeline sequence', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/select-reciter');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                        child: const Text('Continue to Options', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        }
      ),
    );
  }
}
