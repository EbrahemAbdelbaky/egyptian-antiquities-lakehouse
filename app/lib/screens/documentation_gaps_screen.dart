import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../theme.dart';
import '../widgets.dart';

const List<String> _museums = <String>['Met', 'Cleveland', 'Louvre'];

/// The fields of the documentation score, in the order of the matrix.
const List<String> _fields = <String>['site', 'date', 'period', 'region', 'excavation', 'ruler'];

/// A value computed from fewer artifacts than this is shown in italics: too few to compare.
const int _fewArtifacts = 30;

/// One period with the three museums side by side.
class _EraRow {
  _EraRow(this.order, this.name, this.group);

  final int order;
  final String name;
  final String group;
  final Map<String, Rec> byMuseum = <String, Rec>{};
}

/// Where the museums leave their records empty.
/// Everything is read from three views of Gold: v_documentation_gap, v_gap_by_museum and v_gap_by_era.
class DocumentationGapsScreen extends StatefulWidget {
  const DocumentationGapsScreen({super.key, required this.data});

  final GoldData data;

  @override
  State<DocumentationGapsScreen> createState() => _DocumentationGapsScreenState();
}

class _DocumentationGapsScreenState extends State<DocumentationGapsScreen> {
  late final Map<String, Map<String, Rec>> _gap;
  late final Map<String, Rec> _museumRow;
  late final List<_EraRow> _eraRows;

  String _museum = 'All';
  String? _selMuseum;
  String? _selField;

  /// the period table shows the average score (true) or the share with a find site (false)
  bool _scoreMetric = true;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _gap = <String, Map<String, Rec>>{};
    for (final r in d.rows('v_documentation_gap')) {
      _gap.putIfAbsent(toStr(r['museum_name']), () => <String, Rec>{})[toStr(r['field_name'])] = r;
    }
    _museumRow = <String, Rec>{
      for (final r in d.rows('v_gap_by_museum')) toStr(r['museum_name']): r,
    };
    final byOrder = <int, _EraRow>{};
    for (final r in d.rows('v_gap_by_era')) {
      final order = toInt(r['sort_order']);
      final row = byOrder.putIfAbsent(order, () => _EraRow(order, toStr(r['era_name']), toStr(r['era_group'])));
      row.byMuseum[toStr(r['museum_name'])] = r;
    }
    _eraRows = byOrder.values.toList()..sort((a, b) => a.order.compareTo(b.order));

    // the cell that is open at the start: the largest gap
    Rec? worst;
    for (final fields in _gap.values) {
      for (final r in fields.values) {
        if (worst == null || toDouble(r['missing_pct']) > toDouble(worst['missing_pct'])) {
          worst = r;
        }
      }
    }
    if (worst != null) {
      _selMuseum = toStr(worst['museum_name']);
      _selField = toStr(worst['field_name']);
    }
  }

  bool _dim(String museum) => _museum != 'All' && _museum != museum;

  List<Rec> _chosenMuseums() {
    final out = <Rec>[];
    for (final m in _museums) {
      if (_museum != 'All' && m != _museum) continue;
      final r = _museumRow[m];
      if (r != null) out.add(r);
    }
    return out;
  }

  // ------------------------------------------------------------------------------------------
  // the screen
  // ------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rows = widget.data.rows('v_documentation_gap');
    return PageScaffold(
      title: 'Documentation gaps',
      subtitle: 'Where the museums leave their records empty, and how complete each record is.',
      art: 'papyrus',
      children: <Widget>[
        const AboutBox(
          lines: <String>[
            'A documentation gap is a field that a museum could record but left empty for an artifact. For every artifact, Gold counts '
                'the fields that apply to its museum and keeps the share that are filled: the documentation score, from 0 to 1.',
            'The fields that Gold counts depend on the museum. The Met has six (find site, date, period text, region, excavation and ruler), '
                'the Louvre has three (find site, date and period text) and Cleveland has two (find site and date). '
                'A field that is not counted for a museum shows as "not counted" in the matrix.',
            'Because the number of counted fields differs, the average score is not a fair comparison between museums: Cleveland counts two fields, '
                'so its score is almost always 0.5. To compare the museums, compare the share that is missing in one field, in the matrix.',
            'Fully documented means that every counted field is filled; nothing documented means that none is. The museum filter changes the key figures '
                'and fades the other museums. Click a cell of the matrix to read its numbers.',
            'The numbers come from the Gold views v_documentation_gap, v_gap_by_museum and v_gap_by_era. The table at the bottom shows the rows of the first one.',
          ],
        ),
        const SizedBox(height: 18),
        _filterBar(),
        const SizedBox(height: 18),
        KeyFigures(items: _figures()),
        const SizedBox(height: 22),
        Panel(
          title: 'Which fields are empty',
          caption: 'Share of the artifacts whose field is empty. The darker the cell, the larger the gap.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _matrix(),
              const SizedBox(height: 14),
              _selectedLine(),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'How complete the records are',
          caption: 'Each bar is one museum: all of its artifacts, split by how many of the counted fields are filled. '
              'The number of counted fields differs by museum, so the same score means different things.',
          child: _completeness(),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Documentation by period',
          caption: 'Darker is better documented. A value computed from fewer than $_fewArtifacts artifacts is in italics. '
              'The Cleveland score is almost always 0.5: it counts two fields, find site and date, and the date is always filled.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChipButton(
                    label: 'Average documentation score',
                    selected: _scoreMetric,
                    onTap: () => setState(() => _scoreMetric = true),
                  ),
                  ChipButton(
                    label: 'Share with a find site',
                    selected: !_scoreMetric,
                    onTap: () => setState(() => _scoreMetric = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _periodTable(),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'The numbers behind this screen',
          caption: 'The rows of the Gold view v_documentation_gap: for each museum and counted field, how many artifacts '
              'are documented and how many are missing.',
          child: TableViewer(
            columns: const <String>[
              'museum_name',
              'field_name',
              'applicable_rows',
              'documented_rows',
              'missing_rows',
              'missing_pct',
            ],
            rows: rows,
            height: 36.0 + 30.0 * rows.length + 22,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------------------------------
  // filter and key figures
  // ------------------------------------------------------------------------------------------

  Widget _filterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('Museum', style: AppText.small),
          for (final m in <String>['All', ..._museums])
            ChipButton(
              label: m,
              selected: _museum == m,
              color: m == 'All' ? AppColors.lapis : AppColors.museum(m),
              dot: m == 'All' ? null : AppColors.museum(m),
              onTap: () => setState(() => _museum = m),
            ),
          if (_museum != 'All')
            TextButton(
              onPressed: () => setState(() => _museum = 'All'),
              child: const Text('Clear filter'),
            ),
        ],
      ),
    );
  }

  List<KeyFigure> _figures() {
    var artifacts = 0;
    var full = 0;
    var none = 0;
    var image = 0;
    var weighted = 0.0;
    var fewest = 0;
    var most = 0;
    for (final r in _chosenMuseums()) {
      final n = toInt(r['artifacts']);
      artifacts += n;
      full += toInt(r['fully_documented']);
      none += toInt(r['nothing_documented']);
      image += toInt(r['with_open_image']);
      weighted += toDouble(r['average_score']) * n;
      final k = toInt(r['fields_applicable']);
      if (fewest == 0 || k < fewest) fewest = k;
      if (k > most) most = k;
    }
    String share(int part) => artifacts == 0 ? '' : '${fmtPct(100.0 * part / artifacts)} of the artifacts';
    return <KeyFigure>[
      KeyFigure(
        'Artifacts',
        fmtInt(artifacts),
        caption: _museum == 'All' ? 'all three museums' : 'the $_museum only',
        color: AppColors.goldDeep,
      ),
      KeyFigure(
        'Average score',
        artifacts == 0 ? '-' : fmtScore(weighted / artifacts),
        caption: 'share of the counted fields that are filled',
      ),
      KeyFigure('Fully documented', fmtInt(full), caption: share(full)),
      KeyFigure('Nothing documented', fmtInt(none), caption: share(none), color: AppColors.carnelian),
      KeyFigure(
        'Counted fields',
        fewest == most ? '$most' : '$fewest to $most',
        caption: fewest == most ? 'for each artifact' : 'for each artifact, by museum',
      ),
      KeyFigure(
        'With an open image',
        fmtInt(image),
        caption: _museum == 'Louvre' ? 'none in the data we hold' : share(image),
      ),
    ];
  }

  // ------------------------------------------------------------------------------------------
  // the matrix of empty fields
  // ------------------------------------------------------------------------------------------

  Widget _museumHead(String museum) {
    final r = _museumRow[museum];
    return Opacity(
      opacity: _dim(museum) ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(width: 9, height: 9, color: AppColors.museum(museum)),
                const SizedBox(width: 6),
                Flexible(child: Text(museum, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.value)),
              ],
            ),
            Text(
              r == null ? '' : fmtInt(toInt(r['artifacts'])),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small,
            ),
          ],
        ),
      ),
    );
  }

  Widget _matrix() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final labelWidth = compact ? 84.0 : 150.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(width: labelWidth),
                for (final m in _museums) Expanded(child: _museumHead(m)),
              ],
            ),
            const SizedBox(height: 6),
            for (final f in _fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: labelWidth, child: Text(fieldLabel(f), style: AppText.body)),
                    for (final m in _museums) Expanded(child: _gapCell(m, f)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _gapCell(String museum, String field) {
    final r = _gap[museum]?[field];
    final Widget body;
    if (r == null) {
      body = Container(
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.stripe,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.line),
        ),
        child: const Text(
          'not counted',
          style: TextStyle(fontFamily: kSans, fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF8A919D)),
        ),
      );
    } else {
      final pct = toDouble(r['missing_pct']);
      final t = (pct / 100).clamp(0.0, 1.0).toDouble();
      final fill = Color.lerp(const Color(0xFFF1ECDD), AppColors.carnelian, t) ?? AppColors.carnelian;
      // white text only on the darkest cells; on the middle shades dark text is easier to read
      final ink = t >= 0.8 ? Colors.white : AppColors.ink;
      final selected = _selMuseum == museum && _selField == field;
      body = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() {
            _selMuseum = museum;
            _selField = field;
          }),
          child: Container(
            height: 62,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 2),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    fmtPct(pct),
                    style: TextStyle(
                      fontFamily: kSerif,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    '${fmtInt(toInt(r['missing_rows']))} of ${fmtInt(toInt(r['applicable_rows']))}',
                    style: TextStyle(fontFamily: kSans, fontSize: 11.5, color: ink.withAlpha(225)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Opacity(opacity: _dim(museum) ? 0.38 : 1.0, child: body);
  }

  Widget _selectedLine() {
    const hint = Text('Click a cell to read its numbers.', style: AppText.small);
    final m = _selMuseum;
    final f = _selField;
    if (m == null || f == null) return hint;
    final r = _gap[m]?[f];
    if (r == null) return hint;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.aboutBg,
        border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: '$m, ${fieldLabel(f)}: ', style: AppText.value),
            TextSpan(
              text: '${fmtInt(toInt(r['missing_rows']))} of ${fmtInt(toInt(r['applicable_rows']))} artifacts are left empty '
                  '(${fmtPct(toDouble(r['missing_pct']))}). ${fmtInt(toInt(r['documented_rows']))} have a value.',
              style: AppText.body,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // how complete the records are
  // ------------------------------------------------------------------------------------------

  Widget _completeness() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final m in _museums) _completenessRow(m),
      ],
    );
  }

  Widget _completenessRow(String museum) {
    final r = _museumRow[museum];
    if (r == null) return const SizedBox.shrink();
    final n = toInt(r['artifacts']);
    final full = toInt(r['fully_documented']);
    final none = toInt(r['nothing_documented']);
    var partly = n - full - none;
    if (partly < 0) partly = 0;
    final fields = toInt(r['fields_applicable']);
    return Opacity(
      opacity: _dim(museum) ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(width: 10, height: 10, color: AppColors.museum(museum)),
                const SizedBox(width: 8),
                Text(museum, style: AppText.h3),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${fmtInt(n)} artifacts, $fields counted fields',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small,
                  ),
                ),
                const SizedBox(width: 8),
                Pill('Average score ${fmtScore(toDouble(r['average_score']))}', color: AppColors.lapis),
              ],
            ),
            const SizedBox(height: 8),
            _stack(full, partly, none),
            const SizedBox(height: 6),
            Wrap(
              spacing: 20,
              runSpacing: 2,
              children: <Widget>[
                _legendValue(AppColors.lapis, 'Fully documented', full, n),
                _legendValue(AppColors.silver, 'Partly documented', partly, n),
                _legendValue(AppColors.carnelian, 'Nothing documented', none, n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stack(int full, int partly, int none) {
    final segments = <Widget>[];
    void add(int count, Color color) {
      if (count > 0) segments.add(Expanded(flex: count, child: ColoredBox(color: color)));
    }

    add(full, AppColors.lapis);
    add(partly, AppColors.silver);
    add(none, AppColors.carnelian);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 18,
        child: segments.isEmpty
            ? const ColoredBox(color: AppColors.track)
            : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: segments),
      ),
    );
  }

  Widget _legendValue(Color color, String label, int count, int total) {
    final pct = total == 0 ? 0.0 : 100.0 * count / total;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 9, height: 9, color: color),
        const SizedBox(width: 6),
        Text('$label ${fmtInt(count)} (${fmtPct(pct)})', style: AppText.small),
      ],
    );
  }

  // ------------------------------------------------------------------------------------------
  // by period
  // ------------------------------------------------------------------------------------------

  Widget _periodTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final labelWidth = compact ? 118.0 : 210.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(width: labelWidth),
                for (final m in _museums) Expanded(child: _museumHead(m)),
              ],
            ),
            const SizedBox(height: 6),
            for (final e in _eraRows) _eraLine(e, labelWidth),
          ],
        );
      },
    );
  }

  Widget _eraLine(_EraRow e, double labelWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          Container(width: 4, height: 46, color: AppColors.eraGroup(e.group)),
          SizedBox(
            width: labelWidth - 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 6),
              child: Text(
                e.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 13.5, height: 1.25),
              ),
            ),
          ),
          for (final m in _museums) Expanded(child: _eraCell(e.byMuseum[m], m)),
        ],
      ),
    );
  }

  Widget _eraCell(Rec? r, String museum) {
    final fade = _dim(museum) ? 0.38 : 1.0;
    if (r == null) {
      return Opacity(
        opacity: fade,
        child: Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          child: const Text('-', style: AppText.small),
        ),
      );
    }
    final n = toInt(r['artifacts']);
    final double value;
    final String text;
    if (_scoreMetric) {
      value = toDouble(r['average_score']);
      text = fmtScore(value);
    } else {
      final p = toDouble(r['pct_with_site']);
      value = p / 100;
      text = fmtPct(p);
    }
    final t = value.clamp(0.0, 1.0).toDouble();
    final fill = Color.lerp(const Color(0xFFEDEFEA), AppColors.lapis, t) ?? AppColors.lapis;
    final ink = t >= 0.72 ? Colors.white : AppColors.ink;
    final few = n < _fewArtifacts;
    return Opacity(
      opacity: fade,
      child: Container(
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(3)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                text,
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontStyle: few ? FontStyle.italic : FontStyle.normal,
                  color: ink,
                  height: 1.15,
                ),
              ),
              Text(
                fmtInt(n),
                style: TextStyle(fontFamily: kSans, fontSize: 11, color: ink.withAlpha(220)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
