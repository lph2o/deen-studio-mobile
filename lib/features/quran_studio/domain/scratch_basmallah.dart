void main() {
  String apiText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الم";
  
  String stripBasmallah(String text) {
    // A robust way is to just strip all diacritics and check if it starts with "بسم الله الرحمن الرحيم"
    final normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED]'), '')
                           .replaceAll('ٱ', 'ا')
                           .replaceAll('ٰ', 'ا'); // replace alif maqsurah/dagger alif
    
    // Actually, simpler:
    // Just find the index of "الرحيم" or "الرحيم " in the text after stripping? No.
    // Let's just find the first 4 words.
    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 4) {
      final first4 = words.sublist(0, 4).join(' ');
      final norm4 = first4.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED]'), '')
                           .replaceAll('ٱ', 'ا');
      if (norm4 == "بسم الله الرحمن الرحيم") {
        return words.sublist(4).join(' ');
      }
    }
    return text;
  }
  
  print(stripBasmallah(apiText));
}
