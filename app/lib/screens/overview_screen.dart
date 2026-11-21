import 'package:flutter/material.dart';

import '../brand.dart';
import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../medallion.dart';
import '../theme.dart';
import '../widgets.dart';

/// First screen: the title over the three strata, the size of Gold, the way from Bronze to Gold,
/// one record per museum, and where the documentation is missing.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.data, this.onOpen});

  final GoldData data;

  /// called with the number of a screen to open it (used by the button of the Gold layer in the flow)
  final ValueChanged<int>? onOpen;

  @override
  Widget build(BuildContext context) {
    final museums = data.rows('v_gap_by_museum');
    final dimMuseum = <int, Rec>{
      for (final m in data.rows('dim_museum')) toInt(m['museum_key']): m,
    };
    final eras = data.rows('dim_era');
    final rulers = data.rows('dim_ruler');
    final sites = data.rows('v_site_map');
    final gaps = data.rows('v_documentation_gap');
    final tables = data.rows('table_info');

    var totalArtifacts = 0;
    for (final m in museums) {
      totalArtifacts += toInt(m['artifacts']);
    }
    final periods = eras.where((e) => toStr(e['era_name']) != 'Undated').length;
    final named = rulers.where((r) => r['is_unspecified'] != true).toList();
    final linked = named.where((r) => r['is_linked'] == true).length;
    final withCoordinates = sites.where((s) => s['latitude'] != null).length;
    final museumNames = museums.map((m) => toStr(m['museum_name'])).join(', ');

    return PageScaffold(
      title: 'Gold layer overview',
      hero: const StrataHero(
        title: 'Egyptian Antiquities Provenance Lakehouse',
        lead: 'The Egyptian collections of three museums, unified, linked to Wikidata, '
            'and measured for what their records do not say.',
        tag: 'This site shows the Gold layer',
        art: 'sematawy',
        layers: <StrataLayer>[
          StrataLayer(
            name: 'Gold',
            text: 'Arranged for analysis: periods, rulers, sites and one row per artifact',
            fill: AppColors.goldLeaf,
            textColor: Color(0xFF2B2006),
          ),
          StrataLayer(
            name: 'Silver',
            text: 'Cleaned, with rulers linked to Wikidata',
            fill: AppColors.silver,
            textColor: Color(0xFF17202C),
          ),
          StrataLayer(
            name: 'Bronze',
            text: 'The museum files exactly as they were received',
            fill: AppColors.bronze,
            textColor: Color(0xFFF4ECDD),
          ),
        ],
      ),
      children: <Widget>[
        const SectionTitle(
          'The Gold layer at a glance',
          note: 'Every number on this site was read from the Gold tables and views, not typed by hand.',
        ),
        KeyFigures(
          items: <KeyFigure>[
            KeyFigure(
              'Artifacts',
              fmtInt(totalArtifacts),
              caption: 'one row each in fact_artifact',
              color: AppColors.goldDeep,
            ),
            KeyFigure(
              'Museums',
              '${museums.length}',
              caption: museumNames,
            ),
            KeyFigure(
              'Periods',
              '$periods',
              caption: 'plus one "Undated" period',
            ),
            KeyFigure(
              'Rulers',
              fmtInt(named.length),
              caption: '${fmtInt(linked)} linked to Wikidata',
            ),
            KeyFigure(
              'Sites',
              fmtInt(sites.length),
              caption: '${fmtInt(withCoordinates)} with coordinates',
            ),
            KeyFigure(
              'Gold objects',
              '${tables.length} + 7',
              caption: '${tables.length} tables and 7 views',
            ),
          ],
        ),
        const SizedBox(height: 22),
        const AboutBox(
          lines: <String>[
            'Click a layer in "From Bronze to Gold" to see what it holds and what was done to it. This site shows the last one, Gold.',
            'Every number in this app was read from the Gold tables and views of the database, not typed by hand.',
            'The three museums do not record the same fields (the Met has six measured fields, the Louvre three, Cleveland two), '
                'so compare the same field across museums rather than the average scores.',
          ],
        ),
        const SizedBox(height: 40),
        const SectionTitle(
          'From Bronze to Gold',
          note: 'The data passes through three layers. Click a layer to see what it holds and what was done to it.',
        ),
        MedallionFlow(data: data, onOpen: onOpen),
        const SizedBox(height: 40),
        const SectionTitle(
          'The three collections',
          note: 'One record per museum. The fields a museum records differ, so the scores are not directly comparable.',
        ),
        ResponsiveRow(
          children: <Widget>[
            for (final m in museums) _museumCard(m, dimMuseum[toInt(m['museum_key'])]),
          ],
        ),
        const SizedBox(height: 40),
        const SectionTitle('Where the documentation is missing'),
        Panel(
          caption: 'Figure 1. Share of each museum\'s artifacts whose record leaves the field empty. '
              'The hatched length is the share missing. A field a museum does not have at all is not counted.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final m in museums) ..._gapBlock(m, gaps),
            ],
          ),
        ),
      ],
    );
  }

  Widget _museumCard(Rec m, Rec? dim) {
    final name = toStr(m['museum_name']);
    final color = AppColors.museum(name);
    final fullName = dim == null ? '' : toStr(dim['museum_full_name']);
    final country = dim == null ? '' : toStr(dim['country']);
    final license = dim == null ? '' : toStr(dim['data_license']);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: color, width: 5),
          top: const BorderSide(color: AppColors.line),
          right: const BorderSide(color: AppColors.line),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(name, style: AppText.h2),
          const SizedBox(height: 2),
          Text(
            fullName.isEmpty ? country : '$fullName, $country',
            style: AppText.small,
          ),
          const SizedBox(height: 14),
          LedgerRow('Artifacts', fmtInt(toInt(m['artifacts']))),
          LedgerRow('Fields measured', '${toInt(m['fields_applicable'])}'),
          LedgerRow('Average score', fmtScore(toDouble(m['average_score']))),
          LedgerRow(
            'Fully documented',
            '${fmtPct(toDouble(m['fully_documented_pct']))}  (${fmtInt(toInt(m['fully_documented']))})',
          ),
          LedgerRow(
            'Nothing documented',
            '${fmtPct(toDouble(m['nothing_documented_pct']))}  (${fmtInt(toInt(m['nothing_documented']))})',
          ),
          LedgerRow('With open image', fmtInt(toInt(m['with_open_image']))),
          if (license.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Pill(license, color: color),
          ],
        ],
      ),
    );
  }

  /// 0.0% would hide a few missing records, so a tiny share is shown as "<0.1%".
  static String _share(double pct, int rows) {
    if (pct < 0.05 && rows > 0) return '<0.1%';
    return fmtPct(pct);
  }

  List<Widget> _gapBlock(Rec museum, List<Rec> gaps) {
    final key = toInt(museum['museum_key']);
    final name = toStr(museum['museum_name']);
    final color = AppColors.museum(name);
    final rows = gaps.where((g) => toInt(g['museum_key']) == key).toList();
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Row(
          children: <Widget>[
            Container(width: 10, height: 10, color: color),
            const SizedBox(width: 8),
            Text(name, style: AppText.h3),
          ],
        ),
      ),
      for (final g in rows)
        BarRow(
          label: fieldLabel(toStr(g['field_name'])),
          fraction: toDouble(g['missing_pct']) / 100,
          valueText: '${_share(toDouble(g['missing_pct']), toInt(g['missing_rows']))} missing, '
              '${fmtInt(toInt(g['missing_rows']))} of ${fmtInt(toInt(g['applicable_rows']))}',
          color: color,
          valueWidth: 230,
        ),
    ];
  }
}
