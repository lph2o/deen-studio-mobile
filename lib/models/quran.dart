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
    return Ayah(
      number: map['number'] ?? 0,
      text: map['text'] ?? '',
      numberInSurah: map['numberInSurah'] ?? 0,
      juz: map['juz'] ?? 0,
      manzil: map['manzil'] ?? 0,
      page: map['page'] ?? 0,
      ruku: map['ruku'] ?? 0,
      hizbQuarter: map['hizbQuarter'] ?? 0,
      sajda: map['sajda'] ?? false,
    );
  }
}
