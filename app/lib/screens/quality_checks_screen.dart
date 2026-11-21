import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../theme.dart';
import '../widgets.dart';

/// The build steps of the Gold layer, as the checks name them: the step, its short name and what it builds.
const Map<String, List<String>> _steps = <String, List<String>>{
  'G1': <String>['Museums', 'The museum table, dim_museum.'],
  'G2': <String>['Periods', 'The period table, dim_era: the periods of Egyptian history, plus one band for artifacts without a year.'],
  'G3': <String>['Sites', 'The find-site table, dim_site: one row per distinct site text.'],
  'G4': <String>[
    'Rulers',
    'The ruler table dim_ruler, the map from each museum text to a ruler (map_reign_to_ruler) and the spellings of each ruler (ruler_name_variant).',
  ],
  'G5': <String>['Facts', 'The fact table, fact_artifact: one row per artifact, linked to its museum, period, ruler and site.'],
  'G6': <String>['Views', 'The views behind the Documentation gaps and the Time, types and sites screens.'],
  'G7': <String>['ML table', 'The table prepared for machine learning, ml_dataset.'],
};

/// The 24 checks that were run on the Gold layer, one by one, read from gold_checks.json.
class QualityChecksScreen extends StatefulWidget {
  const QualityChecksScreen({super.key, required this.data});

  final GoldData data;

  @override
  State<QualityChecksScreen> createState() => _QualityChecksScreenState();
}

class _QualityChecksScreenState extends State<QualityChecksScreen> {
  late final List<Rec> _checks;
  late final List<String> _stepOrder;

  /// 'All' or one step (G1 to G7)
  String _step = 'All';

  @override
  void initState() {
    super.initState();
    final raw = widget.data.checks['checks'];
    final list = <Rec>[];
    if (raw is List) {
      for (final c in raw) {
        if (c is Map) list.add(Map<String, dynamic>.from(c));
      }
    }
    list.sort((a, b) => toInt(a['seq']).compareTo(toInt(b['seq'])));
    _checks = list;
    final order = <String>[];
    for (final c in list) {
      final s = toStr(c['step']);
      if (!order.contains(s)) order.add(s);
    }
    _stepOrder = order;
  }

  bool _ok(Rec r) => toStr(r['result']).toUpperCase() == 'OK';

  List<Rec> _of(String step) => _checks.where((c) => toStr(c['step']) == step).toList();

  int _okIn(List<Rec> list) => list.where(_ok).length;

  String _stepName(String step) => _steps[step]?[0] ?? step;

  // ------------------------------------------------------------------------------------------
  // the screen
  // ------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final shown = _step == 'All' ? _stepOrder : <String>[_step];
    return PageScaffold(
      title: 'Quality checks',
      subtitle: 'The 24 checks that were run on the Gold layer, one by one.',
      art: 'feather',
      children: <Widget>[
        const AboutBox(
          lines: <String>[
            'After the Gold tables were built, a set of checks was run in one pass (the script G_ALL_gold.sql). Each check compares a number '
                'that the tables must have with the number they really have.',
            'A check is OK when the two agree. The line under its name shows both numbers, so you can read what was compared and not only the result.',
            'The checks are grouped by the build step that made the tables: museums, periods, sites, rulers, facts, views and the machine-learning table. '
                'Choose a step to see only its checks.',
            'What the checks prove: the tables are complete, they agree with each other, and they agree with the counts that were verified earlier in Bronze and Silver. '
                'What they do not prove is listed at the bottom of the page.',
            'This page shows a saved result (gold_checks.json), written when the checks ran. It does not run the checks again.',
          ],
        ),
        const SizedBox(height: 18),
        KeyFigures(items: _figures()),
        const SizedBox(height: 22),
        _stepStrip(),
        const SizedBox(height: 18),
        for (final s in shown) ...<Widget>[
          _stepPanel(s),
          const SizedBox(height: 18),
        ],
        _limits(),
      ],
    );
  }

  List<KeyFigure> _figures() {
    final ok = _okIn(_checks);
    final failed = _checks.length - ok;
    final stamp = fmtStamp(toStr(widget.data.checks['run_finished'])); // "2026-11-16 19:11"
    final day = stamp.length >= 10 ? stamp.substring(0, 10) : stamp;
    final time = stamp.length >= 16 ? stamp.substring(11, 16) : null;
    return <KeyFigure>[
      KeyFigure('Checks run', fmtInt(_checks.length), caption: 'in one pass', color: AppColors.goldDeep),
      KeyFigure(
        'Passed',
        fmtInt(ok),
        caption: _checks.isEmpty ? null : '${fmtPct(100.0 * ok / _checks.length)} of the checks',
        color: AppColors.ok,
      ),
      KeyFigure(
        'Not passed',
        fmtInt(failed),
        caption: failed == 0 ? 'none' : 'see the lines marked in red',
        color: failed == 0 ? AppColors.lapis : AppColors.carnelian,
      ),
      KeyFigure('Build steps', fmtInt(_stepOrder.length), caption: 'from G1 to ${_stepOrder.isEmpty ? '-' : _stepOrder.last}'),
      KeyFigure('Last run', day.isEmpty ? '-' : day, caption: time == null ? null : 'at $time'),
    ];
  }

  /// One tile per build step. A tile filters the list below; its bar shows how many checks passed.
  Widget _stepStrip() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _StepTile(
          code: 'All',
          name: 'All steps',
          ok: _okIn(_checks),
          total: _checks.length,
          selected: _step == 'All',
          onTap: () => setState(() => _step = 'All'),
        ),
        for (final s in _stepOrder)
          _StepTile(
            code: s,
            name: _stepName(s),
            ok: _okIn(_of(s)),
            total: _of(s).length,
            selected: _step == s,
            onTap: () => setState(() => _step = _step == s ? 'All' : s),
          ),
      ],
    );
  }

  Widget _stepPanel(String step) {
    final list = _of(step);
    final ok = _okIn(list);
    final what = _steps[step]?[1];
    return Panel(
      title: '$step  ${_stepName(step)}',
      trailing: Pill('$ok of ${list.length} OK', color: ok == list.length ? AppColors.ok : AppColors.carnelian),
      caption: what,
      child: Column(
        children: <Widget>[
          for (final c in list) _CheckLine(check: c, ok: _ok(c)),
        ],
      ),
    );
  }

  Widget _limits() {
    const items = <String>[
      'Whether a link from a ruler to Wikidata names the right person. The checks count the links; they do not judge them. '
          'A manual audit of a sample of the links is planned for that.',
      'Whether the museums\' own records are right. Gold reflects what the museums published, with its gaps, which the Documentation gaps screen measures.',
      'Meaning. A check compares counts and keys between tables. It does not read each artifact.',
    ];
    return Panel(
      title: 'What the checks do not cover',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 10),
                    child: SizedBox(width: 6, height: 6, child: ColoredBox(color: AppColors.gold)),
                  ),
                  Expanded(child: Text(t, style: AppText.body)),
                ],
              ),
            ),
          Text(
            toStr(widget.data.checks['source']),
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

/// A tile of the strip above the list: the step, its name, and a bar with the share of checks that passed.
class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.code,
    required this.name,
    required this.ok,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String name;
  final int ok;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final failed = total - ok;
    return SizedBox(
      width: 150,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.lapis.withAlpha(18) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.lapis : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    code,
                    style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDeep,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(name, style: AppText.cell, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (ok > 0) Expanded(flex: ok, child: const ColoredBox(color: AppColors.ok)),
                        if (failed > 0) Expanded(flex: failed, child: const ColoredBox(color: AppColors.carnelian)),
                        if (total == 0) const Expanded(child: ColoredBox(color: AppColors.track)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('$ok of $total OK', style: AppText.small),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One check: a mark for its result, its name, and the numbers that were compared.
class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.check, required this.ok});

  final Rec check;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colour = ok ? AppColors.ok : AppColors.carnelian;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(ok ? Icons.check_circle : Icons.cancel, size: 20, color: colour),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(toStr(check['check_name']), style: AppText.body),
                const SizedBox(height: 3),
                Text(toStr(check['detail']), style: AppText.small),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('#${toInt(check['seq'])}', style: AppText.small),
        ],
      ),
    );
  }
}
