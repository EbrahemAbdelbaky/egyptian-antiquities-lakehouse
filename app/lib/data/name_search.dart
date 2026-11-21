/// Loose matching of names.
///
/// A ruler is written in many ways ("Ramses", "Ramesses", "Ramsès", "Rameses"), so the search does not
/// compare the letters as they are. It compares three simpler forms of a name:
///   1. the plain form: lower case, no accents, no punctuation
///   2. the skeleton: the consonants only, with double letters and the silent h left out, so that
///      "ramesses" and "ramsès" both become "rms" and "cleopatra" and "cléopâtre" both become "klptr"
///   3. the numbers: "II", "ii" and "2" are the same number
/// A few well-known kings can also be searched by their Arabic name.

const Map<String, String> _accents = <String, String>{
  'a': 'àáâäãåāăą',
  'e': 'èéêëēĕėęě',
  'i': 'ìíîïĩīĭį',
  'o': 'òóôöõōŏő',
  'u': 'ùúûüũūŭůű',
  'c': 'çćč',
  'n': 'ñń',
  's': 'šśşṣ',
  'z': 'žźżẓ',
  'y': 'ýÿ',
  'd': 'đðḏ',
  'h': 'ḥḫ',
  't': 'ṭṯ',
};

final Map<int, String> _plainOf = _buildPlainOf();

Map<int, String> _buildPlainOf() {
  final out = <int, String>{};
  _accents.forEach((base, chars) {
    for (final rune in chars.runes) {
      out[rune] = base;
    }
  });
  out[0xDF] = 'ss'; // ß
  out[0x153] = 'oe'; // œ
  out[0xE6] = 'ae'; // æ
  return out;
}

/// "Cléopâtre VII" -> "cleopatre vii": lower case, no accents, no punctuation, single spaces.
String foldName(String text) {
  final b = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue; // a combining accent
    // apostrophes and the transliteration marks of ayin and alef are dropped, not turned into a space
    if (rune == 0x27 || rune == 0x2018 || rune == 0x2019 || rune == 0x2BB || rune == 0x2BE || rune == 0x2BF) {
      continue;
    }
    final mapped = _plainOf[rune];
    if (mapped != null) {
      b.write(mapped);
      continue;
    }
    final isLetter = rune >= 0x61 && rune <= 0x7A;
    final isDigit = rune >= 0x30 && rune <= 0x39;
    if (isLetter || isDigit) {
      b.writeCharCode(rune);
    } else {
      b.write(' ');
    }
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// The consonants of a folded word: "ramesses" -> "rms", "thoutmosis" -> "tms", "ahmose" -> "ams".
/// A word that starts with a vowel keeps one "a" in front, so "Ahmose" is not mixed up with "Moses".
String skeleton(String word) {
  final b = StringBuffer();
  var last = '';
  for (var i = 0; i < word.length; i++) {
    var c = word[i];
    if (c == 'c' || c == 'q') c = 'k';
    if ('aeiouyw'.contains(c)) {
      if (i == 0) {
        b.write('a');
        last = 'a';
      }
      continue;
    }
    if (c == 'h' && i > 0) continue; // the silent h: "thutmose" and "tuthmosis"
    if (c == last) continue; // double letters
    b.write(c);
    last = c;
  }
  return b.toString();
}

/// "iii" -> 3, "xii" -> 12, "2" -> 2; null when the word is not a number.
int? _numberOf(String token) {
  if (token.isEmpty) return null;
  if (RegExp(r'^[0-9]+$').hasMatch(token)) return int.tryParse(token);
  if (!RegExp(r'^x{0,3}(ix|iv|v?i{0,3})$').hasMatch(token)) return null;
  const values = <String, int>{'i': 1, 'v': 5, 'x': 10};
  var total = 0;
  for (var i = 0; i < token.length; i++) {
    final v = values[token[i]] ?? 0;
    final next = i + 1 < token.length ? (values[token[i + 1]] ?? 0) : 0;
    total += v < next ? -v : v;
  }
  return total;
}

/// One spelling of a name, prepared for matching.
class NameForm {
  NameForm._(this.words, this.skeletons, this.numbers);

  factory NameForm(String text) {
    final words = <String>[];
    final numbers = <int>{};
    for (final token in foldName(text).split(' ')) {
      if (token.isEmpty) continue;
      final n = _numberOf(token);
      if (n != null) {
        numbers.add(n);
      } else {
        words.add(token);
      }
    }
    return NameForm._(words, <String>[for (final w in words) skeleton(w)], numbers);
  }

  /// the folded words, without the numbers
  final List<String> words;

  /// the skeleton of each word
  final List<String> skeletons;

  /// the numbers in the name (II, III ...)
  final Set<int> numbers;

  String get plain => words.join(' ');
}

/// What the person typed, prepared for matching against the spellings of the rulers.
class NameQuery {
  NameQuery(String text) : _form = NameForm(arabicToEnglish(text));

  final NameForm _form;

  bool get isEmpty => _form.words.isEmpty && _form.numbers.isEmpty;

  /// the typed words in the folded form, for sorting the results
  String get plain => _form.plain;

  /// Every typed word must be found in the name, either as plain letters or by its skeleton;
  /// every typed number must be a number of the name.
  bool matches(NameForm name) {
    for (final n in _form.numbers) {
      if (!name.numbers.contains(n)) return false;
    }
    final namePlain = name.plain;
    for (var i = 0; i < _form.words.length; i++) {
      final word = _form.words[i];
      if (namePlain.contains(word)) continue;
      final sk = _form.skeletons[i];
      if (word.length >= 4 && sk.length >= 2) {
        final found = name.skeletons.any((s) => sk.length < 3 ? s == sk : s.startsWith(sk));
        if (found) continue;
      }
      return false;
    }
    return true;
  }
}

// --------------------------------------------------------------------------------------------
// Arabic names of well-known kings
// --------------------------------------------------------------------------------------------

bool hasArabic(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x600 && rune <= 0x6FF) return true;
  }
  return false;
}

/// The Arabic spelling of a few well-known rulers, written in the normal form (no hamza on the alef,
/// ya instead of alef maqsura, ha instead of ta marbuta), and the English name to look for.
const Map<String, String> _arabicNames = <String, String>{
  'رمسيس': 'ramesses',
  'كليوباترا': 'cleopatra',
  'كليوبترا': 'cleopatra',
  'احمس': 'ahmose',
  'تحتمس': 'thutmose',
  'تحوتمس': 'thutmose',
  'حتشبسوت': 'hatshepsut',
  'اخناتون': 'akhenaten',
  'امنحتب': 'amenhotep',
  'امنحوتب': 'amenhotep',
  'توت': 'tut',
  'خوفو': 'khufu',
  'خفرع': 'khafre',
  'خفرن': 'khafre',
  'منقرع': 'menkaure',
  'منكاورع': 'menkaure',
  'سنفرو': 'sneferu',
  'سنوسرت': 'senusret',
  'امنمحات': 'amenemhat',
  'منتوحتب': 'mentuhotep',
  'سيتي': 'seti',
  'مرنبتاح': 'merneptah',
  'زوسر': 'djoser',
  'جوسر': 'djoser',
  'بيبي': 'pepi',
  'نارمر': 'narmer',
  'مينا': 'menes',
  'بسماتيك': 'psamtik',
  'نختنبو': 'nectanebo',
  'شيشنق': 'shoshenq',
  'اسركون': 'osorkon',
  'تهارقا': 'taharqa',
  'شباكا': 'shabaka',
  'داريوس': 'darius',
  'قمبيز': 'cambyses',
  'بطليموس': 'ptolemy',
  'اوغسطس': 'augustus',
  'اغسطس': 'augustus',
  'تيبريوس': 'tiberius',
  'كلوديوس': 'claudius',
  'نيرون': 'nero',
  'تراجان': 'trajan',
  'هادريان': 'hadrian',
  'دقلديانوس': 'diocletian',
  'قسطنطين': 'constantine',
};

/// "the second", "the third" ... as numbers.
const Map<String, String> _arabicOrdinals = <String, String>{
  'الاول': '1',
  'الثاني': '2',
  'الثالث': '3',
  'الرابع': '4',
  'الخامس': '5',
  'السادس': '6',
  'السابع': '7',
  'الثامن': '8',
  'التاسع': '9',
  'العاشر': '10',
};

/// "رمسيس الثاني" -> "ramesses 2". Text without Arabic letters is returned as it is.
String arabicToEnglish(String text) {
  if (!hasArabic(text)) return text;
  final b = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x64B && rune <= 0x65F) continue; // short vowel marks
    if (rune == 0x670 || rune == 0x640) continue; // dagger alef, tatweel
    if (rune >= 0x660 && rune <= 0x669) {
      b.writeCharCode(0x30 + rune - 0x660); // Arabic-Indic digits
      continue;
    }
    switch (rune) {
      case 0x623: // alef with hamza above
      case 0x625: // alef with hamza below
      case 0x622: // alef with madda
      case 0x671: // alef wasla
        b.write('ا');
        break;
      case 0x649: // alef maqsura
      case 0x626: // ya with hamza
        b.write('ي');
        break;
      case 0x629: // ta marbuta
        b.write('ه');
        break;
      case 0x624: // waw with hamza
        b.write('و');
        break;
      default:
        b.writeCharCode(rune);
    }
  }
  final out = <String>[];
  for (final token in b.toString().split(RegExp(r'\s+'))) {
    if (token.isEmpty) continue;
    if (!hasArabic(token)) {
      out.add(token);
      continue;
    }
    final ordinal = _arabicOrdinals[token];
    if (ordinal != null) {
      out.add(ordinal);
      continue;
    }
    for (final e in _arabicNames.entries) {
      if (token.contains(e.key)) {
        out.add(e.value);
        break;
      }
    }
  }
  return out.join(' ');
}
