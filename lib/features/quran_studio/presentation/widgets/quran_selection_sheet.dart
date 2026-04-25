import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:deen_studio_01/features/quran_studio/presentation/state/quran_studio_notifier.dart';
import 'package:deen_studio_01/features/quran_studio/domain/quran_subtitle_generator_v2.dart';
import 'package:deen_studio_01/features/editor/presentation/editor_state.dart';
import 'package:deen_studio_01/core/services/persistent_media_store.dart';
import 'package:deen_studio_01/models/project.dart';
import 'package:deen_studio_01/models/text_layer_style.dart';

class QuranSelectionSheet extends ConsumerStatefulWidget {
  const QuranSelectionSheet({super.key});

  @override
  ConsumerState<QuranSelectionSheet> createState() => _QuranSelectionSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => const QuranSelectionSheet(),
    );
  }
}

class _QuranSelectionSheetState extends ConsumerState<QuranSelectionSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isGenerating = false;
  String _generatingStatus = '';

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  Future<void> _generateAndAddToProject() async {
    final studioState = ref.read(quranStudioProvider).value;
    if (studioState == null ||
        studioState.selectedSurah == null ||
        studioState.selectedReciter == null) {
      return;
    }

    if (studioState.endAyah - studioState.startAyah > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'éditeur est optimisé pour 15 versets maximum.")),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatingStatus = 'Récupération des données du Coran...';
    });

    try {
      final generator = QuranSubtitleGeneratorV2();

      setState(() => _generatingStatus = 'Téléchargement de l\'audio de ${studioState.selectedReciter!.name}...');

      final clips = await generator.generateSubtitles(
        surahNumber: studioState.selectedSurah!.number,
        startAyah: studioState.startAyah,
        endAyah: studioState.endAyah,
        reciter: studioState.selectedReciter!,
        translationIdentifier: studioState.selectedTranslation?.identifier ?? 'fr.hamidullah',
        includePhonetic: studioState.includePhonetic,
      );

      setState(() => _generatingStatus = 'Persistance des médias...');

      List<Layer> newLayers = [];
      double currentStartTime = 0.0;

      // Calculate start time offset based on existing layers
      final proj = ref.read(editorProvider).currentProject;
      if (proj != null && proj.layers.isNotEmpty) {
        final lastClipEnd = proj.layers.fold(0.0, (max, l) {
          final end = l.startTime + l.duration;
          return end > max ? end : max;
        });
        currentStartTime = lastClipEnd;
      }

      // All clips share the same audio file (full chapter), so we only
      // persist it once. The layer startTime + duration handle segmentation.
      String? persistedAudioPath;
      if (clips.isNotEmpty && clips.first.audioPath.isNotEmpty) {
        try {
          persistedAudioPath = await PersistentMediaStore.persistFile(clips.first.audioPath);
        } catch (e) {
          debugPrint('[QuranSelectionSheet] Audio persist error: $e');
          persistedAudioPath = clips.first.audioPath;
        }
      }


      for (final clip in clips) {
        final ts = DateTime.now().millisecondsSinceEpoch;

        // Word timings from generator are already relative to the layer start (0.0).
        final rebasedWordTimings = clip.wordTimings.map((wt) {
          return {
            'word': wt['word'],
            'start': wt['start'],
            'end': wt['end'],
          };
        }).toList();

        // Audio layer — points to full chapter audio
        if (persistedAudioPath != null) {
          newLayers.add(Layer(
            id: 'audio_${clip.ayahNumber}_$ts',
            type: 'audio',
            content: persistedAudioPath,
            startTime: currentStartTime,
            inPoint: clip.audioInPointSecs,
            duration: clip.durationSecs,
            style: const {},
          ));
        }

        // Arabic text layer
        newLayers.add(Layer(
          id: 'arabic_${clip.ayahNumber}_$ts',
          type: 'arabic',
          content: clip.arabic,
          startTime: currentStartTime,
          duration: clip.durationSecs,
          style: const {},
          textStyle: const TextLayerStyle(fontFamily: 'UthmanicRegular', fontSize: 26, isRTL: true),
          transform: const ClipTransform(x: 0.5, y: 0.35),
          wordTimings: rebasedWordTimings,
        ));

        // Translation layer
        if (clip.translation.isNotEmpty) {
          newLayers.add(Layer(
            id: 'trans_${clip.ayahNumber}_$ts',
            type: 'translation',
            content: clip.translation,
            startTime: currentStartTime,
            duration: clip.durationSecs,
            style: const {},
            textStyle: const TextLayerStyle(fontSize: 14),
            transform: const ClipTransform(x: 0.5, y: 0.65),
          ));
        }

        // Phonetic layer
        if (studioState.includePhonetic && clip.phonetic?.isNotEmpty == true) {
          newLayers.add(Layer(
            id: 'phon_${clip.ayahNumber}_$ts',
            type: 'phonetic',
            content: clip.phonetic ?? '',
            startTime: currentStartTime,
            duration: clip.durationSecs,
            style: const {},
            textStyle: const TextLayerStyle(fontSize: 12),
            transform: const ClipTransform(x: 0.5, y: 0.85),
          ));
        }

        currentStartTime += clip.durationSecs;
      }

      for (final layer in newLayers) {
        ref.read(editorProvider.notifier).addLayer(layer);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _generatingStatus,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  IconButton(icon: const Icon(LucideIcons.arrowLeft, size: 20), onPressed: _prevPage)
                else
                  const SizedBox(width: 48),
                Text(
                  _currentPage == 0
                      ? 'Choisir une Sourate'
                      : _currentPage == 1
                          ? 'Quels versets ?'
                          : 'Choix du Récitateur',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Manrope'),
                ),
                IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSurahSelection(),
                _buildVersesSelection(),
                _buildReciterSelection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahSelection() {
    final quranStateAsync = ref.watch(quranStudioProvider);
    return quranStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (state) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.surahs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final surah = state.surahs[index];
            final isSelected = state.selectedSurah?.number == surah.number;
            return ListTile(
              onTap: () {
                ref.read(quranStudioProvider.notifier).selectSurah(surah);
                _nextPage();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              leading: CircleAvatar(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text('${surah.number}',
                    style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
              ),
              title: Text(surah.englishName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${surah.numberOfAyahs} Versets'),
              trailing: Text(surah.name,
                  style: TextStyle(fontFamily: 'serif', fontSize: 18, color: Theme.of(context).colorScheme.secondary)),
            );
          },
        );
      },
    );
  }

  Widget _buildVersesSelection() {
    final state = ref.watch(quranStudioProvider).value;
    if (state == null || state.selectedSurah == null) return const SizedBox.shrink();
    final surah = state.selectedSurah!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(surah.name,
                    style: TextStyle(fontFamily: 'serif', fontSize: 32, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Text(surah.englishNameTranslation.toUpperCase(),
                    style: const TextStyle(fontSize: 12, letterSpacing: 2.0)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Plage de Versets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          RangeSlider(
            min: 1.0,
            max: surah.numberOfAyahs.toDouble(),
            values: RangeValues(state.startAyah.toDouble(), state.endAyah.toDouble()),
            divisions: surah.numberOfAyahs > 1 ? surah.numberOfAyahs - 1 : 1,
            labels: RangeLabels('${state.startAyah}', '${state.endAyah}'),
            onChanged: (RangeValues values) {
              ref.read(quranStudioProvider.notifier).updateVersesRange(
                    values.start.round(),
                    values.end.round(),
                  );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${state.endAyah - state.startAyah + 1} Versets sélectionnés',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          // Include phonetic toggle
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Inclure la phonétique'),
            subtitle: const Text('Translittération latine du texte arabe'),
            value: state.includePhonetic,
            onChanged: (v) => ref.read(quranStudioProvider.notifier).setIncludePhonetic(v),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('SUIVANT'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReciterSelection() {
    final quranStateAsync = ref.watch(quranStudioProvider);
    return quranStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (state) {
        return Column(
          children: [
            // Info banner about real timestamps
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.zap, color: Theme.of(context).colorScheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Synchronisation mot-par-mot réelle — timestamps enregistrés pour chaque récitateur',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.reciters.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final reciter = state.reciters[index];
                  final isSelected = state.selectedReciter?.id == reciter.id;
                  return ListTile(
                    onTap: () => ref.read(quranStudioProvider.notifier).selectReciter(reciter),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      ),
                    ),
                    tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    title: Text(reciter.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${reciter.style} • ${reciter.qirat}'),
                    trailing: isSelected
                        ? Icon(LucideIcons.checkCircle2, color: Theme.of(context).colorScheme.primary)
                        : null,
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton.icon(
                  onPressed: state.selectedReciter == null ? null : _generateAndAddToProject,
                  icon: const Icon(LucideIcons.wand2),
                  label: const Text('GÉNÉRER MNT'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(60),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
