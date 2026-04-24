import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
import 'quran_com_api_service.dart';

/// Result of generating subtitles for one ayah.
class GeneratedAyahClip {
  final int ayahNumber;
  final String ayahKey; // e.g. "2:5"

  /// Full Arabic text (Uthmani) of the ayah.
  final String arabic;

  /// Translation text.
  final String translation;

  /// Transliteration / phonetic text.
  final String? phonetic;

  /// Path to the downloaded audio segment for this ayah.
  /// May be empty if download failed.
  final String audioPath;

  /// The start time of this ayah within the full chapter audio (in seconds).
  final double audioInPointSecs;

  /// Duration of this ayah's audio in seconds.
  final double durationSecs;

  /// Word-level timings in the format expected by [Layer.wordTimings].
  /// Each entry: {'word': String, 'start': double (s), 'end': double (s)}
  /// Times are ABSOLUTE (relative to 0 = start of this ayah's audio).
  final List<Map<String, dynamic>> wordTimings;

  const GeneratedAyahClip({
    required this.ayahNumber,
    required this.ayahKey,
    required this.arabic,
    required this.translation,
    this.phonetic,
    required this.audioPath,
    required this.audioInPointSecs,
    required this.durationSecs,
    required this.wordTimings,
  });
}

/// Generates real word-level subtitle clips for Quran ayahs using the
/// Quran.com CDN API, which provides actual recorded word timestamps
/// for each reciter (including repetitions, pauses, and style).
///
/// This replaces the old heuristic Tajweed-weight approximation with
/// true, per-reciter word timings.
class QuranSubtitleGeneratorV2 {
  final QuranComApiService _api = QuranComApiService();
  final Dio _dio = Dio();

  Future<List<GeneratedAyahClip>> generateSubtitles({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
    required QuranComReciter reciter,
    String? translationIdentifier,
    bool includePhonetic = false,
  }) async {
    if (endAyah - startAyah > 15) {
      throw Exception("Maximum 15 versets par génération.");
    }

    // ── 1. Fetch Arabic text + translation + phonetic ────────────────────────
    debugPrint('[SubtitleGenV2] Fetching texts for S$surahNumber:$startAyah-$endAyah');
    final texts = await _api.fetchSurahTexts(
      surahNumber: surahNumber,
      startAyah: startAyah,
      endAyah: endAyah,
      translationIdentifier: translationIdentifier,
      includePhonetic: includePhonetic,
    );

    final arabicTexts = texts['arabic'] ?? [];
    final translationTexts = texts['translation'] ?? [];
    final phoneticTexts = texts['phonetic'] ?? [];

    // ── 2. Fetch verse timings (real word timestamps) for this reciter ───────
    debugPrint('[SubtitleGenV2] Fetching verse timings for reciter ${reciter.id}');
    final verseTimings = await _api.fetchVerseTimings(reciter.id, surahNumber);

    // ── 3. Fetch chapter audio URL ───────────────────────────────────────────
    final chapterAudioUrl = await _api.fetchChapterAudioUrl(reciter.id, surahNumber);

    // ── 4. Download the full chapter audio ──────────────────────────────────
    final tmpDir = await getTemporaryDirectory();
    final generatorId = DateTime.now().millisecondsSinceEpoch.toString();
    final baseDir = Directory('${tmpDir.path}/quran_studio_$generatorId');
    await baseDir.create(recursive: true);

    String? chapterAudioPath;
    if (chapterAudioUrl != null) {
      final fileName = 'chapter_${surahNumber}_reciter_${reciter.id}.mp3';
      final filePath = '${baseDir.path}/$fileName';
      try {
        debugPrint('[SubtitleGenV2] Downloading chapter audio: $chapterAudioUrl');
        await _dio.download(chapterAudioUrl, filePath);
        if (await File(filePath).exists()) {
          chapterAudioPath = filePath;
        }
      } catch (e) {
        debugPrint('[SubtitleGenV2] Chapter audio download failed: $e');
      }
    }

    // ── 5. Build individual ayah clips ───────────────────────────────────────
    final List<GeneratedAyahClip> clips = [];
    double currentStartTime = 0.0;

    for (int i = 0; i < arabicTexts.length; i++) {
      final ayahIndex = i;
      final ayahNumInSurah = startAyah + i;
      final ayahKey = '$surahNumber:$ayahNumInSurah';

      // Strip Basmallah from first ayah of non-Fatiha surahs
      final rawArabic = arabicTexts[ayahIndex];
      final ayahArabic = _stripBasmallah(rawArabic, surahNumber, ayahNumInSurah);
      final ayahTranslation = i < translationTexts.length ? translationTexts[i] : '';
      final ayahPhonetic = i < phoneticTexts.length ? phoneticTexts[i] : null;

      // Look up real verse timing
      final timing = verseTimings[ayahKey];

      double ayahDurationSecs;
      List<Map<String, dynamic>> wordTimings;
      String audioPath = chapterAudioPath ?? '';

      if (timing != null) {
        // ── Real timestamps available ─────────────────────────────────────
        // Duration is the verse's own duration, not from chapter start.
        ayahDurationSecs = (timing.timestampTo - timing.timestampFrom) / 1000.0;
        
        // Ensure duration is always positive and reasonable
        if (ayahDurationSecs <= 0) {
           ayahDurationSecs = 5.0; // Fallback for invalid timestamps
        }

        // Convert word timings from absolute chapter-ms to
        // relative-to-ayah-start seconds (what the Layer engine expects).
        final ayahStartMs = timing.timestampFrom;
        final words = ayahArabic.split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

        wordTimings = _buildWordTimingsFromSegments(
          words: words,
          segments: timing.wordTimings,
          ayahStartMs: ayahStartMs,
          currentStartTime: 0.0, // Relative to the layer start!
        );
      } else {
        // ── Fallback: heuristic distribution (alquran.cloud audio) ───────
        debugPrint('[SubtitleGenV2] No real timing for $ayahKey — using heuristic fallback');
        ayahDurationSecs = 5.0; // safe default
        wordTimings = _heuristicWordTimings(ayahArabic, 0.0, ayahDurationSecs); // Relative to the layer start!
      }

      clips.add(GeneratedAyahClip(
        ayahNumber: ayahNumInSurah,
        ayahKey: ayahKey,
        arabic: ayahArabic,
        translation: ayahTranslation,
        phonetic: ayahPhonetic,
        audioPath: audioPath,
        audioInPointSecs: timing != null ? timing.timestampFrom / 1000.0 : currentStartTime,
        durationSecs: ayahDurationSecs,
        wordTimings: wordTimings,
      ));

      currentStartTime += ayahDurationSecs;
    }

    return clips;
  }

  // ---------------------------------------------------------------------------
  // Build word timings from real CDN segments
  // ---------------------------------------------------------------------------

  /// Converts the CDN segments (which are 1-indexed word positions + absolute
  /// ms from chapter start) into the Layer.wordTimings format expected by the
  /// rendering engine: absolute seconds from the timeline start.
  ///
  /// Handles:
  ///  - Out-of-order segments (the CDN may list word 3 before word 2).
  ///  - Repeated segments for the same word position (reciter repeats the word).
  ///  - Gaps between words (silence / breath).
  List<Map<String, dynamic>> _buildWordTimingsFromSegments({
    required List<String> words,
    required List<WordTiming> segments,
    required int ayahStartMs,
    required double currentStartTime,
  }) {
    if (words.isEmpty || segments.isEmpty) return [];

    // Group all segments by word position (1-indexed).
    // When a word is repeated, we take the FIRST occurrence — that is when
    // the word first appears and the text should highlight.
    final Map<int, WordTiming> firstOccurrence = {};
    for (final seg in segments) {
      if (!firstOccurrence.containsKey(seg.position)) {
        firstOccurrence[seg.position] = seg;
      }
    }

    final timings = <Map<String, dynamic>>[];

    for (int i = 0; i < words.length; i++) {
      final wordPos = i + 1; // 1-indexed
      final seg = firstOccurrence[wordPos];

      double startSec;
      double endSec;

      if (seg != null) {
        // Convert from absolute chapter-ms to absolute timeline seconds.
        startSec = currentStartTime + (seg.startMs - ayahStartMs) / 1000.0;
        endSec = currentStartTime + (seg.endMs - ayahStartMs) / 1000.0;
      } else {
        // Word not found in segments — interpolate between neighbors.
        // This can happen for punctuation words or end markers.
        final prev = timings.isNotEmpty ? (timings.last['end'] as double) : currentStartTime;
        final next = firstOccurrence[wordPos + 1];
        final nextSec = next != null
            ? currentStartTime + (next.startMs - ayahStartMs) / 1000.0
            : prev + 0.5;
        startSec = prev;
        endSec = nextSec;
      }

      timings.add({
        'word': words[i],
        'start': startSec.clamp(currentStartTime, double.infinity),
        'end': endSec.clamp(currentStartTime, double.infinity),
      });
    }

    return timings;
  }

  // ---------------------------------------------------------------------------
  // Heuristic fallback (Tajweed-based)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _heuristicWordTimings(
    String text,
    double startTime,
    double duration,
  ) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    final weights = words.map(_tajweedWeight).toList();
    final total = weights.fold(0.0, (a, b) => a + b);
    if (total <= 0) return [];

    double t = startTime;
    return words.asMap().entries.map((e) {
      final w = (weights[e.key] / total) * duration;
      final entry = {'word': e.value, 'start': t, 'end': t + w};
      t += w;
      return entry;
    }).toList();
  }

  double _tajweedWeight(String word) {
    double w = 0;
    for (final ch in word.characters) {
      if ('ًٌٍَُِْۡ'.contains(ch)) continue;
      if ('ۖۗۚۛۙۘ۩ۜ'.contains(ch)) { w += 4.0; continue; }
      if (ch == 'ٓ') { w += 3.5; continue; }
      if ('ٰآٱ'.contains(ch)) { w += 2.0; continue; }
      if (ch == 'ّ') { w += 1.5; continue; }
      if ('اويى'.contains(ch)) { w += 1.5; continue; }
      w += 1.0;
    }
    return w < 1.0 ? 1.0 : w;
  }

  // ---------------------------------------------------------------------------
  // Basmallah stripping
  // ---------------------------------------------------------------------------

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
    for (final b in basmallahs) {
      if (text.startsWith(b)) return text.substring(b.length).trimLeft();
    }
    return text;
  }
}
