import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One row of a dataset: column name -> value (a NULL of the database stays null).
typedef Rec = Map<String, dynamic>;

/// Everything the app shows comes from two files exported from the Gold layer:
///   assets/gold_data.json    the tables, samples and views (written by export_gold_json.ps1)
///   assets/gold_checks.json  the result of the 24 Gold checks (G_ALL_gold.sql)
class GoldData {
  GoldData._(this._datasets, this.checks, this.databaseName, this.exportedAt);

  final Map<String, dynamic> _datasets;
  final Map<String, dynamic> checks;
  final String databaseName;
  final String exportedAt;
  final Map<String, List<Rec>> _cache = <String, List<Rec>>{};

  static Future<GoldData> load() async {
    final dataText = await rootBundle.loadString('assets/gold_data.json');
    final checksText = await rootBundle.loadString('assets/gold_checks.json');
    final data = jsonDecode(dataText) as Map<String, dynamic>;
    final checks = jsonDecode(checksText) as Map<String, dynamic>;
    final datasets = data['datasets'] as Map<String, dynamic>;
    final metaRaw = datasets['meta'];
    final meta = metaRaw is Map ? Map<String, dynamic>.from(metaRaw) : <String, dynamic>{};
    return GoldData._(
      datasets,
      checks,
      '${meta['database_name'] ?? ''}',
      '${meta['exported_at'] ?? ''}',
    );
  }

  /// A dataset that is a list of rows (tables, samples and views).
  List<Rec> rows(String name) {
    final cached = _cache[name];
    if (cached != null) return cached;
    final raw = _datasets[name];
    final out = <Rec>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) out.add(Map<String, dynamic>.from(item));
      }
    }
    _cache[name] = out;
    return out;
  }

  /// A dataset that is a single object (the machine-learning summary).
  Rec one(String name) {
    final raw = _datasets[name];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  bool has(String name) => _datasets.containsKey(name);
}
