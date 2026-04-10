import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/quran_models.dart';

class QuranStudioState {
  // Metadata Data
  final List<Surah> surahs;
  final List<Edition> audioEditions;
  final List<Edition> translationEditions;

  // Selected State
  final Surah? selectedSurah;
  final int startAyah;
  final int endAyah;
  final Edition? selectedAudio;
  final Edition? selectedTranslation;
  final bool includePhonetic;
  
  // Preview Text Cache
  final List<String>? selectedSurahText;
  final List<String>? selectedSurahTranslation;
  
  // UI State
  final int currentStep;
  final bool isGenerating;

  QuranStudioState({
    this.surahs = const [],
    this.audioEditions = const [],
    this.translationEditions = const [],
    this.selectedSurah,
    this.startAyah = 1,
    this.endAyah = 10,
    this.selectedAudio,
    this.selectedTranslation,
    this.includePhonetic = true,
    this.selectedSurahText,
    this.selectedSurahTranslation,
    this.currentStep = 1,
    this.isGenerating = false,
  });

  QuranStudioState copyWith({
    List<Surah>? surahs,
    List<Edition>? audioEditions,
    List<Edition>? translationEditions,
    Surah? selectedSurah,
    int? startAyah,
    int? endAyah,
    Edition? selectedAudio,
    Edition? selectedTranslation,
    bool? includePhonetic,
    List<String>? selectedSurahText,
    List<String>? selectedSurahTranslation,
    int? currentStep,
    bool? isGenerating,
  }) {
    return QuranStudioState(
      surahs: surahs ?? this.surahs,
      audioEditions: audioEditions ?? this.audioEditions,
      translationEditions: translationEditions ?? this.translationEditions,
      selectedSurah: selectedSurah ?? this.selectedSurah,
      startAyah: startAyah ?? this.startAyah,
      endAyah: endAyah ?? this.endAyah,
      selectedAudio: selectedAudio ?? this.selectedAudio,
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      includePhonetic: includePhonetic ?? this.includePhonetic,
      selectedSurahText: selectedSurahText ?? this.selectedSurahText,
      selectedSurahTranslation: selectedSurahTranslation ?? this.selectedSurahTranslation,
      currentStep: currentStep ?? this.currentStep,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class QuranStudioNotifier extends AsyncNotifier<QuranStudioState> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.alquran.cloud/v1'));

  @override
  Future<QuranStudioState> build() async {
    return _fetchMetadata();
  }

  Future<QuranStudioState> _fetchMetadata() async {
    try {
      final responses = await Future.wait([
        _dio.get('/surah'),
        _dio.get('/edition/format/audio'),
        _dio.get('/edition/format/text'),
      ]);

      final surahsData = responses[0].data['data'] as List;
      final audioData = responses[1].data['data'] as List;
      final textData = responses[2].data['data'] as List;

      final surahs = surahsData.map((s) => Surah.fromJson(s)).toList();
      final audioEditions = audioData.map((e) => Edition.fromJson(e)).toList();
      
      // Filter texts for translations only, maybe exclude transliteration except for the default one
      final translationEditions = textData
          .map((e) => Edition.fromJson(e))
          .where((e) => e.type == 'translation')
          .toList();
          
      return QuranStudioState(
        surahs: surahs,
        audioEditions: audioEditions,
        translationEditions: translationEditions,
        // Default translations setup can be done here if needed
      );
    } catch (e) {
      throw Exception('Failed to load Quran metadata: $e');
    }
  }

  void selectSurah(Surah surah) {
    if (state.value == null) return;
    
    // Auto-calculate default range (1 to min(10, numberOfAyahs))
    final end = surah.numberOfAyahs > 10 ? 10 : surah.numberOfAyahs;
    
    state = AsyncData(state.value!.copyWith(
      selectedSurah: surah,
      startAyah: 1,
      endAyah: end,
      currentStep: 2, // Move to step 2 automatically
      selectedSurahText: null, // Clear previous cache
      selectedSurahTranslation: null,
    ));

    _fetchSurahText(surah.number);
  }

  Future<void> _fetchSurahText(int surahNumber) async {
    try {
      final response = await _dio.get('/surah/$surahNumber/editions/quran-uthmani,en.asad');
      final dataList = response.data['data'] as List<dynamic>;
      final arabicData = dataList.firstWhere((e) => e['edition']['identifier'] == 'quran-uthmani')['ayahs'] as List<dynamic>;
      final transData = dataList.firstWhere((e) => e['edition']['identifier'] == 'en.asad')['ayahs'] as List<dynamic>;
      
      if (state.value != null && state.value!.selectedSurah?.number == surahNumber) {
        state = AsyncData(state.value!.copyWith(
          selectedSurahText: arabicData.map((a) => a['text'] as String).toList(),
          selectedSurahTranslation: transData.map((a) => a['text'] as String).toList(),
        ));
      }
    } catch (e) {
      // Ignore preview fetch errors silently
    }
  }

  void updateVersesRange(int start, int end) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(
      startAyah: start,
      endAyah: end,
    ));
  }

  void setIncludePhonetic(bool value) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(includePhonetic: value));
  }

  void selectTranslation(Edition translation) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(selectedTranslation: translation));
  }

  void selectAudio(Edition audio) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(selectedAudio: audio));
  }

  void nextStep() {
    if (state.value == null) return;
    if (state.value!.currentStep < 4) {
      state = AsyncData(state.value!.copyWith(currentStep: state.value!.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.value == null) return;
    if (state.value!.currentStep > 1) {
      state = AsyncData(state.value!.copyWith(currentStep: state.value!.currentStep - 1));
    }
  }

  void setGenerating(bool generating) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(isGenerating: generating));
  }
}

final quranStudioProvider = AsyncNotifierProvider<QuranStudioNotifier, QuranStudioState>(() {
  return QuranStudioNotifier();
});
