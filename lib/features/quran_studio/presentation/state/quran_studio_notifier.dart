import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quran_models.dart';
import '../../domain/quran_com_api_service.dart';
import 'package:dio/dio.dart';

class QuranStudioState {
  // Metadata Data
  final List<Surah> surahs;
  /// Reciters from Quran.com — have real word-level timestamps.
  final List<QuranComReciter> reciters;

  // Legacy (alquran.cloud) text editions used for translations
  final List<Edition> translationEditions;

  // Selected State
  final Surah? selectedSurah;
  final int startAyah;
  final int endAyah;
  final QuranComReciter? selectedReciter;
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
    this.reciters = const [],
    this.translationEditions = const [],
    this.selectedSurah,
    this.startAyah = 1,
    this.endAyah = 10,
    this.selectedReciter,
    this.selectedTranslation,
    this.includePhonetic = true,
    this.selectedSurahText,
    this.selectedSurahTranslation,
    this.currentStep = 1,
    this.isGenerating = false,
  });

  QuranStudioState copyWith({
    List<Surah>? surahs,
    List<QuranComReciter>? reciters,
    List<Edition>? translationEditions,
    Surah? selectedSurah,
    int? startAyah,
    int? endAyah,
    QuranComReciter? selectedReciter,
    Edition? selectedTranslation,
    bool? includePhonetic,
    List<String>? selectedSurahText,
    List<String>? selectedSurahTranslation,
    int? currentStep,
    bool? isGenerating,
  }) {
    return QuranStudioState(
      surahs: surahs ?? this.surahs,
      reciters: reciters ?? this.reciters,
      translationEditions: translationEditions ?? this.translationEditions,
      selectedSurah: selectedSurah ?? this.selectedSurah,
      startAyah: startAyah ?? this.startAyah,
      endAyah: endAyah ?? this.endAyah,
      selectedReciter: selectedReciter ?? this.selectedReciter,
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
  final Dio _alquranDio = Dio(BaseOptions(baseUrl: 'https://api.alquran.cloud/v1'));
  final QuranComApiService _quranComApi = QuranComApiService();

  @override
  Future<QuranStudioState> build() async {
    return _fetchMetadata();
  }

  Future<QuranStudioState> _fetchMetadata() async {
    try {
      // Fetch surahs from alquran.cloud + reciters from Quran.com in parallel
      final responses = await Future.wait([
        _alquranDio.get('/surah'),
        _alquranDio.get('/edition/format/text'),
        _quranComApi.fetchReciters(),
      ]);

      final surahsData = (responses[0] as Response).data['data'] as List;
      final textData = (responses[1] as Response).data['data'] as List;
      final reciters = responses[2] as List<QuranComReciter>;

      final surahs = surahsData.map((s) => Surah.fromJson(s)).toList();
      final translationEditions = textData
          .map((e) => Edition.fromJson(e))
          .where((e) => e.type == 'translation')
          .toList();

      return QuranStudioState(
        surahs: surahs,
        reciters: reciters,
        translationEditions: translationEditions,
        // Default: Mishary Rashid
        selectedReciter: reciters.firstWhere(
          (r) => r.id == 7,
          orElse: () => reciters.isNotEmpty ? reciters.first : const QuranComReciter(id: 7, name: "Mishari Rashid al-'Afasy", style: 'Murattal', qirat: 'Hafs'),
        ),
      );
    } catch (e) {
      throw Exception('Failed to load Quran metadata: $e');
    }
  }

  void selectSurah(Surah surah) {
    if (state.value == null) return;
    final end = surah.numberOfAyahs > 10 ? 10 : surah.numberOfAyahs;
    state = AsyncData(state.value!.copyWith(
      selectedSurah: surah,
      startAyah: 1,
      endAyah: end,
      currentStep: 2,
      selectedSurahText: null,
      selectedSurahTranslation: null,
    ));
    _fetchSurahText(surah.number);
  }

  Future<void> _fetchSurahText(int surahNumber) async {
    try {
      final response = await _alquranDio.get('/surah/$surahNumber/editions/quran-uthmani,en.asad');
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
    state = AsyncData(state.value!.copyWith(startAyah: start, endAyah: end));
  }

  void setIncludePhonetic(bool value) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(includePhonetic: value));
  }

  void selectTranslation(Edition translation) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(selectedTranslation: translation));
  }

  void selectReciter(QuranComReciter reciter) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(selectedReciter: reciter));
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
