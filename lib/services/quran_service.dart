import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran.dart';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<List<Surah>> getSurahs() async {
    final response = await http.get(Uri.parse('$_baseUrl/surah'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((s) => Surah.fromMap(s)).toList();
    }
    throw Exception('Failed to load surahs');
  }

  Future<Surah> getSurah(int number) async {
    final response = await http.get(Uri.parse('$_baseUrl/surah/$number'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Surah.fromMap(data['data']);
    }
    throw Exception('Failed to load surah');
  }

  Future<List<Ayah>> getAyahs(int surahNumber, {String edition = 'quran-uthmani'}) async {
    final response = await http.get(Uri.parse('$_baseUrl/surah/$surahNumber/$edition'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data']['ayahs'] as List).map((a) => Ayah.fromMap(a)).toList();
    }
    throw Exception('Failed to load ayahs');
  }

  String getAudioUrl(int ayahNumber, {String reciter = 'ar.alafasy'}) {
    return 'https://cdn.islamic.network/quran/audio/128/$reciter/$ayahNumber.mp3';
  }
}
