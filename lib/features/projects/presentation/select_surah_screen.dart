import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../quran_studio/presentation/state/quran_studio_notifier.dart';


class SelectSurahScreen extends ConsumerStatefulWidget {
  const SelectSurahScreen({super.key});

  @override
  ConsumerState<SelectSurahScreen> createState() => _SelectSurahScreenState();
}

class _SelectSurahScreenState extends ConsumerState<SelectSurahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _continueToVerses() {
    final stateInfo = ref.read(quranStudioProvider).value;
    if (stateInfo?.selectedSurah == null) return;
    context.push('/select-verses');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quranStateAsync = ref.watch(quranStudioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deen Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: quranStateAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.wifiOff, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load Quran data', style: theme.textTheme.titleMedium),
              Text(err.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(quranStudioProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (quranState) {
          final surahs = quranState.surahs;
          final selectedSurah = quranState.selectedSurah;

          // Filter logic
          final filteredSurahs = surahs.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.englishName.toLowerCase().contains(query) ||
                   s.name.contains(query) ||
                   s.number.toString().contains(query);
          }).toList();

          return Stack(
            children: [
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.displayLarge?.copyWith(
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                ),
                                children: [
                                  const TextSpan(text: 'Select a '),
                                  TextSpan(
                                    text: 'Surah\n',
                                    style: TextStyle(color: theme.colorScheme.primary),
                                  ),
                                  const TextSpan(text: 'to Begin Your Project'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Choose from the 114 chapters of the Holy Quran. Your selection will initialize the studio with the full text and audio tracks.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search by name or number...',
                                prefixIcon: Icon(LucideIcons.search, color: theme.colorScheme.outline),
                                suffixIcon: _searchQuery.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Grid of Surahs
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120), // Extra bottom padding for FAB
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 140,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final surah = filteredSurahs[index];
                            final isSelected = selectedSurah?.number == surah.number;

                            return _SurahCard(
                              id: surah.number,
                              name: surah.englishName,
                              translation: surah.englishNameTranslation,
                              arabic: surah.name,
                              ayahCount: surah.numberOfAyahs,
                              isSelected: isSelected,
                              onTap: () {
                                ref.read(quranStudioProvider.notifier).selectSurah(surah);
                              },
                            );
                          },
                          childCount: filteredSurahs.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // FAB / Continue Button
              if (selectedSurah != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 40,
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: InkWell(
                      onTap: _continueToVerses,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to Verses',
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
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final int id;
  final String name;
  final String translation;
  final String arabic;
  final int ayahCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _SurahCard({
    required this.id,
    required this.name,
    required this.translation,
    required this.arabic,
    required this.ayahCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    
    // Removing string "Surah " prefix internally if name is already fully localized
    final displayArabicText = arabic.replaceAll('سُورَةُ ', '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 0)]
            : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Number Badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$id',
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              translation.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                overflow: TextOverflow.ellipsis,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$ayahCount AYAHS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        displayArabicText,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          color: theme.colorScheme.secondary,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

