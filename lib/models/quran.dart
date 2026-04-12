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

  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      number: map['number'] ?? 0,
      name: map['name'] ?? '',
      englishName: map['englishName'] ?? '',
      englishNameTranslation: map['englishNameTranslation'] ?? '',
      numberOfAyahs: map['numberOfAyahs'] ?? 0,
      revelationType: map['revelationType'] ?? '',
    );
  }
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    String text = map['text'] ?? '';
    final numberInSurah = map['numberInSurah'] ?? 0;
    
    // AlQuran.cloud API appends the Basmallah to the first verse of every Surah (except 1 and 9).
    // This causes audio desyncs in video generation since the audio file typically starts directly with the verse.
    if (numberInSurah == 1) {
      const basmalahUthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ';
      const basmalahUthmani2 = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ ';
      const basmalahSimple = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ';
      
      if (text.startsWith(basmalahUthmani)) {
        text = text.substring(basmalahUthmani.length);
      } else if (text.startsWith(basmalahUthmani2)) {
        text = text.substring(basmalahUthmani2.length);
      } else if (text.startsWith(basmalahSimple)) {
        text = text.substring(basmalahSimple.length);
      }
      
      // Fallback: If it's Surah Al-Fatihah, we MUST NOT strip it because Ayat 1 IS the Basmallah.
      // Above logic handles this because Al-Fatihah Ayat 1 does NOT have a trailing space in the API, 
      // thus startsWith(basmalahUthmani_with_space) returns false!
    }

    return Ayah(
      number: map['number'] ?? 0,
      text: text,
      numberInSurah: numberInSurah,
      juz: map['juz'] ?? 0,
      manzil: map['manzil'] ?? 0,
      page: map['page'] ?? 0,
      ruku: map['ruku'] ?? 0,
      hizbQuarter: map['hizbQuarter'] ?? 0,
      sajda: map['sajda'] ?? false,
    );
  }
}
