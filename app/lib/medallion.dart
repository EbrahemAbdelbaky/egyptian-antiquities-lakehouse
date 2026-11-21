import 'package:flutter/material.dart';

import 'art.dart';
import 'data/fmt.dart';
import 'data/gold_data.dart';
import 'theme.dart';
import 'widgets.dart';

class _LayerInfo {
  const _LayerInfo(this.name, this.role, this.color);

  final String name;
  final String role;
  final Color color;
}

const List<_LayerInfo> _layers = <_LayerInfo>[
  _LayerInfo('Bronze', 'The museum files as they came', AppColors.bronze),
  _LayerInfo('Silver', 'Cleaned, and linked to Wikidata', Color(0xFF8793A0)),
  _LayerInfo('Gold', 'Arranged for analysis', AppColors.goldLeaf),
];

/// The medallion architecture as a flow: Bronze, then Silver, then Gold. Click a layer to see what it holds
/// and what was done to it. The Gold figures are read from the data; the Bronze and Silver ones come from the
/// reports of those two layers.
class MedallionFlow extends StatefulWidget {
  const MedallionFlow({super.key, required this.data, this.onOpen});

  final GoldData data;

  /// called with the number of a screen of the app to open it
  final ValueChanged<int>? onOpen;

  @override
  State<MedallionFlow> createState() => _MedallionFlowState();
}

class _MedallionFlowState extends State<MedallionFlow> {
  int _selected = 2;

  @override
  Widget build(BuildContext context) {
    final tables = widget.data.rows('table_info').length;
    final stats = <String>[
      'Egyptian rows only',
      '20 tables',
      '$tables tables and 7 views',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final cards = <Widget>[
              for (var i = 0; i < _layers.length; i++) _stepCard(i, stats[i]),
            ];
            if (wide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: cards[0]),
                    _arrow(Icons.arrow_forward),
                    Expanded(child: cards[1]),
                    _arrow(Icons.arrow_forward),
                    Expanded(child: cards[2]),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                cards[0],
                _arrow(Icons.arrow_downward),
                cards[1],
                _arrow(Icons.arrow_downward),
                cards[2],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey<int>(_selected),
            child: _detail(_selected),
          ),
        ),
      ],
    );
  }

  Widget _arrow(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Center(child: Icon(icon, size: 28, color: AppColors.goldDeep)),
    );
  }

  Widget _stepCard(int i, String stat) {
    final l = _layers[i];
    final selected = i == _selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected ? l.color.withAlpha(30) : AppColors.surface,
            border: Border.all(
              color: selected ? l.color : AppColors.line,
              width: selected ? 2.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 8, color: l.color),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l.name,
                      style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(l.role, style: AppText.small),
                    const SizedBox(height: 10),
                    Text(
                      stat,
                      style: const TextStyle(
                        fontFamily: kSans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(int i) {
    final data = widget.data;
    final tables = data.rows('table_info').length;
    var artifacts = 0;
    for (final m in data.rows('v_gap_by_museum')) {
      artifacts += toInt(m['artifacts']);
    }
    final checksRun = toInt(data.checks['checks_run']);
    final checksOk = toInt(data.checks['checks_ok']);

    // the find sites: how many pieces with a site text have a site linked to Wikidata (counted on the Gold site table, like the Find sites tab)
    var metSite = 0, metLinked = 0, louSite = 0, louLinked = 0, cleSite = 0;
    for (final s in data.rows('v_site_map')) {
      final linked = toStr(s['wikidata_qid']).isNotEmpty;
      final met = toInt(s['met_artifacts']);
      final lou = toInt(s['louvre_artifacts']);
      metSite += met;
      louSite += lou;
      cleSite += toInt(s['cleveland_artifacts']);
      if (linked) {
        metLinked += met;
        louLinked += lou;
      }
    }
    String share(int a, int b) => b == 0 ? '0%' : fmtPct(100.0 * a / b);

    late final String title;
    late final List<String> holds;
    late final List<String> done;
    String? footer;
    switch (i) {
      case 0:
        title = 'Bronze: the museum files as they came';
        holds = <String>[
          'The Egyptian rows of the three museum files (Met, Cleveland, Louvre), with their original values.',
          'The original files stay untouched on disk, as the raw archive.',
        ];
        done = <String>[
          'Only the Egyptian rows are loaded into SQL Server.',
          'No value is changed. Nothing is cleaned, converted or merged here; that is the work of Silver.',
        ];
        footer = 'Because Bronze is never changed, Silver can always be rebuilt from it.';
        break;
      case 1:
        title = 'Silver: cleaned and linked';
        holds = <String>[
          '20 tables: the museum records with clean values and proper types, the links from the records to Wikidata rulers and places, and the small tables of hand-checked corrections.',
        ];
        done = <String>[
          'Values are cleaned and put in proper types.',
          'Ruler names are linked to Wikidata. Met: 99.7% of the pieces with a reign text (11,429 of 11,459). '
              'Louvre: 4,889 pieces, 15.7% of the 31,117 whose text names a period or a ruler; most of the others name a period only. '
              'Cleveland has no ruler field, so the ruler is read from the Culture text: 134 pieces name one and 120 of them are linked.',
          'Where the automatic match failed, the name was checked by hand against Wikidata: 120 Met, 226 Louvre and 10 Cleveland pieces carry such a correction. '
              'A reign text that fits several rulers is left unlinked.',
          'Find places are linked to Wikidata sites with coordinates: Met ${share(metLinked, metSite)} of the pieces that have a Subregion, '
              'Louvre ${share(louLinked, louSite)} of those that have a place name. The Louvre writes its names in French, so they are compared without accents, '
              'and a short list of corrections made by hand covers the names that Wikidata spells differently. '
              'Cleveland records a find spot for only ${fmtInt(cleSite)} pieces.',
          'Checks C1 to C9 all passed, including that each Silver table has as many rows as its Bronze table.',
        ];
        footer = 'The ruler figures come from the report of the Silver layer; the figures for find places are counted on the Gold site table.';
        break;
      default:
        title = 'Gold: ready for analysis';
        holds = <String>[
          '$tables tables and 7 views: periods, rulers, sites and museums as dimensions, one fact table with ${fmtInt(artifacts)} artifacts, and one table for machine learning.',
        ];
        done = <String>[
          'Arranged as a snowflake: period, then ruler, then artifact.',
          'Each ruler is linked across the museums by its Wikidata number, and each museum keeps its own spelling of the name.',
          'Every artifact has a documentation score: how many of its fields the museum filled in.',
          '$checksOk of $checksRun Gold checks passed.',
        ];
        footer = null;
        break;
    }

    final note = footer;
    final onOpen = widget.onOpen;
    return Panel(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveRow(
            stretch: false,
            breakpoint: 760,
            gap: 28,
            children: <Widget>[
              _block('What it holds', holds),
              _block('What was done to it', done),
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(note, style: AppText.caption),
          ],
          if (i == 2 && onOpen != null) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => onOpen(1),
                  icon: const ArtMark('djed', width: 18, color: AppColors.lapis),
                  label: const Text('Open the structure of Gold'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lapis,
                    side: const BorderSide(color: AppColors.lapis),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    textStyle: const TextStyle(fontFamily: kSans, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _block(String heading, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(heading, style: AppText.h3),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 5, right: 10),
                  child: ArtMark('ankh', width: 14, color: AppColors.goldDeep),
                ),
                Expanded(child: Text(line, style: AppText.body)),
              ],
            ),
          ),
      ],
    );
  }
}
