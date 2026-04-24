import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A reciter as returned by the Quran.com CDN API.
class QuranComReciter {
  final int id;
  final String name;
  final String style;
  final String qirat;

  const QuranComReciter({
    required this.id,
    required this.name,
    required this.style,
    required this.qirat,
  });

  factory QuranComReciter.fromJson(Map<String, dynamic> json) {
    return QuranComReciter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      style: (json['style'] as Map<String, dynamic>?)?['name'] as String? ?? 'Murattal',
      qirat: (json['qirat'] as Map<String, dynamic>?)?['name'] as String? ?? 'Hafs',
    );
  }

  String get displayName {
    if (style == 'Murattal') return name;
    return '$name ($style)';
  }
}

/// Word-level timing for one word in a verse.
class WordTiming {
  /// 1-indexed position of the word in the verse.
  final int position;
  /// Start time in milliseconds from the beginning of the audio file.
  final int startMs;
  /// End time in milliseconds.
  final int endMs;

  const WordTiming({
    required this.position,
    required this.startMs,
    required this.endMs,
  });
}

/// Real timing data for a single verse, sourced from Quran.com.
class VerseTiming {
  final String verseKey;
  final int timestampFrom; // ms from start of chapter audio
  final int timestampTo;   // ms
  final int duration;      // ms
  /// Actual word-level segments: [word_position, start_ms, end_ms]
  /// Some entries may be repetitions (same position repeated).
  final List<WordTiming> wordTimings;

  const VerseTiming({
    required this.verseKey,
    required this.timestampFrom,
    required this.timestampTo,
    required this.duration,
    required this.wordTimings,
  });
}

/// Service to fetch per-reciter audio and real word-level timestamps
/// from the Quran.com / QuranCDN API.
class QuranComApiService {
  static const _cdnBase = 'https://api.qurancdn.com/api/qdc';
  static const _audioBase = 'https://download.quranicaudio.com';

  static const _alquranBase = 'https://api.alquran.cloud/v1';

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  // ---------------------------------------------------------------------------
  // Reciters
  // ---------------------------------------------------------------------------

  /// Fetches all available reciters from Quran.com CDN.
  Future<List<QuranComReciter>> fetchReciters() async {
    try {
      final resp = await _dio.get('$_cdnBase/audio/reciters');
      final list = resp.data['reciters'] as List<dynamic>;
      return list.map((e) => QuranComReciter.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[QuranComAPI] fetchReciters error: $e');
      return _hardcodedReciters;
    }
  }

  // ---------------------------------------------------------------------------
  // Chapter audio URL (full-chapter MP3)
  // ---------------------------------------------------------------------------

  /// Returns the CDN audio URL for a full chapter for the given reciter.
  Future<String?> fetchChapterAudioUrl(int reciterId, int chapterNumber) async {
    try {
      final resp = await _dio.get(
        '$_cdnBase/audio/reciters/$reciterId/audio_files',
        queryParameters: {'chapter_number': chapterNumber, 'segments': true},
      );
      final files = resp.data['audio_files'] as List<dynamic>;
      if (files.isEmpty) return null;
      return files.first['audio_url'] as String?;
    } catch (e) {
      debugPrint('[QuranComAPI] fetchChapterAudioUrl error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Verse timings with REAL word-level segments
  // ---------------------------------------------------------------------------

  /// Fetches the real verse timings (with word-level segments) for an entire
  /// chapter for the given reciter.
  ///
  /// Returns a map keyed by verse_key (e.g. "2:1") → [VerseTiming].
  Future<Map<String, VerseTiming>> fetchVerseTimings(
    int reciterId,
    int chapterNumber,
  ) async {
    try {
      final resp = await _dio.get(
        '$_cdnBase/audio/reciters/$reciterId/audio_files',
        queryParameters: {'chapter_number': chapterNumber, 'segments': true},
      );

      final files = resp.data['audio_files'] as List<dynamic>;
      if (files.isEmpty) return {};

      final file = files.first as Map<String, dynamic>;
      final rawTimings = file['verse_timings'] as List<dynamic>?;
      if (rawTimings == null) return {};

      final Map<String, VerseTiming> result = {};
      for (final raw in rawTimings) {
        final verseKey = raw['verse_key'] as String;
        final tsFrom = (raw['timestamp_from'] as num).toInt();
        final tsTo = (raw['timestamp_to'] as num).toInt();
        final dur = (raw['duration'] as num).toInt();
        final rawSegs = raw['segments'] as List<dynamic>? ?? [];

        // Parse segments: each is [word_position, start_ms, end_ms]
        // Some segments may only have [word_position] (repetition markers with no time).
        final wordTimings = <WordTiming>[];
        for (final seg in rawSegs) {
          final list = seg as List<dynamic>;
          if (list.length < 3) continue; // repetition marker without timestamp — skip
          final pos = (list[0] as num).toInt();
          final start = (list[1] as num).toInt();
          final end = (list[2] as num).toInt();
          wordTimings.add(WordTiming(position: pos, startMs: start, endMs: end));
        }

        result[verseKey] = VerseTiming(
          verseKey: verseKey,
          timestampFrom: tsFrom,
          timestampTo: tsTo,
          duration: dur,
          wordTimings: wordTimings,
        );
      }
      return result;
    } catch (e) {
      debugPrint('[QuranComAPI] fetchVerseTimings error: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Arabic text (uthmani) from alquran.cloud
  // ---------------------------------------------------------------------------

  /// Fetches the full Arabic text (Uthmani) for a surah from alquran.cloud,
  /// along with translation and optional transliteration.
  Future<Map<String, List<String>>> fetchSurahTexts({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
    String? translationIdentifier,
    bool includePhonetic = false,
  }) async {
    try {
      final editionsList = [
        'quran-uthmani',
        if (translationIdentifier != null) translationIdentifier,
        if (includePhonetic) 'en.transliteration',
      ];
      final editionsString = editionsList.join(',');
      final url = '$_alquranBase/surah/$surahNumber/editions/$editionsString';
      final response = await _dio.get(url);

      final dataList = response.data['data'] as List<dynamic>;
      final arabicData = dataList
          .firstWhere((e) => e['edition']['identifier'] == 'quran-uthmani')['ayahs'] as List<dynamic>;

      final startIndex = startAyah - 1;
      final endIndex = endAyah;

      final arabic = arabicData
          .sublist(startIndex, endIndex)
          .map((a) => a['text'] as String)
          .toList();

      String? translationId = translationIdentifier;
      List<String>? translation;
      if (translationId != null) {
        try {
          final transData = dataList
              .firstWhere((e) => e['edition']['identifier'] == translationId)['ayahs'] as List<dynamic>;
          translation = transData
              .sublist(startIndex, endIndex)
              .map((a) => a['text'] as String)
              .toList();
        } catch (_) {}
      }

      List<String>? phonetic;
      if (includePhonetic) {
        try {
          final phonData = dataList
              .firstWhere((e) => e['edition']['identifier'] == 'en.transliteration')['ayahs'] as List<dynamic>;
          phonetic = phonData
              .sublist(startIndex, endIndex)
              .map((a) => a['text'] as String)
              .toList();
        } catch (_) {}
      }

      return {
        'arabic': arabic,
        if (translation != null) 'translation': translation,
        if (phonetic != null) 'phonetic': phonetic,
      };
    } catch (e) {
      debugPrint('[QuranComAPI] fetchSurahTexts error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Hardcoded fallback reciters
  // ---------------------------------------------------------------------------

  static const List<QuranComReciter> _hardcodedReciters = [
    QuranComReciter(id: 7, name: "Mishari Rashid al-'Afasy", style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 2, name: 'AbdulBaset AbdulSamad', style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 1, name: 'AbdulBaset AbdulSamad', style: 'Mujawwad', qirat: 'Hafs'),
    QuranComReciter(id: 3, name: 'Abdur-Rahman as-Sudais', style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 4, name: 'Abu Bakr al-Shatri', style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 5, name: 'Hani ar-Rifai', style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 6, name: 'Mahmoud Khalil Al-Husary', style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 10, name: "Sa'ud ash-Shuraim", style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 9, name: 'Mohamed Siddiq al-Minshawi', style: 'Murattal', qirat: 'Hafs'),
    QuranComReciter(id: 97, name: 'Yasser Ad Dussary', style: 'Murattal', qirat: 'Hafs'),
  ];
}
