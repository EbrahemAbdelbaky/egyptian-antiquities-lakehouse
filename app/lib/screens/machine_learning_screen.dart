import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../theme.dart';
import '../widgets.dart';

/// What each feature of the table is, in words. The names are the columns of ml_dataset.
const Map<String, String> _featureAbout = <String, String>{
  'era_name': 'The period that the artifact\'s dates fall in.',
  'mid_year': 'The middle of its begin year and end year (a negative year is BC).',
  'accession_year': 'The year the museum acquired it.',
  'object_name': 'The museum\'s name for the object, free text.',
  'object_type': 'The museum\'s type of object.',
  'medium': 'The material it is made of.',
  'dynasty_text': 'The dynasty, as the museum wrote it.',
  'period_text': 'The period, as the museum wrote it.',
  'ruler_name': 'The ruler named for the artifact, when there is one.',
};

/// One part of a bar that splits the rows of the table.
class _Seg {
  const _Seg(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

/// The table that Gold prepared for machine learning (ml_dataset): what it holds, how its rows are split, and the number
/// that any model has to beat. Read from ml_summary, ml_classes, ml_features and a sample of the table.
/// This screen does not train or run a model.
class MachineLearningScreen extends StatelessWidget {
  const MachineLearningScreen({super.key, required this.data});

  final GoldData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.one('ml_summary');
    final classes = data.rows('ml_classes');
    final features = data.rows('ml_features');
    final total = toInt(summary['total_rows']);
    final labeled = toInt(summary['labeled_rows']);
    final toPredict = toInt(summary['to_predict_rows']);

    // the most common class, and the most common named site
    Rec? top;
    Rec? topNamed;
    for (final c in classes) {
      if (top == null || toInt(c['rows_n']) > toInt(top['rows_n'])) top = c;
      if (toStr(c['target_site']) != 'Other' && (topNamed == null || toInt(c['rows_n']) > toInt(topNamed['rows_n']))) {
        topNamed = c;
      }
    }

    return PageScaffold(
      title: 'Machine learning',
      subtitle: 'The table that Gold prepared for machine learning, and the number a model has to beat.',
      art: 'ibis',
      children: <Widget>[
        const AboutBox(
          lines: <String>[
            'Besides the tables for analysis, Gold holds one table prepared for machine learning, ml_dataset, with one row for each core Met artifact.',
            'The task it prepares is to guess where an artifact was found. The answer to guess is the target site: one of the most common find sites, '
                'or "Other". Artifacts with a recorded find site are labeled. Artifacts without one are "to predict", and a guess for them would be a suggestion, '
                'never a recorded fact.',
            'This page shows what is in the table (rows, classes and features), how the labeled rows are split into training and test, '
                'and the accuracy of a model that always gives the most common answer. A real model has to beat that number.',
            'This site does not train or run a model. Gold only prepares the table, so no accuracy of a trained model appears here.',
            'The numbers come from the Gold table ml_dataset, through the summaries ml_summary, ml_classes and ml_features and a sample of its first rows.',
          ],
        ),
        const SizedBox(height: 18),
        KeyFigures(
          items: <KeyFigure>[
            KeyFigure('Rows', fmtInt(total), caption: 'one per core Met artifact', color: AppColors.goldDeep),
            KeyFigure(
              'Labeled',
              fmtInt(labeled),
              caption: total == 0 ? null : '${fmtPct(100.0 * labeled / total)} have a find site',
            ),
            KeyFigure(
              'To predict',
              fmtInt(toPredict),
              caption: total == 0 ? null : '${fmtPct(100.0 * toPredict / total)} have none',
              color: AppColors.violet,
            ),
            KeyFigure(
              'Classes',
              fmtInt(classes.length),
              caption: classes.isEmpty ? null : '${fmtInt(classes.length - 1)} named sites and Other',
            ),
            KeyFigure('Features', fmtInt(features.length), caption: 'columns used to guess the site'),
            KeyFigure(
              'Number to beat',
              top == null ? '-' : fmtPct(toDouble(top['pct'])),
              caption: top == null ? null : 'always answering "${toStr(top['target_site'])}"',
              color: AppColors.carnelian,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _splitPanel(summary, total, labeled, toPredict),
        const SizedBox(height: 18),
        _classesPanel(classes, top, topNamed),
        const SizedBox(height: 18),
        _featuresPanel(features),
        const SizedBox(height: 18),
        _samplePanel(),
      ],
    );
  }

  // ------------------------------------------------------------------------------------------
  // how the rows are used
  // ------------------------------------------------------------------------------------------

  Widget _splitPanel(Rec s, int total, int labeled, int toPredict) {
    final randomTrain = toInt(s['random_train']);
    final randomTest = toInt(s['random_test']);
    final acqTrain = toInt(s['acquisition_train']);
    final acqTest = toInt(s['acquisition_test']);
    final noYear = toInt(s['labeled_without_acquisition_year']);
    final fromYear = toInt(s['acquisition_test_from_year']);
    return Panel(
      title: 'How the rows are used',
      caption: 'Two ways to hold out a test set from the labeled rows. In a random split, near twins of an artifact (the same dig, the same year, '
          'the same kind of object) can sit in both the training and the test part. In the split by acquisition year, the older acquisitions '
          'train the model and the newer ones, from $fromYear on, test it, so the test looks like artifacts the model has not seen.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SplitBar(
            title: 'Random split',
            total: total,
            segments: <_Seg>[
              _Seg('Training', randomTrain, AppColors.lapis),
              _Seg('Test', randomTest, AppColors.goldLeaf),
              _Seg('To predict', toPredict, AppColors.violet),
            ],
          ),
          const SizedBox(height: 22),
          _SplitBar(
            title: 'Split by acquisition year',
            total: total,
            segments: <_Seg>[
              _Seg('Training', acqTrain, AppColors.lapis),
              _Seg('Test', acqTest, AppColors.goldLeaf),
              _Seg('No acquisition year', noYear, AppColors.silver),
              _Seg('To predict', toPredict, AppColors.violet),
            ],
          ),
          if (labeled > 0 && randomTrain + randomTest != labeled) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'The random parts add up to ${fmtInt(randomTrain + randomTest)}, not ${fmtInt(labeled)}.',
              style: AppText.small.copyWith(color: AppColors.carnelian),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // the classes
  // ------------------------------------------------------------------------------------------

  Widget _classesPanel(List<Rec> classes, Rec? top, Rec? topNamed) {
    var maxPct = 0.0;
    for (final c in classes) {
      final p = toDouble(c['pct']);
      if (p > maxPct) maxPct = p;
    }
    return Panel(
      title: 'The answer to guess',
      caption: 'The labeled artifacts by target site. The bar is as long as the share of the largest class. '
          'A model that always gave the most common answer would be right for about the share of that class.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (classes.isEmpty)
            const Text('No classes in the export.', style: AppText.small)
          else
            for (final c in classes)
              BarRow(
                label: toStr(c['target_site']),
                fraction: maxPct <= 0 ? 0.0 : toDouble(c['pct']) / maxPct,
                valueText: '${fmtInt(toInt(c['rows_n']))} artifacts, ${fmtPct(toDouble(c['pct']))}',
                color: toStr(c['target_site']) == 'Other' ? AppColors.silver : AppColors.lapis,
                labelWidth: 170,
                valueWidth: 200,
              ),
          if (top != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(width: double.infinity, height: 1, color: AppColors.line),
            const SizedBox(height: 12),
            LedgerRow('Most common class', '${toStr(top['target_site'])}, ${fmtPct(toDouble(top['pct']))}'),
            if (topNamed != null && toStr(topNamed['target_site']) != toStr(top['target_site']))
              LedgerRow('Most common named site', '${toStr(topNamed['target_site'])}, ${fmtPct(toDouble(topNamed['pct']))}'),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // the features
  // ------------------------------------------------------------------------------------------

  Widget _featuresPanel(List<Rec> features) {
    return Panel(
      title: 'What the model may look at',
      caption: 'How often each feature is filled. The artifacts to predict are documented less than the labeled ones, so a model tested on the '
          'labeled rows will probably look better than it will be on the rows it is meant for.',
      child: features.isEmpty
          ? const Text('No features in the export.', style: AppText.small)
          : LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 700;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!narrow) const _FeatureHeader(),
                    for (final f in features)
                      _FeatureLine(
                        name: toStr(f['feature']),
                        about: _featureAbout[toStr(f['feature'])] ?? '',
                        labeled: toDouble(f['filled_pct_labeled']),
                        toPredict: toDouble(f['filled_pct_to_predict']),
                        narrow: narrow,
                      ),
                  ],
                );
              },
            ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // a sample of the table
  // ------------------------------------------------------------------------------------------

  Widget _samplePanel() {
    final rows = data.rows('sample_ml_dataset');
    if (rows.isEmpty) return const SizedBox.shrink();
    final columns = rows.first.keys.toList();
    final predictRows = rows.where((r) => toStr(r['row_role']) == 'to_predict').length;
    return Panel(
      title: 'The first rows of the table',
      caption: 'The first ${fmtInt(rows.length)} rows of ml_dataset, in the order of the artifact number. '
          '${fmtInt(predictRows)} of them are "to_predict", so their label columns are empty. '
          'label_site_text and target_site are the answer; they are not features.',
      child: TableViewer(columns: columns, rows: rows, height: 320),
    );
  }
}

/// A bar that is split into parts, with a legend that gives the size and the share of each part.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.title, required this.segments, required this.total});

  final String title;
  final List<_Seg> segments;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppText.value),
        const SizedBox(height: 8),
        SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final s in segments)
                if (s.value > 0)
                  Expanded(
                    flex: s.value,
                    child: Container(margin: const EdgeInsets.only(right: 2), color: s.color),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          runSpacing: 4,
          children: <Widget>[
            for (final s in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(width: 10, height: 10, color: s.color),
                  const SizedBox(width: 6),
                  Text(
                    '${s.label} ${fmtInt(s.value)}${total == 0 ? '' : ' (${fmtPct(100.0 * s.value / total)})'}',
                    style: AppText.small,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

const double _fillWidth = 150;
const double _gapWidth = 90;

class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader();

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
          Expanded(child: Text('Feature', style: style)),
          SizedBox(width: _fillWidth + 14, child: Text('Filled, labeled rows', style: style)),
          SizedBox(width: _fillWidth + 14, child: Text('Filled, rows to predict', style: style)),
          SizedBox(width: _gapWidth - 14, child: Text('Difference', textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.name,
    required this.about,
    required this.labeled,
    required this.toPredict,
    required this.narrow,
  });

  final String name;
  final String about;
  final double labeled;
  final double toPredict;
  final bool narrow;

  Widget _bar(double pct, Color color) {
    final f = (pct / 100).clamp(0.0, 1.0).toDouble();
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

  Widget _fill(double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _bar(pct, color),
        const SizedBox(height: 3),
        Text(fmtPct(pct), style: AppText.cell),
      ],
    );
  }

  Widget _name() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(name, style: AppText.mono),
        if (about.isNotEmpty) Text(about, style: AppText.small),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = toPredict - labeled;
    final gapText = '${gap >= 0 ? '+' : '-'}${gap.abs().toStringAsFixed(1)} points';
    final gapStyle = gap <= -10
        ? AppText.cell.copyWith(color: AppColors.carnelian, fontWeight: FontWeight.w700)
        : AppText.cell.copyWith(color: AppColors.muted);
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
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Labeled rows', style: AppText.small),
                      const SizedBox(height: 3),
                      _fill(labeled, AppColors.lapis),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Rows to predict', style: AppText.small),
                      const SizedBox(height: 3),
                      _fill(toPredict, AppColors.violet),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Difference $gapText', style: gapStyle),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: _name()),
          SizedBox(width: _fillWidth, child: _fill(labeled, AppColors.lapis)),
          const SizedBox(width: 14),
          SizedBox(width: _fillWidth, child: _fill(toPredict, AppColors.violet)),
          const SizedBox(width: 14),
          SizedBox(width: _gapWidth - 14, child: Text(gapText, textAlign: TextAlign.right, style: gapStyle)),
        ],
      ),
    );
  }
}
