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

  /// Calculate word-by-word timing dynamically.
  /// Uses a specialized Tajweed-aware heuristic to distribute ayah duration based on 
  /// Arabic reading rules (Madd, Shaddah, Waqf) rather than a naive character count.
  List<Map<String, dynamic>> _calculateWordTimings(
    String ayahText,
    double ayahStartTime,
    double ayahDuration,
  ) {
    final words = ayahText.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    if (words.isEmpty) return [];

    // Calculate the Tajweed-based temporal weight of each word
    final wordWeights = words.map((w) => _calculateWordWeight(w)).toList();
    final totalWeight = wordWeights.fold(0.0, (sum, w) => sum + w);

    if (totalWeight <= 0) return [];

    double currentTime = ayahStartTime;
    final timings = <Map<String, dynamic>>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final weight = wordWeights[i];
      
      // Distribute time proportionally by Tajweed weight
      final wordDuration = (weight / totalWeight) * ayahDuration;
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

  /// Advanced heuristic for Quranic word timing distribution.
  /// Calculates a weight for each word predicting its relative audio duration.
  double _calculateWordWeight(String word) {
    double weight = 0.0;
    
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      
      // Harakat (short vowels) and sukun do not take extra time relative to the consonant
      if (['َ', 'ُ', 'ِ', 'ْ', 'ً', 'ٌ', 'ٍ', 'ۡ'].contains(char)) continue;
      
      // Tajweed Stop/Pause Marks (Waqf) — the reciter physically pauses here
      if (['ۖ', 'ۗ', 'ۚ', 'ۛ', 'ۙ', 'ۘ', '۩', 'ۜ'].contains(char)) {
        weight += 4.0;
        continue;
      }
      
      // Maddah Lazim/Muttasil (elongation marker ~) implies 4-6 beats!
      if (char == 'ٓ') {
        weight += 3.5;
        continue;
      }
      
      // Dagger Alif or Alif Maddah (implies at least 2 beats Madd Tabi'i)
      if (['ٰ', 'آ', 'ٱ'].contains(char)) {
        weight += 2.0;
        continue;
      }
      
      // Shaddah (doubles the consonant articulation time)
      if (char == 'ّ') {
        weight += 1.5;
        continue;
      }
      
      // Heavy timing letters (often forms of Madd Tabi'i if unvoweled)
      if (['ا', 'و', 'ي', 'ى'].contains(char)) {
        weight += 1.5;
        continue;
      }

      // Base consonants
      weight += 1.0;
    }
    
    // Guarantee minimal weight even for tiny structural words (e.g. "بِ", "وَ")
    return weight < 1.0 ? 1.0 : weight;
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
    if (ayahNumberInSurah != 1) return text;
    if (surahNumber == 1 || surahNumber == 9) return text;

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 4) {
      final first4 = words.sublist(0, 4).join(' ');
      // Remove all diacritics and normalize Alif variants for a bulletproof check
      final normalized = first4
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED]'), '')
          .replaceAll('ٱ', 'ا')
          .replaceAll('ـ', ''); // Remove tatweel
          
      if (normalized == "بسم الله الرحمن الرحيم") {
        return words.sublist(4).join(' ');
      }
    }
    
    // Fallback for exact matches just in case
    const basmallahs = [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ',
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ ',
      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      'بسم الله الرحمن الرحيم ',
      'بسم الله الرحمن الرحيم',
    ];
    for (final basmallah in basmallahs) {
      if (text.startsWith(basmallah)) {
        final stripped = text.substring(basmallah.length).trimLeft();
        debugPrint('[QuranSubtitleGenerator] Stripped Basmallah (exact) from S$surahNumber:A1');
        return stripped;
      }
    }
    return text;
  }

  static String _normalizeArabicForPrefix(String value) {
    var out = value;
    // Remove tatweel + Arabic diacritics / small marks.
    out = out.replaceAll(RegExp(r'[\u0640\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    // Normalize common alif/hamza variants for stable comparisons.
    out = out
        .replaceAll('ٱ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا');
    return out.trimLeft().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _dropLeadingWordCount(String value, int wordCount) {
    int i = 0;
    int seen = 0;
    bool inWord = false;

    while (i < value.length) {
      final ch = value[i];
      final isSpace = RegExp(r'\s').hasMatch(ch);
      if (!isSpace && !inWord) {
        inWord = true;
        seen++;
      } else if (isSpace && inWord) {
        inWord = false;
        if (seen >= wordCount) {
          return value.substring(i).trimLeft();
        }
      }
      i++;
    }

    return seen >= wordCount ? '' : value;
  }
}
