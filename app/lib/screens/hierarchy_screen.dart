import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand.dart';
import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../data/name_search.dart';
import '../theme.dart';
import '../widgets.dart';

const List<String> _museumFilters = <String>['All', 'Met', 'Cleveland', 'Louvre'];

/// One museum and a count, used for the split of a ruler's artifacts.
class _Part {
  const _Part(this.museum, this.count);

  final String museum;
  final int count;
}

/// One spelling of a ruler's name, with the museum that writes it (null for the Wikidata name).
class _Spelling {
  _Spelling(this.text, this.museum) : form = NameForm(text);

  final String text;
  final String? museum;
  final NameForm form;
}

/// The hierarchy of the snowflake: period, then ruler, then artifact.
/// Choose a period to see its rulers, then a ruler to see what the museums hold under it.
/// Everything is read from dim_era, dim_ruler, ruler_name_variant, map_reign_to_ruler and the views of Gold.
class HierarchyScreen extends StatefulWidget {
  const HierarchyScreen({super.key, required this.data});

  final GoldData data;

  @override
  State<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends State<HierarchyScreen> {
  final TextEditingController _search = TextEditingController();

  late final List<Rec> _eras;
  late final Map<int, List<Rec>> _byEra;
  late final Map<int, Rec> _view;
  late final Map<int, Rec> _rulers;
  late final Map<int, List<Rec>> _variants;
  late final Map<int, List<Rec>> _reigns;
  late final Map<int, List<Rec>> _examples;
  late final Map<int, String> _museumNames;

  /// every spelling of every ruler (museum names and the Wikidata name), prepared for the search
  late final Map<int, List<_Spelling>> _forms;

  /// the typed text prepared for matching, kept so that it is not prepared again for every row
  NameQuery _cachedQuery = NameQuery('');
  String _cachedFor = '';

  /// to bring the list of rulers or the detail into view when the window is narrow and the panels are stacked
  final GlobalKey _rulersKey = GlobalKey();
  final GlobalKey _detailKey = GlobalKey();
  bool _wide = true;

  String _museum = 'All';
  bool _linkedOnly = false;
  int _era = 7;
  int? _ruler;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _eras = List<Rec>.of(d.rows('dim_era'))
      ..sort((a, b) => toInt(a['sort_order']).compareTo(toInt(b['sort_order'])));
    _byEra = <int, List<Rec>>{};
    _view = <int, Rec>{};
    for (final r in d.rows('v_era_ruler')) {
      _byEra.putIfAbsent(toInt(r['era_key']), () => <Rec>[]).add(r);
      _view[toInt(r['ruler_key'])] = r;
    }
    _rulers = <int, Rec>{for (final r in d.rows('dim_ruler')) toInt(r['ruler_key']): r};
    _variants = _group(d.rows('ruler_name_variant'));
    _reigns = _group(d.rows('map_reign_to_ruler'));
    _examples = _group(d.rows('ruler_examples'));
    _museumNames = <int, String>{
      for (final m in d.rows('dim_museum')) toInt(m['museum_key']): toStr(m['museum_name']),
    };
    _forms = <int, List<_Spelling>>{};
    for (final r in _view.values) {
      final key = toInt(r['ruler_key']);
      final list = <_Spelling>[];
      final seen = <String>{};
      void add(dynamic value, String? museum) {
        final s = toStr(value).trim();
        if (s.isEmpty) return;
        if (!seen.add(foldName(s))) return; // the same spelling is kept once
        list.add(_Spelling(s, museum));
      }

      // the spellings of the museums first, so that the museum is known; then the Wikidata name and the name Gold chose
      for (final v in _variants[key] ?? const <Rec>[]) {
        add(v['name_text'], _museumNames[toInt(v['museum_key'])]);
      }
      add(_rulers[key]?['wikidata_label'], null);
      add(r['ruler_name'], null);
      _forms[key] = list;
    }
    if (!_byEra.containsKey(_era) && _eras.isNotEmpty) {
      _era = toInt(_eras.first['era_key']);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static Map<int, List<Rec>> _group(List<Rec> rows) {
    final out = <int, List<Rec>>{};
    for (final r in rows) {
      out.putIfAbsent(toInt(r['ruler_key']), () => <Rec>[]).add(r);
    }
    return out;
  }

  // ------------------------------------------------------------------------------------------
  // numbers under the current filters
  // ------------------------------------------------------------------------------------------

  int _count(Rec r) {
    switch (_museum) {
      case 'Met':
        return toInt(r['met_artifacts']);
      case 'Cleveland':
        return toInt(r['cleveland_artifacts']);
      case 'Louvre':
        return toInt(r['louvre_artifacts']);
      default:
        return toInt(r['artifacts']);
    }
  }

  bool _isPlaceholder(Rec r) => r['is_unspecified'] == true;

  bool _isLinked(Rec r) => !_isPlaceholder(r) && r['wikidata_qid'] != null;

  /// a ruler row is shown when it has artifacts of the chosen museum, and (if asked) is linked to Wikidata
  bool _passes(Rec r) {
    if (_count(r) <= 0) return false;
    if (_linkedOnly && !_isLinked(r)) return false;
    return true;
  }

  List<Rec> _rulersOf(int eraKey) {
    final rows = (_byEra[eraKey] ?? const <Rec>[]).where(_passes).toList();
    rows.sort((a, b) {
      final pa = _isPlaceholder(a) ? 1 : 0;
      final pb = _isPlaceholder(b) ? 1 : 0;
      if (pa != pb) return pa - pb;
      final c = _count(b).compareTo(_count(a));
      if (c != 0) return c;
      return _name(a).compareTo(_name(b));
    });
    return rows;
  }

  NameQuery get _nameQuery {
    if (_cachedFor != _query) {
      _cachedQuery = NameQuery(_query);
      _cachedFor = _query;
    }
    return _cachedQuery;
  }

  /// The other spellings of the ruler that match what was typed, with the museum that writes each one
  /// (for example: Also written: Louvre "Cléopâtre VII Philopator"). Null when no other spelling matches.
  String? _matchNote(Rec r) {
    final q = _nameQuery;
    final shown = foldName(_name(r));
    final notes = <String>[];
    for (final s in _forms[toInt(r['ruler_key'])] ?? const <_Spelling>[]) {
      if (!q.matches(s.form)) continue;
      if (foldName(s.text) == shown) continue;
      final museum = s.museum;
      notes.add(museum == null ? '"${s.text}"' : '$museum "${s.text}"');
    }
    if (notes.isEmpty) return null;
    return 'Also written: ${notes.take(2).join('; ')}';
  }

  /// The name shown for a ruler: the English name of Wikidata when the ruler is linked,
  /// otherwise the spelling of the museums (the Met spelling, else the Louvre one).
  String _name(Rec v) {
    if (_isPlaceholder(v)) return '(no ruler recorded)';
    if (_isLinked(v)) {
      final label = toStr(_rulers[toInt(v['ruler_key'])]?['wikidata_label']).trim();
      if (label.isNotEmpty) return label;
    }
    return toStr(v['ruler_name']);
  }

  /// The rulers (of all periods) one of whose spellings matches the search text.
  /// The match is loose: accents, double letters and vowels do not matter (see name_search.dart).
  List<Rec> _searchResults() {
    final q = _nameQuery;
    if (q.isEmpty) return <Rec>[];
    final out = <Rec>[];
    for (final r in _view.values) {
      if (_isPlaceholder(r) || !_passes(r)) continue;
      final forms = _forms[toInt(r['ruler_key'])] ?? const <_Spelling>[];
      if (forms.any((s) => q.matches(s.form))) out.add(r);
    }
    // names that begin with what was typed come first, then the rulers with more artifacts
    final typed = q.plain;
    int rank(Rec r) {
      if (typed.isEmpty) return 1;
      final forms = _forms[toInt(r['ruler_key'])] ?? const <_Spelling>[];
      return forms.any((s) => s.form.plain.startsWith(typed)) ? 0 : 1;
    }

    out.sort((a, b) {
      final c = rank(a).compareTo(rank(b));
      if (c != 0) return c;
      return _count(b).compareTo(_count(a));
    });
    return out;
  }

  Rec? _eraRec(int key) {
    for (final e in _eras) {
      if (toInt(e['era_key']) == key) return e;
    }
    return null;
  }

  Rec? _selectedRuler(List<Rec> listed) {
    final id = _ruler;
    if (id != null) {
      for (final r in listed) {
        if (toInt(r['ruler_key']) == id) return r;
      }
    }
    return listed.isEmpty ? null : listed.first;
  }

  static String _yr(int y) => y < 0 ? '${-y} BCE' : '$y CE';

  static String _years(Rec e) {
    final f = e['year_from'];
    final t = e['year_to'];
    if (f == null || t == null) return 'no date';
    final from = toInt(f);
    final to = toInt(t);
    if (from <= -100000000) return 'before ${_yr(to)}';
    if (to >= 100000000) return 'from ${_yr(from)}';
    final a = _yr(from);
    final b = _yr(to);
    if (from < 0 && to < 0) return '${a.replaceAll(' BCE', '')} to $b';
    return '$a to $b';
  }

  static Color _groupColor(String group) => AppColors.eraGroup(group);

  // ------------------------------------------------------------------------------------------
  // actions
  // ------------------------------------------------------------------------------------------

  /// On a narrow window the panels are stacked, so after a click the next panel is brought into view.
  void _bringIntoView(GlobalKey key) {
    if (_wide) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _pickEra(int era) {
    setState(() {
      _era = era;
      _ruler = null;
      _query = '';
      _search.clear();
    });
    _bringIntoView(_rulersKey);
  }

  void _pickRuler(Rec r) {
    setState(() {
      _era = toInt(r['era_key']);
      _ruler = toInt(r['ruler_key']);
    });
    _bringIntoView(_detailKey);
  }

  void _clear() {
    setState(() {
      _museum = 'All';
      _linkedOnly = false;
      _query = '';
      _search.clear();
      _ruler = null;
    });
  }

  // ------------------------------------------------------------------------------------------
  // the screen
  // ------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final listed = searching ? _searchResults() : _rulersOf(_era);
    final selected = _selectedRuler(listed);
    final eraRec = _eraRec(_era);

    return PageScaffold(
      title: 'Hierarchy: period, ruler, artifact',
      subtitle: 'The order of the snowflake. Choose a period, then a ruler, to see what the museums hold.',
      art: 'cartouche',
      children: <Widget>[
        const AboutBox(
          lines: <String>[
            'The Gold layer is a snowflake. The top level is the period (dim_era), the middle level is the ruler (dim_ruler, '
                'each ruler belongs to one period) and the bottom level is the artifact (fact_artifact). '
                'This screen follows that order: choose a period, then a ruler.',
            'A ruler is placed in the period where most of its dated artifacts fall.',
            'Every period has one placeholder ruler, "(no ruler recorded)", so the artifacts whose museum names no ruler stay in the hierarchy. '
                'Cleveland has no ruler field; its ruler is read from the Culture text, which names one for fewer than one artifact in ten, '
                'so most of its artifacts sit under the placeholder.',
            'A ruler is one row, identified by its Wikidata number and not by its name. Each museum spells the name its own way and Gold keeps every spelling, '
                'so the Met "Thutmose III" and the Louvre "Thoutmosis III" are the same ruler.',
            'The ruler is shown by its English name in Wikidata. A ruler that is not linked to Wikidata is shown by the spelling of the museums.',
            'The museum filter changes every count on the screen. The Wikidata filter keeps the rulers that are linked to Wikidata.',
            'The search box looks for a name in every spelling of every museum and in the Wikidata name. Accents, double letters and vowels do not matter, '
                'so "Ramses", "Ramesses" and "Ramsès" find the same ruler. A few well-known kings can also be searched by their Arabic name. '
                'Under each result, the other spellings that match are shown with the museum that writes them.',
            'The copy button at the top of the list of rulers puts the rulers on the list in the clipboard as a CSV table, '
                'with the counts of the museum filter now set.',
          ],
        ),
        const SizedBox(height: 18),
        _filterBar(searching),
        const SizedBox(height: 18),
        KeyFigures(items: _figures()),
        const SizedBox(height: 22),
        _path(eraRec, selected),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            // the lists are as tall as the window allows, so that many rows are visible without scrolling
            final window = MediaQuery.of(context).size.height;
            final listHeight = wide ? (window - 150).clamp(560.0, 900.0).toDouble() : 380.0;
            _wide = wide;
            final periods = _periodsPanel(listHeight);
            final rulers = KeyedSubtree(
              key: _rulersKey,
              child: _rulersPanel(listed, selected, eraRec, searching, listHeight),
            );
            final detail = KeyedSubtree(key: _detailKey, child: _detail(selected));
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 262, child: periods),
                  const SizedBox(width: 14),
                  SizedBox(width: 306, child: rulers),
                  const SizedBox(width: 14),
                  Expanded(child: detail),
                ],
              );
            }
            // narrow window: the panels are stacked; while searching, the results and the detail come first
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: searching
                  ? <Widget>[
                      rulers,
                      const SizedBox(height: 14),
                      detail,
                      const SizedBox(height: 14),
                      periods,
                    ]
                  : <Widget>[
                      periods,
                      const SizedBox(height: 14),
                      rulers,
                      const SizedBox(height: 14),
                      detail,
                    ],
            );
          },
        ),
      ],
    );
  }

  // ------------------------------------------------------------------------------------------
  // filters, key figures, path
  // ------------------------------------------------------------------------------------------

  Widget _filterBar(bool searching) {
    final active = _museum != 'All' || _linkedOnly || searching;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Wrap(
        spacing: 22,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Text('Museum', style: AppText.small),
              for (final m in _museumFilters)
                ChipButton(
                  label: m,
                  selected: _museum == m,
                  color: m == 'All' ? AppColors.lapis : AppColors.museum(m),
                  dot: m == 'All' ? null : AppColors.museum(m),
                  onTap: () => setState(() {
                    _museum = m;
                    _ruler = null;
                  }),
                ),
            ],
          ),
          ChipButton(
            label: 'Only rulers linked to Wikidata',
            selected: _linkedOnly,
            color: AppColors.lapis,
            icon: _linkedOnly ? Icons.check : null,
            onTap: () => setState(() {
              _linkedOnly = !_linkedOnly;
              _ruler = null;
            }),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() {
                _query = v;
                _ruler = null;
              }),
              style: AppText.body,
              decoration: InputDecoration(
                hintText: 'Find a ruler, in any spelling',
                hintStyle: AppText.small,
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.lapis, width: 1.6),
                ),
              ),
            ),
          ),
          if (active)
            TextButton(
              onPressed: _clear,
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }

  List<KeyFigure> _figures() {
    var named = 0;
    var linked = 0;
    var withRuler = 0;
    var without = 0;
    final eraSet = <int>{};
    for (final r in _view.values) {
      final c = _count(r);
      if (c <= 0) continue;
      eraSet.add(toInt(r['era_key']));
      if (_isPlaceholder(r)) {
        without += c;
      } else {
        named++;
        withRuler += c;
        if (_isLinked(r)) linked++;
      }
    }
    final total = withRuler + without;
    return <KeyFigure>[
      KeyFigure('Periods', '${eraSet.length}', caption: 'with artifacts, of ${_eras.length}'),
      KeyFigure('Rulers', fmtInt(named), caption: 'named, with artifacts'),
      KeyFigure(
        'Linked to Wikidata',
        fmtInt(linked),
        caption: named == 0 ? null : '${fmtPct(100.0 * linked / named)} of the rulers',
      ),
      KeyFigure(
        'Artifacts with a ruler',
        fmtInt(withRuler),
        caption: total == 0 ? null : '${fmtPct(100.0 * withRuler / total)} of the artifacts',
      ),
      KeyFigure(
        'Artifacts without a ruler',
        fmtInt(without),
        caption: 'under "no ruler recorded"',
      ),
      KeyFigure(
        'Artifacts',
        fmtInt(total),
        caption: _museum == 'All' ? 'all three museums' : 'the $_museum only',
        color: AppColors.goldDeep,
      ),
    ];
  }

  Widget _path(Rec? era, Rec? sel) {
    final eraName = era == null ? '-' : toStr(era['era_name']);
    final rulerName = sel == null ? '-' : _name(sel);
    final artifacts = sel == null ? '-' : fmtInt(_count(sel));
    Widget step(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: AppText.small),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
        ],
      );
    }

    const arrow = Icon(Icons.arrow_forward, size: 20, color: AppColors.goldDeep);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          step('Period', eraName),
          arrow,
          step('Ruler', rulerName),
          arrow,
          step('Artifacts', artifacts),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // the list of periods
  // ------------------------------------------------------------------------------------------

  Widget _panelHead(String title, Widget? trailing, String sub) {
    final extra = trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(title, style: AppText.h2)),
              if (extra != null) extra,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Text(sub, style: AppText.small),
        ),
        Container(height: 1, color: AppColors.line),
      ],
    );
  }

  Widget _periodsPanel(double listHeight) {
    final totals = <int, int>{};
    var maxCount = 1;
    for (final e in _eras) {
      final k = toInt(e['era_key']);
      var t = 0;
      for (final r in _byEra[k] ?? const <Rec>[]) {
        if (_passes(r)) t += _count(r);
      }
      totals[k] = t;
      if (t > maxCount) maxCount = t;
    }
    return Panel(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHead('Periods', null, 'Click a period to see its rulers.'),
          SizedBox(
            height: listHeight,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (final e in _eras)
                  _periodRow(e, totals[toInt(e['era_key'])] ?? 0, maxCount),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: <Widget>[
                for (final g in const <String>['Prehistoric', 'Pharaonic', 'Greco-Roman', 'Later'])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 9,
                        height: 9,
                        color: _groupColor(g == 'Later' ? 'Late Antique and later' : g),
                      ),
                      const SizedBox(width: 5),
                      Text(g, style: AppText.small),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodRow(Rec e, int count, int maxCount) {
    final key = toInt(e['era_key']);
    final selected = key == _era;
    final dim = count <= 0;
    final color = _groupColor(toStr(e['era_group']));
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.lapis.withAlpha(22) : null,
        border: Border(
          left: BorderSide(color: color, width: 4),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _pickEra(key),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        toStr(e['era_name']),
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 14.5,
                          height: 1.25,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: dim ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(fmtInt(count), style: AppText.value),
                  ],
                ),
                const SizedBox(height: 1),
                Text(_years(e), style: AppText.small),
                const SizedBox(height: 6),
                _bar(maxCount <= 0 ? 0 : count / maxCount, color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(double fraction, Color color) {
    final f = fraction < 0 ? 0.0 : (fraction > 1 ? 1.0 : fraction);
    return Container(
      height: 4,
      color: AppColors.track,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: f,
        child: Container(color: color),
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // the list of rulers
  // ------------------------------------------------------------------------------------------

  Widget _rulersPanel(List<Rec> listed, Rec? selected, Rec? era, bool searching, double listHeight) {
    var maxCount = 1;
    for (final r in listed) {
      final c = _count(r);
      if (c > maxCount) maxCount = c;
    }
    final selectedKey = selected == null ? -1 : toInt(selected['ruler_key']);
    final n = listed.length;
    final subtitle = searching
        ? 'In every period, for "${_query.trim()}". Accents, double letters and vowels do not matter.'
        : (era == null ? '' : '${toStr(era['era_name'])}, ${_years(era)}');
    final countLabel = searching ? '$n ${n == 1 ? 'result' : 'results'}' : '$n ${n == 1 ? 'ruler' : 'rulers'}';
    final String emptyText;
    if (searching) {
      emptyText = hasArabic(_query)
          ? 'No match. The Arabic search knows only well-known kings (Ramesses, Cleopatra, Ahmose, Thutmose, Hatshepsut, '
              'Akhenaten, Amenhotep, Ptolemy and a few more). Try the English name.'
          : 'No ruler matches "${_query.trim()}" with the filters now set. Try a shorter part of the name, '
              'or set the museum to All.';
    } else {
      emptyText = 'No ruler matches the filters here. Change the museum, the Wikidata filter or the search.';
    }
    return Panel(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHead(
            searching ? 'Search results' : 'Rulers',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Pill(countLabel, color: AppColors.lapis),
                if (n > 0)
                  IconButton(
                    tooltip: 'Copy this list as CSV',
                    onPressed: () => _copyCsv(listed),
                    icon: const Icon(Icons.copy, size: 18, color: AppColors.muted),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
            subtitle,
          ),
          SizedBox(
            height: listHeight,
            child: listed.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(emptyText, style: AppText.small),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      for (final r in listed)
                        _rulerRow(r, maxCount, toInt(r['ruler_key']) == selectedKey, searching),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _csvCell(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Copies the rulers now in the list as CSV, with the counts of the museum filter now set.
  void _copyCsv(List<Rec> rows) {
    final b = StringBuffer(
      'period,ruler,museum_spelling,wikidata_qid,artifacts,met_artifacts,cleveland_artifacts,louvre_artifacts\n',
    );
    for (final r in rows) {
      b.writeln(<String>[
        _csvCell(toStr(r['era_name'])),
        _csvCell(_name(r)),
        _csvCell(toStr(r['ruler_name'])),
        _csvCell(toStr(r['wikidata_qid'])),
        '${_count(r)}',
        '${toInt(r['met_artifacts'])}',
        '${toInt(r['cleveland_artifacts'])}',
        '${toInt(r['louvre_artifacts'])}',
      ].join(','));
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${rows.length} rulers as CSV')),
    );
  }

  Widget _rulerRow(Rec r, int maxCount, bool selected, bool showEra) {
    final placeholder = _isPlaceholder(r);
    final name = _name(r);
    final note = showEra ? _matchNote(r) : null;
    final qid = toStr(r['wikidata_qid']);
    final parts = <String>[];
    if (showEra) parts.add(toStr(r['era_name']));
    if (placeholder) {
      parts.add('names no ruler');
    } else if (qid.isNotEmpty) {
      parts.add('Wikidata $qid');
    } else {
      parts.add('not linked to Wikidata');
    }
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.lapis.withAlpha(22) : null,
        border: Border(
          left: BorderSide(color: selected ? AppColors.gold : Colors.transparent, width: 4),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _pickRuler(r),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 14.5,
                          fontStyle: placeholder ? FontStyle.italic : FontStyle.normal,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(fmtInt(_count(r)), style: AppText.value),
                  ],
                ),
                const SizedBox(height: 1),
                Text(parts.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small),
                if (note != null)
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.goldDeep,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 6),
                _museumBar(r, maxCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_Part> _parts(Rec r) {
    return <_Part>[
      _Part('Met', toInt(r['met_artifacts'])),
      _Part('Cleveland', toInt(r['cleveland_artifacts'])),
      _Part('Louvre', toInt(r['louvre_artifacts'])),
    ];
  }

  /// a bar whose length is the number of artifacts and whose colours are the museums
  Widget _museumBar(Rec r, int maxCount) {
    final parts = _parts(r).where((p) => (_museum == 'All' || p.museum == _museum) && p.count > 0).toList();
    var total = 0;
    for (final p in parts) {
      total += p.count;
    }
    if (total == 0 || maxCount <= 0) {
      return Container(height: 4, color: AppColors.track);
    }
    final f = total / maxCount;
    return Container(
      height: 4,
      color: AppColors.track,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: f > 1 ? 1.0 : f,
        child: SizedBox(
          height: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final p in parts)
                Expanded(
                  flex: p.count,
                  child: ColoredBox(color: AppColors.museum(p.museum)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // the detail of one ruler
  // ------------------------------------------------------------------------------------------

  Widget _detail(Rec? v) {
    if (v == null) {
      return const Panel(
        child: Text(
          'No ruler to show. Change the museum, the Wikidata filter or the search.',
          style: AppText.small,
        ),
      );
    }
    final key = toInt(v['ruler_key']);
    final placeholder = _isPlaceholder(v);
    final era = _eraRec(toInt(v['era_key']));
    final dim = _rulers[key] ?? <String, dynamic>{};
    final qid = toStr(v['wikidata_qid']);
    final total = toInt(v['artifacts']);

    final children = <Widget>[];

    // the name
    if (placeholder) {
      children.add(const Text('No ruler recorded', style: AppText.h2));
      children.add(const SizedBox(height: 8));
      children.add(
        const Text(
          'This is not a ruler. It is the place of the artifacts whose museum names no ruler: most Cleveland and Louvre artifacts name no ruler, '
          'and many Met artifacts have no reign text. So that these artifacts stay in the hierarchy, '
          'every period has one such row. An artifact without a ruler goes under the row of its own period (decided by its dates), '
          'or under Undated when it has no year.',
          style: AppText.body,
        ),
      );
    } else {
      children.add(
        Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Cartouche(
              child: Text(
                _name(v),
                style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.2,
                ),
              ),
            ),
            Pill(
              qid.isEmpty ? 'Not linked to Wikidata' : 'Wikidata $qid',
              color: qid.isEmpty ? AppColors.muted : AppColors.lapis,
            ),
          ],
        ),
      );
      if (qid.isNotEmpty) {
        children.add(const SizedBox(height: 12));
        children.add(_wikidataBlock(qid, toStr(dim['wikidata_description'])));
      } else {
        children.add(const SizedBox(height: 10));
        children.add(
          const Text(
            'The name this museum writes does not match any name that Wikidata gives to a ruler, so the ruler has no Wikidata number yet.',
            style: AppText.small,
          ),
        );
      }
    }

    // the facts
    children.add(const SizedBox(height: 18));
    children.add(LedgerRow(
      'Period',
      era == null ? '' : toStr(era['era_name']),
    ));
    children.add(LedgerRow('Artifacts', fmtInt(total)));
    if (!placeholder && v['era_share_pct'] != null) {
      final dated = toInt(dim['dated_artifacts']);
      children.add(LedgerRow(
        'Placed in this period',
        dated > 0
            ? '${fmtPct(toDouble(v['era_share_pct']))} of ${fmtInt(dated)} dated artifacts'
            : fmtPct(toDouble(v['era_share_pct'])),
      ));
    }
    if (v['average_score'] != null) {
      children.add(LedgerRow('Average documentation score', fmtScore(toDouble(v['average_score']))));
    }
    if (v['pct_with_site'] != null) {
      children.add(LedgerRow('With a find site', fmtPct(toDouble(v['pct_with_site']))));
    }
    if (v['pct_with_region'] != null) {
      children.add(LedgerRow('With a region', fmtPct(toDouble(v['pct_with_region']))));
    }
    if (v['pct_with_excavation'] != null) {
      children.add(LedgerRow('With an excavation', fmtPct(toDouble(v['pct_with_excavation']))));
    }

    // by museum
    children.add(_head('Artifacts by museum'));
    for (final p in _parts(v)) {
      children.add(_splitRow(p, total));
    }

    // the names
    final variants = List<Rec>.of(_variants[key] ?? const <Rec>[])
      ..sort((a, b) => toInt(a['museum_key']).compareTo(toInt(b['museum_key'])));
    if (variants.isNotEmpty) {
      children.add(_head('How each museum writes the name'));
      for (final n in variants) {
        children.add(_nameRow(
          _museumNames[toInt(n['museum_key'])] ?? 'Museum',
          toStr(n['name_text']),
          '${fmtInt(toInt(n['artifacts']))} ${toInt(n['artifacts']) == 1 ? 'artifact' : 'artifacts'}',
        ));
      }
      children.add(const SizedBox(height: 6));
      children.add(
        const Text(
          'One ruler is one row. The museums spell the name differently and Gold keeps every spelling.',
          style: AppText.caption,
        ),
      );
    }

    // the texts
    final reigns = _reigns[key] ?? const <Rec>[];
    if (reigns.isNotEmpty) {
      children.add(_head('Museum texts that point to this ruler'));
      final shown = reigns.length > 8 ? reigns.sublist(0, 8) : reigns;
      for (final t in shown) {
        children.add(_nameRow(
          _museumNames[toInt(t['museum_key'])] ?? 'Museum',
          toStr(t['reign_text']),
          toStr(t['match_type']),
        ));
      }
      if (reigns.length > shown.length) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('and ${reigns.length - shown.length} more texts', style: AppText.small),
        ));
      }
    }

    // examples
    final examples = _examples[key] ?? const <Rec>[];
    if (examples.isNotEmpty) {
      final rows = <Rec>[
        for (final e in examples)
          <String, dynamic>{
            'Museum': e['museum_name'],
            'Object number': e['object_number'],
            'Type': e['object_type'],
            'Title': e['title'],
            'Date text': e['date_text'],
            'Find site': e['has_site'] == true ? 'yes' : 'no',
            'Score': fmtScore(toDouble(e['documentation_score'])),
          },
      ];
      children.add(_head('Examples of artifacts'));
      children.add(
        TableViewer(
          columns: const <String>['Museum', 'Object number', 'Type', 'Title', 'Date text', 'Find site', 'Score'],
          rows: rows,
          height: 36.0 + 30.0 * rows.length + 22,
        ),
      );
      children.add(const SizedBox(height: 8));
      children.add(
        Text(
          'Up to two artifacts of each museum are shown. All ${fmtInt(total)} artifacts under this row are rows of fact_artifact with the same ruler_key.',
          style: AppText.caption,
        ),
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _head(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: AppText.h3),
    );
  }

  Widget _wikidataBlock(String qid, String description) {
    final url = 'https://www.wikidata.org/wiki/$qid';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (description.isNotEmpty) Text(description, style: AppText.small),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SelectableText(url, style: AppText.mono),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wikidata link copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy link'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _splitRow(_Part p, int total) {
    final color = AppColors.museum(p.museum);
    final f = total <= 0 ? 0.0 : p.count / total;
    final pct = total <= 0 ? 0.0 : 100.0 * p.count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Row(
              children: <Widget>[
                Container(width: 9, height: 9, color: color),
                const SizedBox(width: 7),
                Text(p.museum, style: AppText.body),
              ],
            ),
          ),
          Expanded(child: _bar(f, color)),
          const SizedBox(width: 12),
          SizedBox(
            width: 118,
            child: Text('${fmtInt(p.count)}  (${fmtPct(pct)})', style: AppText.small),
          ),
        ],
      ),
    );
  }

  Widget _nameRow(String museum, String text, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Row(
              children: <Widget>[
                Container(width: 9, height: 9, color: AppColors.museum(museum)),
                const SizedBox(width: 7),
                Text(museum, style: AppText.small),
              ],
            ),
          ),
          Expanded(child: Text(text, style: AppText.body)),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(note, style: AppText.small, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
