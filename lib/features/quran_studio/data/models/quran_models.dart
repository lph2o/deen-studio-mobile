class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      revelationType: json['revelationType'] ?? '',
    );
  }
}

class Edition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format; // 'audio', 'text'
  final String type;   // 'translation', 'quran', 'transliteration', 'versebyverse'
  
  Edition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.type,
  });

  factory Edition.fromJson(Map<String, dynamic> json) {
    return Edition(
      identifier: json['identifier'] ?? '',
      language: json['language'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      format: json['format'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class Ayah {
  final int number;
  final String text;
  final String? audio;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;

  Ayah({
    required this.number,
    required this.text,
    this.audio,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      audio: json['audio'],
      numberInSurah: json['numberInSurah'] ?? 0,
      juz: json['juz'] ?? 0,
      manzil: json['manzil'] ?? 0,
      page: json['page'] ?? 0,
      ruku: json['ruku'] ?? 0,
      hizbQuarter: json['hizbQuarter'] ?? 0,
    );
  }
}

class TimelineClip {
  final int ayahNumber;
  final String arabic;
  final String translation;
  final String? phonetic;
  final String audioPath;
  final Duration duration;
  final double startTime;
  /// Word-by-word timing for recitation sync.
  /// Each entry: {'word': String, 'start': double, 'end': double}
  final List<Map<String, dynamic>> wordTimings;

  TimelineClip({
    required this.ayahNumber,
    required this.arabic,
    required this.translation,
    this.phonetic,
    required this.audioPath,
    required this.duration,
    required this.startTime,
    this.wordTimings = const [],
  });
}
