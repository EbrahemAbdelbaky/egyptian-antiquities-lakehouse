import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../theme.dart';
import '../widgets.dart';

const List<String> _order = <String>['Met', 'Cleveland', 'Louvre'];

/// A decade with fewer artifacts than this is drawn as a hollow point.
const int _fewArtifacts = 30;

const double _left = 52;
const double _right = 10;
const double _top = 8;
const double _bottom = 28;

/// One museum in one decade: the weighted averages of the years of that decade.
class _DecadePoint {
  const _DecadePoint(this.artifacts, this.score, this.site);

  final int artifacts;

  /// average documentation score, 0 to 1
  final double score;

  /// share of the artifacts with a find site, 0 to 100
  final double site;
}

/// The year in which each artifact entered the museum (accession year), and how well documented it is.
/// Read from the Gold view v_gap_by_accession_year. The Louvre has no accession year in Gold.
class TimeTab extends StatefulWidget {
  const TimeTab({super.key, required this.data});

  final GoldData data;

  @override
  State<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<TimeTab> {
  late final Map<String, Map<int, Rec>> _years;
  late final List<String> _present;
  late final Map<String, int> _museumTotals;
  late final Map<String, Map<int, _DecadePoint>> _decadeData;
  late final int _firstYear;
  late final int _lastYear;
  late final int _firstDecade;
  late final int _lastDecade;

  String _museum = 'All';
  bool _scoreMetric = true;
  int? _hoverYear;
  int? _hoverDecade;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _years = <String, Map<int, Rec>>{};
    var first = 100000;
    var last = 0;
    for (final r in d.rows('v_gap_by_accession_year')) {
      final y = r['accession_year'];
      if (y == null) continue;
      final year = toInt(y);
      _years.putIfAbsent(toStr(r['museum_name']), () => <int, Rec>{})[year] = r;
      if (year < first) first = year;
      if (year > last) last = year;
    }
    _firstYear = first;
    _lastYear = last;
    _present = <String>[
      for (final m in _order)
        if (_years.containsKey(m)) m,
    ];
    _museumTotals = <String, int>{
      for (final r in d.rows('v_gap_by_museum')) toStr(r['museum_name']): toInt(r['artifacts']),
    };
    _decadeData = <String, Map<int, _DecadePoint>>{
      for (final m in _present) m: _decadesOf(m),
    };
    _firstDecade = (first ~/ 10) * 10;
    _lastDecade = (last ~/ 10) * 10;
  }

  Map<int, _DecadePoint> _decadesOf(String museum) {
    final rows = _years[museum];
    if (rows == null) return <int, _DecadePoint>{};
    final sums = <int, List<double>>{};
    rows.forEach((year, r) {
      final dec = (year ~/ 10) * 10;
      final n = toInt(r['artifacts']).toDouble();
      final s = sums.putIfAbsent(dec, () => <double>[0, 0, 0]);
      s[0] += n;
      s[1] += toDouble(r['average_score']) * n;
      s[2] += toDouble(r['pct_with_site']) * n;
    });
    final out = <int, _DecadePoint>{};
    sums.forEach((dec, s) {
      if (s[0] > 0) out[dec] = _DecadePoint(s[0].round(), s[1] / s[0], s[2] / s[0]);
    });
    return out;
  }

  List<String> _chosen() => _museum == 'All' ? _present : <String>[_museum];

  int _yearTotal(int year) {
    var t = 0;
    for (final m in _chosen()) {
      t += toInt(_years[m]?[year]?['artifacts']);
    }
    return t;
  }

  // ------------------------------------------------------------------------------------------
  // the screen
  // ------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_present.isEmpty) {
      return const Panel(child: Text('No accession years in the export.', style: AppText.small));
    }
    final chosen = _chosen();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MuseumFilter(
          options: <String>['All', ..._present],
          selected: _museum,
          onChanged: (m) => setState(() {
            _museum = m;
            _hoverYear = null;
            _hoverDecade = null;
          }),
        ),
        const SizedBox(height: 18),
        KeyFigures(items: _figures()),
        const SizedBox(height: 22),
        Panel(
          title: 'Artifacts by year of accession',
          caption: 'Each bar is one year. Its height is the number of artifacts that entered the museum that year. '
              'The Louvre has no accession year in Gold, so only the Met and Cleveland are shown.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _legend(chosen),
              const SizedBox(height: 8),
              _readout(_yearReadout(chosen)),
              const SizedBox(height: 6),
              _yearChart(chosen),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Documentation by decade of accession',
          caption: 'The average of the artifacts accessioned in each decade, weighted by their number. '
              'A hollow point is a decade with fewer than $_fewArtifacts artifacts. '
              'The Cleveland score stays near 0.5: it counts two fields, and the date is always filled.',
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
              const SizedBox(height: 12),
              _legend(chosen),
              const SizedBox(height: 8),
              _readout(_decadeReadout(chosen)),
              const SizedBox(height: 6),
              _decadeChart(chosen),
            ],
          ),
        ),
      ],
    );
  }

  List<KeyFigure> _figures() {
    var total = 0;
    var upTo1930 = 0;
    var peakYear = 0;
    var peakCount = 0;
    var first = 0;
    var last = 0;
    var weighted = 0.0;
    for (var y = _firstYear; y <= _lastYear; y++) {
      final n = _yearTotal(y);
      if (n <= 0) continue;
      total += n;
      if (y <= 1930) upTo1930 += n;
      if (n > peakCount) {
        peakCount = n;
        peakYear = y;
      }
      if (first == 0) first = y;
      last = y;
      for (final m in _chosen()) {
        final r = _years[m]?[y];
        if (r != null) weighted += toDouble(r['average_score']) * toInt(r['artifacts']);
      }
    }
    var all = 0;
    for (final m in _museum == 'All' ? _present : <String>[_museum]) {
      all += _museumTotals[m] ?? 0;
    }
    String dash(String v) => total == 0 ? '-' : v;
    return <KeyFigure>[
      KeyFigure(
        'Artifacts with a year',
        fmtInt(total),
        caption: 'of ${fmtInt(all)}${_museum == 'All' ? ' (the Louvre has no year)' : ''}',
        color: AppColors.goldDeep,
      ),
      KeyFigure('First year', dash('$first')),
      KeyFigure('Last year', dash('$last')),
      KeyFigure('Peak year', dash('$peakYear'), caption: total == 0 ? null : '${fmtInt(peakCount)} artifacts'),
      KeyFigure(
        'Accessioned up to 1930',
        total == 0 ? '-' : fmtPct(100.0 * upTo1930 / total),
        caption: '${fmtInt(upTo1930)} artifacts',
      ),
      KeyFigure(
        'Average score',
        total == 0 ? '-' : fmtScore(weighted / total),
        caption: 'of the artifacts with a year',
      ),
    ];
  }

  Widget _legend(List<String> chosen) {
    return Wrap(
      spacing: 18,
      runSpacing: 4,
      children: <Widget>[
        for (final m in chosen)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(width: 10, height: 10, color: AppColors.museum(m)),
              const SizedBox(width: 6),
              Text(m, style: AppText.small),
            ],
          ),
      ],
    );
  }

  Widget _readout(String text) {
    return SizedBox(
      height: 24,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // chart 1: artifacts by year
  // ------------------------------------------------------------------------------------------

  String _yearReadout(List<String> chosen) {
    final y = _hoverYear;
    if (y == null) return 'Move the mouse over the chart, or tap it, to read a year.';
    final parts = <String>[];
    for (final m in chosen) {
      parts.add('$m ${fmtInt(toInt(_years[m]?[y]?['artifacts']))}');
    }
    return '$y: ${parts.join(', ')}';
  }

  Widget _yearChart(List<String> chosen) {
    final n = _lastYear - _firstYear + 1;
    final series = <List<int>>[
      for (final m in chosen)
        <int>[
          for (var y = _firstYear; y <= _lastYear; y++) toInt(_years[m]?[y]?['artifacts']),
        ],
    ];
    final colors = <Color>[for (final m in chosen) AppColors.museum(m)];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final plotW = w - _left - _right;
        void hoverAt(double dx) {
          final i = ((dx - _left) / (plotW / n)).floor();
          setState(() => _hoverYear = (i < 0 || i >= n) ? null : _firstYear + i);
        }

        return MouseRegion(
          onHover: (e) => hoverAt(e.localPosition.dx),
          onExit: (_) => setState(() => _hoverYear = null),
          child: GestureDetector(
            onTapDown: (d) => hoverAt(d.localPosition.dx),
            child: CustomPaint(
              size: Size(w, 280),
              painter: _YearBarsPainter(
                first: _firstYear,
                last: _lastYear,
                series: series,
                colors: colors,
                hover: _hoverYear,
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------------------------------
  // chart 2: documentation by decade
  // ------------------------------------------------------------------------------------------

  String _decadeReadout(List<String> chosen) {
    final dec = _hoverDecade;
    if (dec == null) return 'Move the mouse over the chart, or tap it, to read a decade.';
    final parts = <String>[];
    for (final m in chosen) {
      final p = _decadeData[m]?[dec];
      if (p == null) continue;
      final value = _scoreMetric ? fmtScore(p.score) : fmtPct(p.site);
      parts.add('$m $value (${fmtInt(p.artifacts)} artifacts)');
    }
    if (parts.isEmpty) return '${dec}s: no artifacts';
    return '${dec}s: ${parts.join(', ')}';
  }

  Widget _decadeChart(List<String> chosen) {
    final count = (_lastDecade - _firstDecade) ~/ 10 + 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final plotW = w - _left - _right;
        void hoverAt(double dx) {
          final step = count <= 1 ? plotW : plotW / (count - 1);
          final i = ((dx - _left - 8) / step).round();
          setState(() => _hoverDecade = (i < 0 || i >= count) ? null : _firstDecade + 10 * i);
        }

        return MouseRegion(
          onHover: (e) => hoverAt(e.localPosition.dx),
          onExit: (_) => setState(() => _hoverDecade = null),
          child: GestureDetector(
            onTapDown: (d) => hoverAt(d.localPosition.dx),
            child: CustomPaint(
              size: Size(w, 280),
              painter: _DecadePainter(
                firstDecade: _firstDecade,
                lastDecade: _lastDecade,
                lines: <_Line>[
                  for (final m in chosen)
                    _Line(AppColors.museum(m), _decadeData[m] ?? const <int, _DecadePoint>{}),
                ],
                scoreMetric: _scoreMetric,
                hover: _hoverDecade,
              ),
            ),
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------------------------------------
// drawing
// --------------------------------------------------------------------------------------------

const TextStyle _axisStyle = TextStyle(fontFamily: kSans, fontSize: 11.5, color: AppColors.muted);

/// Writes [text] with its anchor point at [at]. [alignX] is the share of the width that lies to the left of the point
/// (0 left-aligned, 0.5 centred, 1 right-aligned); [alignY] is the same for the height.
void _drawText(Canvas canvas, String text, Offset at, {double alignX = 0, double alignY = 0}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: _axisStyle),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(at.dx - tp.width * alignX, at.dy - tp.height * alignY));
}

/// A step for the axis (1, 2 or 5 times a power of ten) that gives at most [maxTicks] intervals.
double _tickStep(double maxValue, int maxTicks) {
  if (maxValue <= 0) return 1;
  final raw = maxValue / maxTicks;
  final power = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / power;
  final base = f <= 1 ? 1.0 : (f <= 2 ? 2.0 : (f <= 5 ? 5.0 : 10.0));
  return base * power;
}

class _YearBarsPainter extends CustomPainter {
  _YearBarsPainter({
    required this.first,
    required this.last,
    required this.series,
    required this.colors,
    required this.hover,
  });

  final int first;
  final int last;

  /// one list per museum (bottom to top), one value per year
  final List<List<int>> series;
  final List<Color> colors;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _left - _right;
    final plotH = size.height - _top - _bottom;
    final n = last - first + 1;
    if (n <= 0 || plotW <= 0) return;

    var maxTotal = 1;
    for (var i = 0; i < n; i++) {
      var t = 0;
      for (final s in series) {
        t += s[i];
      }
      if (t > maxTotal) maxTotal = t;
    }
    final step = _tickStep(maxTotal.toDouble(), 5);
    final yMax = (maxTotal / step).ceil() * step;

    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var v = 0.0; v <= yMax + 0.001; v += step) {
      final y = _top + plotH - plotH * v / yMax;
      canvas.drawLine(Offset(_left, y), Offset(_left + plotW, y), grid);
      _drawText(canvas, fmtInt(v), Offset(_left - 6, y), alignX: 1, alignY: 0.5);
    }

    final barW = plotW / n;
    if (hover != null) {
      final i = hover! - first;
      if (i >= 0 && i < n) {
        canvas.drawRect(
          Rect.fromLTWH(_left + i * barW, _top, barW < 3 ? 3 : barW, plotH),
          Paint()..color = AppColors.ink.withAlpha(22),
        );
      }
    }
    final gap = barW > 4 ? 1.0 : 0.0;
    for (var i = 0; i < n; i++) {
      var y = _top + plotH;
      for (var m = 0; m < series.length; m++) {
        final v = series[m][i];
        if (v <= 0) continue;
        final h = plotH * v / yMax;
        y -= h;
        canvas.drawRect(
          Rect.fromLTWH(_left + i * barW, y, math.max(barW - gap, 1.0), h),
          Paint()..color = colors[m],
        );
      }
    }

    canvas.drawLine(
      Offset(_left, _top + plotH),
      Offset(_left + plotW, _top + plotH),
      Paint()
        ..color = AppColors.edge
        ..strokeWidth = 1.2,
    );

    // labels under the axis: every 10, 20 or 50 years, so that they do not touch each other
    var every = 10;
    for (final candidate in const <int>[10, 20, 50, 100]) {
      every = candidate;
      if (candidate * barW >= 46) break;
    }
    for (var year = ((first + every - 1) ~/ every) * every; year <= last; year += every) {
      final x = _left + (year - first + 0.5) * barW;
      canvas.drawLine(Offset(x, _top + plotH), Offset(x, _top + plotH + 4), grid);
      _drawText(canvas, '$year', Offset(x, _top + plotH + 6), alignX: 0.5);
    }
  }

  @override
  bool shouldRepaint(covariant _YearBarsPainter old) {
    return old.hover != hover || old.series != series || old.first != first || old.last != last;
  }
}

/// The values of one museum, decade by decade, with the colour of its line.
class _Line {
  const _Line(this.color, this.points);

  final Color color;
  final Map<int, _DecadePoint> points;
}

class _DecadePainter extends CustomPainter {
  _DecadePainter({
    required this.firstDecade,
    required this.lastDecade,
    required this.lines,
    required this.scoreMetric,
    required this.hover,
  });

  final int firstDecade;
  final int lastDecade;
  final List<_Line> lines;
  final bool scoreMetric;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _left - _right - 16;
    final plotH = size.height - _top - _bottom;
    final count = (lastDecade - firstDecade) ~/ 10 + 1;
    if (count <= 0 || plotW <= 0) return;

    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    final yMax = scoreMetric ? 1.0 : 100.0;
    final step = scoreMetric ? 0.2 : 20.0;
    for (var v = 0.0; v <= yMax + 0.001; v += step) {
      final y = _top + plotH - plotH * v / yMax;
      canvas.drawLine(Offset(_left, y), Offset(_left + plotW + 16, y), grid);
      _drawText(canvas, scoreMetric ? v.toStringAsFixed(1) : '${v.round()}%', Offset(_left - 6, y), alignX: 1, alignY: 0.5);
    }

    double xOf(int decade) {
      final i = (decade - firstDecade) ~/ 10;
      final f = count <= 1 ? 0.5 : i / (count - 1);
      return _left + 8 + plotW * f;
    }

    // decade labels, thinned out when the window is narrow
    final spacing = count <= 1 ? plotW : plotW / (count - 1);
    final skip = spacing >= 46 ? 1 : (spacing >= 23 ? 2 : 4);
    for (var dec = firstDecade; dec <= lastDecade; dec += 10 * skip) {
      _drawText(canvas, '$dec', Offset(xOf(dec), _top + plotH + 8), alignX: 0.5);
    }

    final h = hover;
    if (h != null && h >= firstDecade && h <= lastDecade) {
      canvas.drawLine(
        Offset(xOf(h), _top),
        Offset(xOf(h), _top + plotH),
        Paint()
          ..color = AppColors.ink.withAlpha(60)
          ..strokeWidth = 1,
      );
    }

    for (final line in lines) {
      final decades = line.points.keys.toList()..sort();
      final path = Path();
      var open = false;
      Offset? previous;
      for (var dec = firstDecade; dec <= lastDecade; dec += 10) {
        final p = line.points[dec];
        if (p == null) {
          open = false;
          continue;
        }
        final v = scoreMetric ? p.score : p.site;
        final at = Offset(xOf(dec), _top + plotH - plotH * (v / yMax).clamp(0.0, 1.0));
        if (!open) {
          path.moveTo(at.dx, at.dy);
          open = true;
        } else {
          path.lineTo(at.dx, at.dy);
        }
        previous = at;
      }
      if (previous != null && decades.isNotEmpty) {
        canvas.drawPath(
          path,
          Paint()
            ..color = line.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      for (final dec in decades) {
        final p = line.points[dec];
        if (p == null) continue;
        final v = scoreMetric ? p.score : p.site;
        final at = Offset(xOf(dec), _top + plotH - plotH * (v / yMax).clamp(0.0, 1.0));
        if (p.artifacts < _fewArtifacts) {
          canvas.drawCircle(at, 4.2, Paint()..color = AppColors.surface);
          canvas.drawCircle(
            at,
            4.2,
            Paint()
              ..color = line.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        } else {
          canvas.drawCircle(at, 4.2, Paint()..color = line.color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DecadePainter old) {
    return old.hover != hover || old.scoreMetric != scoreMetric || old.lines != lines;
  }
}
