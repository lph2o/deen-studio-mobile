import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deen_studio_01/core/services/persistent_media_store.dart';
import '../../auth/presentation/auth_state.dart';
import '../../quran_studio/domain/quran_com_api_service.dart';
import '../../quran_studio/domain/quran_subtitle_generator_v2.dart';
import '../../quran_studio/presentation/state/quran_studio_notifier.dart';

class SelectReciterScreen extends ConsumerStatefulWidget {
  const SelectReciterScreen({super.key});

  @override
  ConsumerState<SelectReciterScreen> createState() => _SelectReciterScreenState();
}

class _SelectReciterScreenState extends ConsumerState<SelectReciterScreen> {
  bool _isCreatingProject = false;

  Future<void> _createProject() async {
    final state = ref.read(quranStudioProvider).value;
    if (state == null || state.selectedReciter == null) return;

    setState(() => _isCreatingProject = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      if (userId == null) throw Exception('User not authenticated');

      final surah = state.selectedSurah;
      if (surah == null) throw Exception('No Surah selected');

      // ── Generate subtitles with real word timestamps ────────────────────
      final generator = QuranSubtitleGeneratorV2();
      final clips = await generator.generateSubtitles(
        surahNumber: surah.number,
        startAyah: state.startAyah,
        endAyah: state.endAyah,
        reciter: state.selectedReciter!,
        translationIdentifier: state.selectedTranslation?.identifier ?? 'fr.hamidullah',
        includePhonetic: state.includePhonetic,
      );

      // ── Build layer data for Supabase ───────────────────────────────────
      List<Map<String, dynamic>> layersData = [];
      String? persistedAudioPath;

      // All clips share one chapter audio file — persist it once.
      if (clips.isNotEmpty && clips.first.audioPath.isNotEmpty) {
        try {
          persistedAudioPath = await PersistentMediaStore.persistFile(clips.first.audioPath);
        } catch (e) {
          debugPrint('[SelectReciter] Failed to persist audio: $e');
          persistedAudioPath = clips.first.audioPath;
        }
      }

      double currentStartTime = 0.0;
      for (final clip in clips) {
        final ts = clip.ayahNumber;

        // Word timings from generator are already relative to the start of the entire sequence (0.0).
        // So they are already absolute timeline timestamps. No need to add currentStartTime.
        final rebasedWordTimings = clip.wordTimings.map((wt) => {
          'word': wt['word'],
          'start': wt['start'],
          'end': wt['end'],
        }).toList();

        if (persistedAudioPath != null) {
          layersData.add({
            'id': 'audio_$ts',
            'type': 'audio',
            'content': persistedAudioPath,
            'startTime': currentStartTime,
            'inPoint': clip.audioInPointSecs,
            'duration': clip.durationSecs,
            'style': {},
          });
        }

        layersData.add({
          'id': 'arabic_$ts',
          'type': 'arabic',
          'content': clip.arabic,
          'startTime': currentStartTime,
          'duration': clip.durationSecs,
          'style': {},
          'textStyle': {'fontFamily': 'UthmanicRegular', 'fontSize': 26, 'isRTL': true},
          'transform': {'x': 0.5, 'y': 0.35},
          'wordTimings': rebasedWordTimings,
        });

        if (clip.translation.isNotEmpty) {
          layersData.add({
            'id': 'translation_$ts',
            'type': 'translation',
            'content': clip.translation,
            'startTime': currentStartTime,
            'duration': clip.durationSecs,
            'style': {},
            'textStyle': {'fontSize': 14},
            'transform': {'x': 0.5, 'y': 0.65},
          });
        }

        if (state.includePhonetic && clip.phonetic?.isNotEmpty == true) {
          layersData.add({
            'id': 'phonetic_$ts',
            'type': 'phonetic',
            'content': clip.phonetic ?? '',
            'startTime': currentStartTime,
            'duration': clip.durationSecs,
            'style': {},
            'textStyle': {'fontSize': 12, 'isItalic': true},
            'transform': {'x': 0.5, 'y': 0.85},
          });
        }

        currentStartTime += clip.durationSecs;
      }

      final title = '${surah.englishName} Versets ${state.startAyah}-${state.endAyah}';

      final response = await Supabase.instance.client
          .from('projects')
          .insert({
            'user_id': userId,
            'title': title,
            'surah_id': surah.number,
            'ayah_range': {'start': state.startAyah, 'end': state.endAyah},
            'reciter_id': '${state.selectedReciter!.id}',
            'layers': layersData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      if (!mounted) return;
      context.go('/editor/${response['id']}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreatingProject = false);
    }
  }

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
      ),
      body: quranStateAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (quranState) {
          final reciters = quranState.reciters;
          final selectedReciterId = quranState.selectedReciter?.id;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(top: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VOICE OF THE SANCTUARY',
                            style: TextStyle(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Manrope',
                                color: theme.colorScheme.onSurface,
                                height: 1.2,
                              ),
                              children: [
                                const TextSpan(text: 'Select Your\n'),
                                TextSpan(
                                  text: 'Master Reciter',
                                  style: TextStyle(color: theme.colorScheme.secondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Choose the soul that will guide your creation. Each voice carries the weight of centuries of tradition.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Translation Settings
                          Text(
                            'TRANSLATION SETTINGS',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: quranState.selectedTranslation?.identifier,
                              hint: const Text('Select a Translation'),
                              dropdownColor: theme.colorScheme.surfaceContainerHigh,
                              underline: const SizedBox(),
                              items: quranState.translationEditions.map((t) {
                                return DropdownMenuItem(
                                  value: t.identifier,
                                  child: Text('${t.language.toUpperCase()} - ${t.englishName}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                final translation = quranState.translationEditions.firstWhere((t) => t.identifier == val);
                                ref.read(quranStudioProvider.notifier).selectTranslation(translation);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Include Phonetics', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Adds a transliteration layer for easy reading.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                            value: quranState.includePhonetic,
                            activeThumbColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              ref.read(quranStudioProvider.notifier).setIncludePhonetic(val);
                            },
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reciter = reciters[index];
                          final isSelected = selectedReciterId == reciter.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () => ref.read(quranStudioProvider.notifier).selectReciter(reciter),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.colorScheme.surfaceContainerHigh : theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected 
                                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                                  ),
                                  boxShadow: isSelected 
                                      ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 20)]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            reciter.name.substring(0, 1),
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            bottom: -4,
                                            right: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.check, size: 12, color: theme.colorScheme.onPrimary),
                                            ),
                                          )
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reciter.name,
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${reciter.style} • ${reciter.qirat}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.play, size: 16),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: reciters.length,
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom CTA
              if (selectedReciterId != null)
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: 1.0,
                    child: InkWell(
                      onTap: _isCreatingProject ? null : _createProject,
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
                            if (_isCreatingProject)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            Text(
                              _isCreatingProject ? 'Generating audio clips…' : 'Create Project',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
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
