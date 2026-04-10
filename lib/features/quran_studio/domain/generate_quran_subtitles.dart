import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/quran_models.dart';

class QuranSubtitleGenerator {
  final Dio _dio = Dio();
  // Don't reuse AudioPlayer across files — create per-file to get accurate duration

  Future<List<TimelineClip>> generateQuranSubtitles({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
    required String audioIdentifier,
    String? translationIdentifier,
    bool includePhonetic = false,
  }) async {
    // 1. Build the comma-separated editions string
    final editionsList = [
      'quran-uthmani', 
      audioIdentifier,
      ?translationIdentifier,
      if (includePhonetic) 'en.transliteration',
    ];
    final editionsString = editionsList.join(',');

    // 2. Fetch the data from Alquran Cloud
    final url = 'https://api.alquran.cloud/v1/surah/$surahNumber/editions/$editionsString';
    final response = await _dio.get(url);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Quran data from Alquran Cloud');
    }

    final dataList = response.data['data'] as List<dynamic>;
    
    // Find the respective editions from the response array
    final arabicData = dataList.firstWhere((e) => e['edition']['identifier'] == 'quran-uthmani')['ayahs'] as List<dynamic>;
    final audioData = dataList.firstWhere((e) => e['edition']['identifier'] == audioIdentifier)['ayahs'] as List<dynamic>;
    
    List<dynamic>? translationData;
    if (translationIdentifier != null) {
      translationData = dataList.firstWhere((e) => e['edition']['identifier'] == translationIdentifier, orElse: () => null)?['ayahs'] as List<dynamic>?;
    }
    
    List<dynamic>? transliterationData;
    if (includePhonetic) {
      transliterationData = dataList.firstWhere((e) => e['edition']['identifier'] == 'en.transliteration', orElse: () => null)?['ayahs'] as List<dynamic>?;
    }

    // 3. Slice the ayahs based on range (startAyah and endAyah are 1-indexed)
    // numberInSurah is also 1-indexed, so we subtract 1 for array index
    final startIndex = startAyah - 1;
    final endIndex = endAyah; // non-inclusive upper bound for sublist
    
    final slicedArabic = arabicData.sublist(startIndex, endIndex);
    final slicedAudio = audioData.sublist(startIndex, endIndex);
    final slicedTranslation = translationData?.sublist(startIndex, endIndex);
    final slicedTransliteration = transliterationData?.sublist(startIndex, endIndex);

    final tmpDir = await getTemporaryDirectory();
    final generatorId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseDir = Directory('${tmpDir.path}/quran_studio_$generatorId');
    await baseDir.create(recursive: true);

    List<TimelineClip> clips = [];
    double currentStartTime = 0.0;

    // 4. Iterate and download audio, extract durations
    for (int i = 0; i < slicedArabic.length; i++) {
      final ayahNumInSurah = slicedArabic[i]['numberInSurah'] as int;
      final rawArabicText = slicedArabic[i]['text'] as String;
      // Strip Basmallah from first ayah of non-Fatiha surahs — audio & translation don't include it
      final ayahArabicText = _stripBasmallah(rawArabicText, surahNumber, ayahNumInSurah);
      final audioUrl = slicedAudio[i]['audio'] as String?;
      final ayahTranslationText = slicedTranslation?[i]['text'] as String?;
      final ayahPhoneticText = slicedTransliteration?[i]['text'] as String?;

      if (audioUrl == null || audioUrl.isEmpty) {
        // Skip this ayah if no audio URL is available
        final fallbackDuration = 3.0;
        clips.add(TimelineClip(
          ayahNumber: ayahNumInSurah,
          arabic: ayahArabicText,
          translation: ayahTranslationText ?? '',
          phonetic: ayahPhoneticText,
          audioPath: '',
          duration: const Duration(seconds: 3),
          startTime: currentStartTime,
          wordTimings: _calculateWordTimings(ayahArabicText, currentStartTime, fallbackDuration),
        ));
        currentStartTime += fallbackDuration;
        continue;
      }

      // Download the MP3 file
      final fileName = 'surah_${surahNumber}_ayah_$ayahNumInSurah.mp3';
      final filePath = '${baseDir.path}/$fileName';

      try {
        await _dio.download(audioUrl, filePath);
        // Verify file was actually created
        if (!await File(filePath).exists()) {
          throw Exception('File not created: $filePath');
        }
      } catch (e) {
        // Fallback if download fails
        debugPrint('[QuranSubtitleGenerator] Failed to download audio for ayah $ayahNumInSurah: $e');
      }

      // Extract duration — create a fresh player per file to avoid state conflicts
      Duration? audioDuration;
      try {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Audio file does not exist: $filePath');
        }

        final tempPlayer = AudioPlayer();
        audioDuration = await tempPlayer.setFilePath(filePath);
        await tempPlayer.dispose();

        if (audioDuration == null || audioDuration.inMilliseconds <= 0) {
          throw Exception('Invalid duration for $filePath');
        }
      } catch (e) {
        debugPrint('[QuranSubtitleGenerator] Duration extraction failed for ayah $ayahNumInSurah: $e');
        audioDuration = const Duration(seconds: 3);
      }

      final durationSecs = audioDuration.inMilliseconds / 1000.0;

      // Calculate word-by-word timing by splitting ayah text into words
      // and distributing duration proportionally by character count
      final wordTimings = _calculateWordTimings(ayahArabicText, currentStartTime, durationSecs);

      // Construct TimelineClip
      clips.add(
        TimelineClip(
          ayahNumber: ayahNumInSurah,
          arabic: ayahArabicText,
          translation: ayahTranslationText ?? '',
          phonetic: ayahPhoneticText,
          audioPath: filePath,
          duration: audioDuration,
          startTime: currentStartTime,
          wordTimings: wordTimings,
        )
      );

      // Advance timeline
      currentStartTime += durationSecs;
    }

    return clips;
  }

  /// Calculate word-by-word timing by splitting Arabic text into words
  /// and distributing the ayah duration proportionally by character count.
  List<Map<String, dynamic>> _calculateWordTimings(
    String ayahText,
    double ayahStartTime,
    double ayahDuration,
  ) {
    final words = ayahText.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    if (words.isEmpty) return [];

    // Count total characters (including spaces for better distribution)
    final totalChars = ayahText.length;
    if (totalChars == 0) return [];

    double currentTime = ayahStartTime;
    final timings = <Map<String, dynamic>>[];

    for (final word in words) {
      // Distribute time proportionally by word length
      final wordDuration = (word.length / totalChars) * ayahDuration;
      final wordStart = currentTime;
      final wordEnd = wordStart + wordDuration;

      timings.add({
        'word': word,
        'start': wordStart,
        'end': wordEnd,
      });

      currentTime = wordEnd;
    }

    return timings;
  }

  /// Strips the Basmallah from the start of an ayah's Arabic text.
  ///
  /// The alquran.cloud API (quran-uthmani) prepends the Basmallah to the text
  /// of the first ayah of most surahs, but the audio files and translations
  /// do NOT include it — causing a sync mismatch.
  ///
  /// Rules:
  /// - Surah 1 (Al-Fatiha): Ayah 1 IS the Basmallah — never strip.
  /// - Surah 9 (At-Tawbah): Has no Basmallah — nothing to strip.
  /// - All other surahs: Strip from ayah 1 if present.
  static String _stripBasmallah(String text, int surahNumber, int ayahNumberInSurah) {
    // Only the first ayah of a surah can have the Basmallah prepended.
    if (ayahNumberInSurah != 1) return text;
    // Surah 1 = the Basmallah IS the verse. Surah 9 = no Basmallah.
    if (surahNumber == 1 || surahNumber == 9) return text;

    // Common Basmallah variants in alquran.cloud API responses
    const basmallahs = [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ',  // uthmani with tatweel + space
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',   // uthmani with tatweel no space
      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ ',     // standard with space
      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',      // standard no space
      'بسم الله الرحمن الرحيم ',                     // simplified with space
      'بسم الله الرحمن الرحيم',                      // simplified no space
    ];

    for (final basmallah in basmallahs) {
      if (text.startsWith(basmallah)) {
        final stripped = text.substring(basmallah.length).trimLeft();
        debugPrint('[QuranSubtitleGenerator] Stripped Basmallah from S$surahNumber:A1');
        return stripped;
      }
    }

    return text;
  }
}
