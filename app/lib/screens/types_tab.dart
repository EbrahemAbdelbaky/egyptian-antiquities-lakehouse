import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../data/name_search.dart';
import '../theme.dart';
import '../widgets.dart';

const List<String> _museums = <String>['Met', 'Cleveland', 'Louvre'];

/// A type with fewer artifacts than this has too few artifacts for its shares and scores to mean much.
const int _fewArtifacts = 30;

/// The list shows this many types at first, and this many more each time the button is pressed.
const int _pageSize = 40;

/// English words for the French terms the Louvre uses most. These are the project's own translations of the common
/// terms and are shown in italics under the French text. A type with several parts ("amulette ; perle") is translated
/// only when every part is in this list. Keys are lower case, with a straight apostrophe.
const Map<String, String> _glossary = <String, String>{
  'amulette': 'amulet',
  'amulette oudjat': 'wedjat-eye amulet',
  'papyrus': 'papyrus',
  'papyrus funéraire': 'funerary papyrus',
  'papyrus documentaire': 'documentary papyrus',
  'papyrus magique': 'magical papyrus',
  'figurine': 'figurine',
  'figurine féminine': 'female figurine',
  'figurine érotique': 'erotic figurine',
  "figurine d'osiris": 'figurine of Osiris',
  "figurine d'isis allaitant": 'figurine of Isis nursing',
  "figurine d'harpocrate": 'figurine of Harpocrates',
  "figurine de fils d'horus": 'figurine of the sons of Horus',
  'figurine de donateur': 'donor figurine',
  'enseigne divine': 'divine standard',
  'ostracon': 'ostracon',
  'ostracon figuré': 'figured ostracon (with a drawing)',
  'scarabée': 'scarab',
  'scarabée de cœur': 'heart scarab',
  'scarabée funéraire': 'funerary scarab',
  'scaraboïde': 'scaraboid',
  'stèle': 'stela',
  'stèle cintrée': 'round-topped stela',
  'stèle biface': 'two-sided stela',
  'stèle à un registre': 'one-register stela',
  'stèle à deux registres': 'two-register stela',
  'stèle à trois registres': 'three-register stela',
  'étiquette de momie': 'mummy label',
  'étiquette de momie biface': 'two-sided mummy label',
  'étiquette de momie en palette': 'palette-shaped mummy label',
  'étiquette de momie rectangulaire': 'rectangular mummy label',
  'bandelette de momie': 'mummy bandage',
  'masque de momie': 'mummy mask',
  'serviteur funéraire': 'funerary servant (ushabti)',
  'serviteur funéraire momiforme': 'mummiform funerary servant (ushabti)',
  'serviteur funéraire contremaître': 'overseer funerary servant (ushabti)',
  'cône funéraire': 'funerary cone',
  'vase': 'vase',
  'vase canope': 'canopic jar',
  'vase miniature': 'miniature vase',
  'couvercle de vase': 'vase lid',
  'couvercle de vase canope': 'canopic jar lid',
  'statue': 'statue',
  'statuette': 'statuette',
  'statue cube': 'block statue',
  'statue de ptah-sokar-osiris': 'statue of Ptah-Sokar-Osiris',
  'tétradrachme alexandrin': 'Alexandrian tetradrachm',
  'monnaie': 'coin',
  'jarre': 'jar',
  'bouchon de jarre': 'jar stopper',
  'empreinte de sceau': 'seal impression',
  'pot': 'pot',
  'coupe': 'cup',
  'coupelle': 'small cup',
  'flacon': 'flask',
  'bol': 'bowl',
  'bouteille': 'bottle',
  'cruche': 'jug',
  'gobelet': 'beaker',
  'assiette': 'plate',
  'alabastron': 'alabastron',
  'amphore': 'amphora',
  'lampe': 'lamp',
  'panier': 'basket',
  'couvercle de panier': 'basket lid',
  'tissu': 'textile',
  'linceul': 'shroud',
  'linceul peint': 'painted shroud',
  'sceau cylindre': 'cylinder seal',
  'sceau': 'seal',
  'modèle': 'model',
  'moule': 'mould',
  'moule à amulette': 'amulet mould',
  'moule à pain': 'bread mould',
  'pendentif': 'pendant',
  'perle': 'bead',
  'perles': 'beads',
  'plaquette': 'plaque',
  'dépôt de fondation': 'foundation deposit',
  'plaquette de dépôt de fondation': 'foundation-deposit plaque',
  'relief mural': 'wall relief',
  'bloc de paroi': 'wall block',
  'élément de cercueil': 'coffin element',
  'cercueil momiforme': 'mummiform coffin',
  'enveloppe de cartonnage': 'cartonnage case',
  'élément de faucille': 'sickle element',
  'élément de meuble': 'furniture element',
  'ciseau': 'chisel',
  'outil': 'tool',
  'poids': 'weight',
  'bague': 'ring',
  'sandale': 'sandal',
  'pointe de flèche': 'arrowhead',
  'flèche': 'arrow',
  'lame de silex': 'flint blade',
  'pseudo-momie': 'pseudo-mummy',
};

/// The English words for a type written in French, or null when they are not all known.
String? _glossOf(String type) {
  final clean = type.trim().toLowerCase().replaceAll('’', "'");
  String? words = _glossary[clean];
  if (words == null) {
    final pieces = clean.split(' ; ');
    if (pieces.length < 2) return null;
    final out = <String>[];
    for (final piece in pieces) {
      final g = _glossary[piece.trim()];
      if (g == null) return null;
      out.add(g);
    }
    words = out.join(' ; ');
  }
  // "papyrus", "figurine" and "ostracon" are the same word in French and in English: nothing to add
  return words.toLowerCase() == clean ? null : words;
}

/// One object type of one museum.
class _TypeRow {
  _TypeRow(this.type, this.artifacts, this.site, this.score, this.gloss)
      : folded = foldName('$type ${gloss ?? ''}');

  final String type;
  final int artifacts;

  /// share of its artifacts with a find site, 0 to 100
  final double site;

  /// average documentation score, 0 to 1
  final double score;

  /// the English words, for the French terms of the Louvre
  final String? gloss;

  /// the type and its gloss without accents or punctuation, for the search box
  final String folded;
}

/// What the objects are. Read from the Gold view v_gap_by_object_type: one row per museum and per type, with the number
/// of artifacts, the share with a find site and the average documentation score.
/// The museums are not merged: each one names its types in its own words.
class TypesTab extends StatefulWidget {
  const TypesTab({super.key, required this.data});

  final GoldData data;

  @override
  State<TypesTab> createState() => _TypesTabState();
}

class _TypesTabState extends State<TypesTab> {
  late final Map<String, List<_TypeRow>> _byMuseum;
  late final Map<String, int> _museumTotals;
  late final int _glossedTypes;
  late final int _glossedArtifacts;
  final TextEditingController _search = TextEditingController();

  String _museum = 'Met';
  bool _byScore = false;
  int _shown = _pageSize;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    // The Met writes some types twice, once with a stray space or a line break at the end ("Pendant" and "Pendant\r\n").
    // After trimming, the two rows are one type: their artifacts are added and their shares are averaged by artifacts.
    final merged = <String, Map<String, List<double>>>{};
    for (final r in d.rows('v_gap_by_object_type')) {
      final museum = toStr(r['museum_name']);
      final type = toStr(r['object_type']).trim();
      if (type.isEmpty) continue;
      final n = toInt(r['artifacts']).toDouble();
      final sums = merged.putIfAbsent(museum, () => <String, List<double>>{}).putIfAbsent(type, () => <double>[0, 0, 0]);
      sums[0] += n;
      sums[1] += toDouble(r['pct_with_site']) * n;
      sums[2] += toDouble(r['average_score']) * n;
    }
    final byMuseum = <String, List<_TypeRow>>{};
    var glossedTypes = 0;
    var glossedArtifacts = 0;
    merged.forEach((museum, types) {
      types.forEach((type, sums) {
        final n = sums[0];
        final gloss = museum == 'Louvre' ? _glossOf(type) : null;
        final row = _TypeRow(type, n.round(), n == 0 ? 0.0 : sums[1] / n, n == 0 ? 0.0 : sums[2] / n, gloss);
        byMuseum.putIfAbsent(museum, () => <_TypeRow>[]).add(row);
        if (gloss != null) {
          glossedTypes++;
          glossedArtifacts += row.artifacts;
        }
      });
    });
    for (final rows in byMuseum.values) {
      rows.sort((a, b) {
        final c = b.artifacts.compareTo(a.artifacts);
        return c != 0 ? c : a.type.compareTo(b.type);
      });
    }
    _byMuseum = byMuseum;
    _glossedTypes = glossedTypes;
    _glossedArtifacts = glossedArtifacts;
    _museumTotals = <String, int>{
      for (final r in d.rows('v_gap_by_museum')) toStr(r['museum_name']): toInt(r['artifacts']),
    };
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_TypeRow> _rows() => _byMuseum[_museum] ?? const <_TypeRow>[];

  List<_TypeRow> _visible() {
    final words = foldName(_search.text).split(' ').where((w) => w.isNotEmpty).toList();
    var list = _rows().toList();
    if (words.isNotEmpty) {
      list = list.where((r) => words.every((w) => r.folded.contains(w))).toList();
    }
    if (_byScore) {
      list = list.where((r) => r.artifacts >= _fewArtifacts).toList();
      list.sort((a, b) {
        var c = a.score.compareTo(b.score);
        if (c == 0) c = a.site.compareTo(b.site);
        if (c == 0) c = b.artifacts.compareTo(a.artifacts);
        return c;
      });
    }
    return list;
  }

  void _reset() => _shown = _pageSize;

  // ------------------------------------------------------------------------------------------
  // the tab
  // ------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    final visible = _visible();
    final shown = visible.length < _shown ? visible.length : _shown;
    final maxCount = rows.isEmpty ? 1 : rows.first.artifacts;
    final color = AppColors.museum(_museum);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MuseumFilter(
          options: _museums,
          selected: _museum,
          onChanged: (m) => setState(() {
            _museum = m;
            _reset();
          }),
        ),
        const SizedBox(height: 18),
        KeyFigures(items: _figures(rows)),
        const SizedBox(height: 22),
        Panel(
          title: 'Object types of the $_museum',
          caption: _caption(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SearchField(
                    controller: _search,
                    hint: _museum == 'Louvre' ? 'Find a type, in French or English' : 'Find a type',
                    onChanged: (_) => setState(_reset),
                  ),
                  ChipButton(
                    label: 'Most artifacts',
                    selected: !_byScore,
                    onTap: () => setState(() {
                      _byScore = false;
                      _reset();
                    }),
                  ),
                  ChipButton(
                    label: 'Lowest score (at least $_fewArtifacts artifacts)',
                    selected: _byScore,
                    onTap: () => setState(() {
                      _byScore = true;
                      _reset();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                visible.length == rows.length
                    ? '${fmtInt(rows.length)} types'
                    : '${fmtInt(visible.length)} of ${fmtInt(rows.length)} types',
                style: AppText.small,
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No type matches this search.', style: AppText.small),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 700;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (!narrow) const _HeaderLine(),
                        for (var i = 0; i < shown; i++)
                          _TypeLine(row: visible[i], maxCount: maxCount, color: color, narrow: narrow),
                      ],
                    );
                  },
                ),
              if (shown < visible.length) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    ChipButton(
                      label: 'Show ${visible.length - shown < _pageSize ? visible.length - shown : _pageSize} more',
                      selected: false,
                      onTap: () => setState(() => _shown += _pageSize),
                    ),
                    const SizedBox(width: 12),
                    Text('Showing ${fmtInt(shown)} of ${fmtInt(visible.length)}', style: AppText.small),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _caption() {
    final base = 'Each type is shown exactly as the museum wrote it, and the museums are not merged because they do not '
        'share a vocabulary. A score and a share in italics come from fewer than $_fewArtifacts artifacts.';
    if (_museum != 'Louvre') return base;
    final total = _rows().fold<int>(0, (a, r) => a + r.artifacts);
    final pct = total == 0 ? 0.0 : 100.0 * _glossedArtifacts / total;
    return '$base The English words in italics are this project\'s own translation of the common French terms. '
        'They cover ${fmtInt(_glossedTypes)} types and ${fmtPct(pct)} of the Louvre artifacts.';
  }

  List<KeyFigure> _figures(List<_TypeRow> rows) {
    var typed = 0;
    var few = 0;
    var fewArtifacts = 0;
    var single = 0;
    var top10 = 0;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      typed += r.artifacts;
      if (i < 10) top10 += r.artifacts;
      if (r.artifacts >= _fewArtifacts) {
        few++;
        fewArtifacts += r.artifacts;
      }
      if (r.artifacts == 1) single++;
    }
    final total = _museumTotals[_museum] ?? typed;
    final untyped = total - typed;
    final largest = rows.isEmpty ? null : rows.first;
    return <KeyFigure>[
      KeyFigure('Distinct types', fmtInt(rows.length), caption: 'as the museum writes them', color: AppColors.goldDeep),
      KeyFigure(
        'Artifacts with a type',
        fmtInt(typed),
        caption: untyped > 0 ? 'of ${fmtInt(total)}, ${fmtInt(untyped)} have no type' : 'of ${fmtInt(total)}',
      ),
      KeyFigure(
        'Largest type',
        largest == null ? '-' : fmtInt(largest.artifacts),
        caption: largest?.type,
      ),
      KeyFigure(
        'Top 10 types',
        typed == 0 ? '-' : fmtPct(100.0 * top10 / typed),
        caption: 'of the artifacts with a type',
      ),
      KeyFigure(
        'Types with $_fewArtifacts or more',
        fmtInt(few),
        caption: typed == 0 ? null : 'they hold ${fmtPct(100.0 * fewArtifacts / typed)} of the artifacts',
      ),
      KeyFigure(
        'Types with one artifact',
        fmtInt(single),
        caption: rows.isEmpty ? null : '${fmtPct(100.0 * single / rows.length)} of the types',
      ),
    ];
  }
}

const double _barWidth = 170;
const double _countWidth = 84;
const double _siteWidth = 104;
const double _scoreWidth = 64;

class _HeaderLine extends StatelessWidget {
  const _HeaderLine();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: kSans, fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.edge)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(child: Text('Type', style: style)),
          SizedBox(width: _barWidth + 12),
          SizedBox(width: _countWidth, child: Text('Artifacts', textAlign: TextAlign.right, style: style)),
          SizedBox(width: _siteWidth, child: Text('Find site', textAlign: TextAlign.right, style: style)),
          SizedBox(width: _scoreWidth, child: Text('Score', textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}

class _TypeLine extends StatelessWidget {
  const _TypeLine({required this.row, required this.maxCount, required this.color, required this.narrow});

  final _TypeRow row;
  final int maxCount;
  final Color color;
  final bool narrow;

  Widget _bar() {
    final f = maxCount <= 0 ? 0.0 : (row.artifacts / maxCount).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 10,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: AppColors.track),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: f,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    );
  }

  Widget _name() {
    final g = row.gloss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(row.type, style: AppText.body),
        if (g != null) Text(g, style: AppText.small.copyWith(fontStyle: FontStyle.italic, color: AppColors.goldDeep)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final few = row.artifacts < _fewArtifacts;
    final shareStyle = few
        ? AppText.cell.copyWith(fontStyle: FontStyle.italic, color: AppColors.muted)
        : AppText.cell;
    final site = fmtPct(row.site);
    final score = fmtScore(row.score);
    const border = BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line)),
    );
    if (narrow) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _name(),
            const SizedBox(height: 6),
            _bar(),
            const SizedBox(height: 4),
            Text(
              '${countOf(row.artifacts, 'artifact')}, $site with a find site, score $score',
              style: few ? AppText.small.copyWith(fontStyle: FontStyle.italic) : AppText.small,
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: _name()),
          SizedBox(width: _barWidth, child: _bar()),
          const SizedBox(width: 12),
          SizedBox(
            width: _countWidth,
            child: Text(fmtInt(row.artifacts), textAlign: TextAlign.right, style: AppText.cell),
          ),
          SizedBox(width: _siteWidth, child: Text(site, textAlign: TextAlign.right, style: shareStyle)),
          SizedBox(width: _scoreWidth, child: Text(score, textAlign: TextAlign.right, style: shareStyle)),
        ],
      ),
    );
  }
}
