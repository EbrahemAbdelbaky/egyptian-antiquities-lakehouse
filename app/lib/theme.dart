import 'package:flutter/material.dart';

/// The three font families (files in assets/fonts, registered in pubspec.yaml by the setup script).
///   GoldSerif : TeX Gyre Pagella (a Palatino-style book face), for titles and big numbers
///   GoldSans  : Carlito (a humanist sans), for text and tables
///   GoldMono  : DejaVu Sans Mono, only for table and column names
const String kSerif = 'GoldSerif';
const String kSans = 'GoldSans';
const String kMono = 'GoldMono';

/// Colours. The page is limestone, the ink is a deep Nile blue, lapis is the main accent and gold marks the Gold layer.
/// Bronze, silver and gold are also the three strata of the medallion (Bronze, Silver, Gold).
class AppColors {
  static const Color paper = Color(0xFFF1F2EE); // limestone
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF16202E);
  static const Color sidebar = Color(0xFFFAFAF7);
  static const Color muted = Color(0xFF5D6675);
  static const Color line = Color(0xFFD7DAD2);
  static const Color track = Color(0xFFE6E8E1);
  static const Color stripe = Color(0xFFF6F7F3);
  static const Color headerBg = Color(0xFFE8EBE4);

  static const Color lapis = Color(0xFF1D4E89);
  static const Color lapisDeep = Color(0xFF0E2744);
  static const Color gold = Color(0xFFC59A2C);
  static const Color goldDeep = Color(0xFF86620F); // gold that is dark enough for text
  static const Color teal = Color(0xFF1F8A7F);
  static const Color burgundy = Color(0xFF8C2F39);
  static const Color blue = Color(0xFF3B5B92);
  static const Color violet = Color(0xFF6B4E9B);

  static const Color bronze = Color(0xFF5B4637);
  static const Color silver = Color(0xFFB5BDC5);
  static const Color goldLeaf = Color(0xFFD6AB3E);

  /// The painted colours of Egyptian friezes: blue, green (faience) and red (carnelian), with gold.
  static const Color lapisBright = Color(0xFF2F63AE);
  static const Color faience = Color(0xFF2A9D8F);
  static const Color carnelian = Color(0xFFB5472F);

  static const Color edge = Color(0xFFB4B9AE);
  static const Color aboutBg = Color(0xFFEAF0F6);
  static const Color aboutLine = Color(0xFFCBD6E3);
  static const Color ok = Color(0xFF2E7D4F);

  /// One colour per museum, used everywhere the museums are compared.
  static Color museum(String name) {
    if (name == 'Met') return burgundy;
    if (name == 'Cleveland') return teal;
    if (name == 'Louvre') return blue;
    return muted;
  }

  /// One colour per group of periods (the groups of dim_era.era_group), used wherever periods are listed.
  static Color eraGroup(String group) {
    switch (group) {
      case 'Prehistoric':
        return bronze;
      case 'Pharaonic':
        return gold;
      case 'Greco-Roman':
        return lapisBright;
      case 'Late Antique and later':
        return faience;
      default:
        return silver;
    }
  }

  /// One colour per kind of Gold table.
  static Color tableKind(String kind) {
    if (kind == 'Fact') return gold;
    if (kind == 'Dimension') return lapis;
    if (kind == 'Mapping') return teal;
    if (kind == 'ML dataset') return violet;
    return muted;
  }
}

class AppText {
  static const TextStyle h1 = TextStyle(
    fontFamily: kSerif,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.15,
  );
  static const TextStyle lead = TextStyle(
    fontFamily: kSans,
    fontSize: 16,
    color: AppColors.muted,
    height: 1.5,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: kSerif,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: kSerif,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
  );
  static const TextStyle body = TextStyle(
    fontFamily: kSans,
    fontSize: 14.5,
    color: AppColors.ink,
    height: 1.5,
  );
  static const TextStyle small = TextStyle(
    fontFamily: kSans,
    fontSize: 13,
    color: AppColors.muted,
    height: 1.4,
  );
  static const TextStyle cell = TextStyle(
    fontFamily: kSans,
    fontSize: 13,
    color: AppColors.ink,
  );
  static const TextStyle aboutTitle = TextStyle(
    fontFamily: kSans,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.lapis,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: kMono,
    fontSize: 12.5,
    color: AppColors.ink,
  );

  /// Caption under a figure: serif italic, like a figure legend in a paper.
  static const TextStyle caption = TextStyle(
    fontFamily: kSerif,
    fontSize: 13.5,
    fontStyle: FontStyle.italic,
    color: AppColors.muted,
    height: 1.4,
  );

  /// A value in a record: sans, bold.
  static const TextStyle value = TextStyle(
    fontFamily: kSans,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.lapis,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.lapis,
    onSurface: AppColors.ink,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kSans,
    scaffoldBackgroundColor: AppColors.paper,
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        fontFamily: kSans,
        fontSize: 12.5,
        color: Colors.white,
      ),
    ),
  );
}
