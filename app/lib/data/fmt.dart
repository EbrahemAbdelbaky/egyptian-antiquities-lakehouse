/// Small helpers that turn the loosely typed JSON values into numbers and text.

int toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0.0;
}

String toStr(dynamic v) => v == null ? '' : '$v';

/// (1, 'artifact') -> "1 artifact", (2, 'artifact') -> "2 artifacts"
String countOf(int n, String noun) => '${fmtInt(n)} $noun${n == 1 ? '' : 's'}';

/// 69250 -> "69,250"
String fmtInt(num n) {
  final s = n.round().toString();
  final negative = s.startsWith('-');
  final digits = negative ? s.substring(1) : s;
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
    b.write(digits[i]);
  }
  return negative ? '-${b.toString()}' : b.toString();
}

/// 59.34 -> "59.3%"
String fmtPct(num n) => '${n.toStringAsFixed(1)}%';

/// 0.7321 -> "0.732"
String fmtScore(num n) => n.toStringAsFixed(3);

/// "2026-11-20T17:36:23.7308080" -> "2026-11-20 17:36"
String fmtStamp(String iso) {
  if (iso.length < 16) return iso;
  return iso.substring(0, 16).replaceFirst('T', ' ');
}

/// The field names of the documentation score, in words.
String fieldLabel(String field) {
  switch (field) {
    case 'site':
      return 'Find site';
    case 'date':
      return 'Date';
    case 'period':
      return 'Period text';
    case 'region':
      return 'Region';
    case 'excavation':
      return 'Excavation';
    case 'ruler':
      return 'Ruler named';
    default:
      return field;
  }
}
