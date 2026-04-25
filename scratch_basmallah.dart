// ignore_for_file: avoid_print
void main() {
  String text = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الر ۚ كِتَابٌ أُحْكِمَتْ آيَاتُهُ ثُمَّ فُصِّلَتْ مِن لَّدُنْ حَكِيمٍ خَبِيرٍ";
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final first4 = words.sublist(0, 4).join(' ');
  final normalized = first4
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED]'), '')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ـ', '');
      
  print("Raw: $first4");
  print("Normalized: $normalized");
  print("Match: ${normalized == 'بسم الله الرحمن الرحيم'}");
}
