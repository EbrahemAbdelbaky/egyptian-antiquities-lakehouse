import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/egypt_outline.dart';
import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../data/name_search.dart';
import '../theme.dart';
import '../widgets.dart';

/// The museums in the order of the counts of a site.
const List<String> _museums = <String>['Met', 'Cleveland', 'Louvre'];

/// The list shows this many sites at first, and this many more each time the button is pressed.
const int _pageSize = 12;

/// A part of the world that the map can show (degrees), the distance between its grid lines, and the widest it is drawn.
class _View {
  const _View(this.lonMin, this.lonMax, this.latMin, this.latMax, this.gridStep, this.maxWidth);

  final double lonMin;
  final double lonMax;
  final double latMin;
  final double latMax;
  final double gridStep;
  final double maxWidth;

  double get lonSpan => lonMax - lonMin;
  double get latSpan => latMax - latMin;
}

/// All of Egypt, with a margin of one degree on the west so that the labels of the grid do not touch the border.
const _View _wholeCountry = _View(24.0, 37.0, 21.7, 32.0, 2.0, 640);

/// The Nile valley from Aswan to Cairo, where nearly all the sites are.
const _View _nileValley = _View(29.0, 34.5, 23.8, 30.6, 1.0, 520);

/// One degree of longitude is shorter than one degree of latitude by cos(latitude); 27 N is the middle of Egypt.
final double _cosLat = math.cos(27 * math.pi / 180);

/// The matching of site names to Wikidata, in the order of the panel at the bottom: how Silver found the place.
/// Each entry is: the text in the data, the words for the screen, and whether the site was linked.
const List<List<String>> _matchKinds = <List<String>>[
  <String>['exact', 'Same name', 'linked'],
  <String>['exact (accent-free)', 'Same name, accents ignored', 'linked'],
  <String>['manual (spelling corrected by hand)', 'Spelling corrected by hand', 'linked'],
  <String>['manual (approximate area)', 'Approximate area, chosen by hand', 'linked'],
  <String>['before the comma (main site)', 'Name before the comma', 'linked'],
  <String>['name in parentheses', 'Name in parentheses', 'linked'],
  <String>['base name (north/south removed)', 'Name without north or south', 'linked'],
  <String>['no match', 'Tried, no match found', 'open'],
  <String>['not linked', 'Not linked', 'open'],
];

/// One find site, with the counts of the three museums.
class _Site {
  _Site(Rec r)
      : key = toInt(r['site_key']),
        text = toStr(r['site_text']),
        label = toStr(r['wikidata_label']),
        qid = toStr(r['wikidata_qid']),
        lat = r['latitude'] == null ? null : toDouble(r['latitude']),
        lon = r['longitude'] == null ? null : toDouble(r['longitude']),
        matchType = toStr(r['match_type']),
        counts = <int>[toInt(r['met_artifacts']), toInt(r['cleveland_artifacts']), toInt(r['louvre_artifacts'])],
        folded = foldName('${toStr(r['site_text'])} ${toStr(r['wikidata_label'])}');

  final int key;
  final String text;
  final String label;
  final String qid;
  final double? lat;
  final double? lon;
  final String matchType;

  /// artifacts per museum, in the order Met, Cleveland, Louvre
  final List<int> counts;

  /// the name and the Wikidata label without accents, for the search box
  final String folded;

  bool get onMap => lat != null && lon != null;

  int countFor(String museum) {
    final i = _museums.indexOf(museum);
    if (i < 0) return counts[0] + counts[1] + counts[2];
    return counts[i];
  }
}

/// A site on the map: where it is drawn and how large.
class _Bubble {
  _Bubble(this.key, this.at, this.radius, this.name, this.segments);

  final int key;
  final Offset at;
  final double radius;
  final String name;

  /// the artifacts of each museum that the bubble shows, in the order Met, Cleveland, Louvre
  final List<int> segments;
}

/// The area of a bubble is proportional to the number of artifacts.
double _bubbleRadius(int count, int maxCount) {
  if (maxCount <= 0) return 4;
  return 3.5 + 20 * math.sqrt(count / maxCount);
}

/// Turns longitude and latitude into positions in a box of [width] by [height] pixels.
class _Geo {
  _Geo(this.view, this.width) : height = width * (view.latSpan / (view.lonSpan * _cosLat));

  final _View view;
  final double width;
  final double height;

  Offset project(double lon, double lat) {
    return Offset((lon - view.lonMin) / view.lonSpan * width, (view.latMax - lat) / view.latSpan * height);
  }
}

/// Where the artifacts were found. Read from the Gold view v_site_map: one row per find site, with the artifacts of each
/// museum and, for the sites that Silver linked to Wikidata, the coordinates.
class SitesTab extends StatefulWidget {
  const SitesTab({super.key, required this.data});

  final GoldData data;

  @override
  State<SitesTab> createState() => _SitesTabState();
}

class _SitesTabState extends State<SitesTab> {
  late final List<_Site> _sites;
  late final Map<int, _Site> _byKey;
  late final Map<String, int> _museumTotals;
  final TextEditingController _search = TextEditingController();

  String _museum = 'All';
  _View _view = _wholeCountry;
  bool _mapOnly = false;
  int? _selKey;
  int? _hoverKey;
  int _shown = _pageSize;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _sites = <_Site>[for (final r in d.rows('v_site_map')) _Site(r)];
    _byKey = <int, _Site>{for (final s in _sites) s.key: s};
    _museumTotals = <String, int>{
      for (final r in d.rows('v_gap_by_museum')) toStr(r['museum_name']): toInt(r['artifacts']),
    };
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _count(_Site s) => s.countFor(_museum);

  /// The sites that have artifacts of the chosen museum, the largest first.
  List<_Site> _active() {
    final list = _sites.where((s) => _count(s) > 0).toList();
    list.sort((a, b) {
      final c = _count(b).compareTo(_count(a));
      return c != 0 ? c : a.text.compareTo(b.text);
    });
    return list;
  }

  List<_Site> _listed(List<_Site> active) {
    final words = foldName(_search.text).split(' ').where((w) => w.isNotEmpty).toList();
    return active.where((s) {
      if (_mapOnly && !s.onMap) return false;
      return words.every((w) => s.folded.contains(w));
    }).toList();
  }

  // ------------------------------------------------------------------------------------------
  // the tab
  // ------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final active = _active();
    final listed = _listed(active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MuseumFilter(
          options: <String>['All', ..._museums],
          selected: _museum,
          onChanged: (m) => setState(() {
            _museum = m;
            _selKey = null;
            _hoverKey = null;
            _shown = _pageSize;
          }),
        ),
        const SizedBox(height: 18),
        KeyFigures(items: _figures(active)),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final mapPanel = _mapPanel(active);
            final listPanel = _listPanel(listed);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[mapPanel, const SizedBox(height: 18), listPanel],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 11, child: mapPanel),
                const SizedBox(width: 18),
                Expanded(flex: 9, child: listPanel),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _matchPanel(active),
      ],
    );
  }

  List<KeyFigure> _figures(List<_Site> active) {
    var atSite = 0;
    var onMapSites = 0;
    var onMapArtifacts = 0;
    var single = 0;
    _Site? largest;
    for (final s in active) {
      final c = _count(s);
      atSite += c;
      if (s.onMap) {
        onMapSites++;
        onMapArtifacts += c;
      }
      if (c == 1) single++;
      if (largest == null || c > _count(largest)) largest = s;
    }
    var total = 0;
    for (final m in _museum == 'All' ? _museums : <String>[_museum]) {
      total += _museumTotals[m] ?? 0;
    }
    return <KeyFigure>[
      KeyFigure('Find sites', fmtInt(active.length), caption: 'named in the records', color: AppColors.goldDeep),
      KeyFigure(
        'Sites on the map',
        fmtInt(onMapSites),
        caption: active.isEmpty ? null : '${fmtPct(100.0 * onMapSites / active.length)} of the sites',
      ),
      KeyFigure(
        'Artifacts at a find site',
        fmtInt(atSite),
        caption: total == 0 ? null : '${fmtPct(100.0 * atSite / total)} of ${fmtInt(total)}',
      ),
      KeyFigure(
        'Artifacts on the map',
        fmtInt(onMapArtifacts),
        caption: atSite == 0 ? null : '${fmtPct(100.0 * onMapArtifacts / atSite)} of those at a find site',
      ),
      KeyFigure(
        'Largest site',
        largest == null ? '-' : fmtInt(_count(largest)),
        caption: largest?.text,
      ),
      KeyFigure(
        'Sites with one artifact',
        fmtInt(single),
        caption: active.isEmpty ? null : '${fmtPct(100.0 * single / active.length)} of the sites',
      ),
    ];
  }

  // ------------------------------------------------------------------------------------------
  // the map
  // ------------------------------------------------------------------------------------------

  Widget _mapPanel(List<_Site> active) {
    final onMap = active.where((s) => s.onMap).toList();
    return Panel(
      title: 'Find sites on the map',
      caption: 'A bubble is a find site that Silver linked to Wikidata. Its area is proportional to the number of artifacts. '
          'The outline of Egypt and the river are drawn by hand for orientation, not surveyed.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChipButton(
                label: 'Whole country',
                selected: _view == _wholeCountry,
                onTap: () => setState(() {
                  _view = _wholeCountry;
                  _hoverKey = null;
                }),
              ),
              ChipButton(
                label: 'Nile valley, Aswan to Cairo',
                selected: _view == _nileValley,
                onTap: () => setState(() {
                  _view = _nileValley;
                  _hoverKey = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 4,
            children: <Widget>[
              for (final m in _museum == 'All' ? _museums : <String>[_museum])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(width: 10, height: 10, color: AppColors.museum(m)),
                    const SizedBox(width: 6),
                    Text(m, style: AppText.small),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          _mapCanvas(onMap),
          const SizedBox(height: 14),
          _detail(),
        ],
      ),
    );
  }

  Widget _mapCanvas(List<_Site> onMap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.min(constraints.maxWidth, _view.maxWidth);
        final geo = _Geo(_view, w);
        var maxCount = 0;
        for (final s in onMap) {
          if (_count(s) > maxCount) maxCount = _count(s);
        }
        final bubbles = <_Bubble>[];
        var outside = 0;
        for (final s in onMap) {
          final lat = s.lat;
          final lon = s.lon;
          if (lat == null || lon == null) continue;
          final at = geo.project(lon, lat);
          if (at.dx < 0 || at.dy < 0 || at.dx > geo.width || at.dy > geo.height) {
            outside++;
            continue;
          }
          final segments = <int>[
            for (final m in _museums) _museum == 'All' || _museum == m ? s.countFor(m) : 0,
          ];
          bubbles.add(_Bubble(s.key, at, _bubbleRadius(_count(s), maxCount), s.text, segments));
        }
        bubbles.sort((a, b) => b.radius.compareTo(a.radius));

        int? hit(Offset p) {
          _Bubble? best;
          for (final b in bubbles) {
            final dist = (b.at - p).distance;
            if (dist <= b.radius + 3 && (best == null || b.radius < best.radius)) best = b;
          }
          return best?.key;
        }

        final map = Align(
          alignment: Alignment.topLeft,
          child: MouseRegion(
            cursor: _hoverKey == null ? MouseCursor.defer : SystemMouseCursors.click,
            onHover: (e) {
              final k = hit(e.localPosition);
              if (k != _hoverKey) setState(() => _hoverKey = k);
            },
            onExit: (_) {
              if (_hoverKey != null) setState(() => _hoverKey = null);
            },
            child: GestureDetector(
              onTapDown: (d) => setState(() => _selKey = hit(d.localPosition)),
              child: ClipRect(
                child: CustomPaint(
                  size: Size(geo.width, geo.height),
                  painter: _MapPainter(geo: geo, bubbles: bubbles, selected: _selKey, hover: _hoverKey),
                ),
              ),
            ),
          ),
        );
        if (outside == 0) return map;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            map,
            const SizedBox(height: 6),
            Text(
              outside == 1
                  ? '1 site on the map lies outside this view.'
                  : '$outside sites on the map lie outside this view.',
              style: AppText.small,
            ),
          ],
        );
      },
    );
  }

  Widget _detail() {
    final key = _hoverKey ?? _selKey;
    final site = key == null ? null : _byKey[key];
    if (site == null) {
      return const Text(
        'Move the mouse over a bubble, or tap a bubble or a site in the list, to read its details.',
        style: AppText.small,
      );
    }
    final kind = _kindOf(site.matchType);
    final position = site.onMap
        ? '${site.lat!.toStringAsFixed(4)} N, ${site.lon!.toStringAsFixed(4)} E'
        : 'none: the site is not linked to Wikidata, so it is not on the map';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.stripe,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(site.text, style: AppText.h3),
          const SizedBox(height: 8),
          for (var i = 0; i < _museums.length; i++)
            if (site.counts[i] > 0) LedgerRow(_museums[i], countOf(site.counts[i], 'artifact')),
          if (site.qid.isNotEmpty)
            LedgerRow('Wikidata', site.label.isEmpty || site.label == site.text ? site.qid : '${site.qid}, ${site.label}'),
          LedgerRow('How it was matched', kind[1]),
          LedgerRow('Position', position),
        ],
      ),
    );
  }

  /// The words for the screen for a match type of the data: [text in the data, words, linked or open].
  List<String> _kindOf(String matchType) {
    for (final k in _matchKinds) {
      if (k[0] == matchType) return k;
    }
    return <String>[matchType, matchType, 'open'];
  }

  // ------------------------------------------------------------------------------------------
  // the list
  // ------------------------------------------------------------------------------------------

  Widget _listPanel(List<_Site> listed) {
    final shown = math.min(_shown, listed.length);
    return Panel(
      title: 'Sites ranked by artifacts',
      caption: 'A site name is shown as the museum wrote it. The Louvre writes French names (Thèbes, Éléphantine), '
          'so the same place can appear twice, once in each language.',
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
                hint: 'Find a site',
                width: 230,
                onChanged: (_) => setState(() => _shown = _pageSize),
              ),
              ChipButton(
                label: 'Only sites on the map',
                selected: _mapOnly,
                icon: _mapOnly ? Icons.check : null,
                onTap: () => setState(() {
                  _mapOnly = !_mapOnly;
                  _shown = _pageSize;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${fmtInt(listed.length)} sites', style: AppText.small),
          const SizedBox(height: 6),
          if (listed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No site matches this search.', style: AppText.small),
            )
          else
            for (var i = 0; i < shown; i++) _siteLine(listed[i]),
          if (shown < listed.length) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ChipButton(
                  label: 'Show ${math.min(_pageSize, listed.length - shown)} more',
                  selected: false,
                  onTap: () => setState(() => _shown += _pageSize),
                ),
                Text('Showing ${fmtInt(shown)} of ${fmtInt(listed.length)}', style: AppText.small),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _siteLine(_Site s) {
    final chosen = s.key == _selKey;
    final parts = <String>[];
    if (_museum == 'All') {
      for (var i = 0; i < _museums.length; i++) {
        if (s.counts[i] > 0) parts.add('${_museums[i]} ${fmtInt(s.counts[i])}');
      }
    }
    if (s.onMap && s.label.isNotEmpty && s.label != s.text) parts.add('Wikidata: ${s.label}');
    return Material(
      color: chosen ? AppColors.lapis.withAlpha(18) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selKey = chosen ? null : s.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 22,
                child: s.onMap
                    ? const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.place, size: 16, color: AppColors.lapis),
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.text,
                      style: chosen ? AppText.value : AppText.body,
                    ),
                    if (parts.isNotEmpty) Text(parts.join(', '), style: AppText.small),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(fmtInt(_count(s)), style: AppText.cell),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------------------------
  // how the sites were matched
  // ------------------------------------------------------------------------------------------

  Widget _matchPanel(List<_Site> active) {
    final sites = <String, int>{};
    final artifacts = <String, int>{};
    for (final s in active) {
      sites[s.matchType] = (sites[s.matchType] ?? 0) + 1;
      artifacts[s.matchType] = (artifacts[s.matchType] ?? 0) + _count(s);
    }
    final kinds = <List<String>>[..._matchKinds];
    for (final t in sites.keys) {
      if (!kinds.any((k) => k[0] == t)) kinds.add(<String>[t, t, 'open']);
    }
    var linked = 0;
    for (final k in kinds) {
      if (k[2] == 'linked') linked += sites[k[0]] ?? 0;
    }
    return Panel(
      title: 'How the sites were matched to Wikidata',
      caption: 'Silver looks for the site names of the three museums in Wikidata and keeps their coordinates. The Louvre writes its names in French, '
          'so they are compared without accents, and a short list of hand-checked corrections covers the names spelt differently in Wikidata. '
          'When a text names several places, the first one found is used. '
          '${active.isEmpty ? '' : '${fmtPct(100.0 * linked / active.length)} of these sites are linked.'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (active.isEmpty)
            const Text('No site in this selection.', style: AppText.small)
          else
            for (final k in kinds)
              if ((sites[k[0]] ?? 0) > 0)
                BarRow(
                  label: k[1],
                  fraction: (sites[k[0]] ?? 0) / active.length,
                  valueText: '${countOf(sites[k[0]] ?? 0, 'site')}, ${countOf(artifacts[k[0]] ?? 0, 'artifact')}',
                  color: k[2] == 'linked' ? AppColors.lapis : AppColors.carnelian,
                  labelWidth: 250,
                  valueWidth: 220,
                ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------------------------
// drawing
// --------------------------------------------------------------------------------------------

const TextStyle _mapText = TextStyle(fontFamily: kSans, fontSize: 11.5, color: AppColors.muted);

TextPainter _layoutText(String text, TextStyle style) {
  return TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.geo, required this.bubbles, required this.selected, required this.hover});

  final _Geo geo;
  final List<_Bubble> bubbles;
  final int? selected;
  final int? hover;

  Path _line(List<List<double>> points) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = geo.project(points[i][0], points[i][1]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // the sea and the neighbours
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.aboutBg);

    // a graticule: a line every gridStep degrees, labelled once the land is drawn
    final view = geo.view;
    final step = view.gridStep.round();
    final firstLat = (view.latMin / step).ceil() * step;
    final firstLon = (view.lonMin / step).ceil() * step;
    final grid = Paint()
      ..color = AppColors.aboutLine
      ..strokeWidth = 1;
    for (var lat = firstLat; lat <= view.latMax; lat += step) {
      final y = geo.project(view.lonMin, lat.toDouble()).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var lon = firstLon; lon <= view.lonMax; lon += step) {
      final x = geo.project(lon.toDouble(), view.latMin).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    // the land of Egypt
    final land = _line(kEgyptOutline)..close();
    canvas.drawPath(land, Paint()..color = AppColors.surface);
    canvas.drawPath(
      land,
      Paint()
        ..color = AppColors.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    for (var lat = firstLat; lat <= view.latMax; lat += step) {
      final y = geo.project(view.lonMin, lat.toDouble()).dy;
      _label(canvas, '$lat°N', Offset(3, y - 2), alignY: 1);
    }
    for (var lon = firstLon; lon <= view.lonMax; lon += step) {
      final x = geo.project(lon.toDouble(), view.latMin).dx;
      _label(canvas, '$lon°E', Offset(x + 3, size.height - 3), alignY: 1);
    }

    // the river and the lake
    canvas.drawPath(
      _line(kLakeNasser),
      Paint()
        ..color = AppColors.lapisBright.withAlpha(110)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );
    final river = Paint()
      ..color = AppColors.lapisBright
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4;
    canvas.drawPath(_line(kNile), river);
    canvas.drawPath(_line(kRosetta), river);
    canvas.drawPath(_line(kDamietta), river);

    _label(canvas, 'Mediterranean Sea', geo.project(27.4, 31.95), italic: true);
    _label(canvas, 'Red Sea', geo.project(35.7, 26.2), italic: true);
    _label(canvas, 'Sinai', geo.project(33.5, 29.0), italic: true);

    // a few cities to find one's way
    for (final c in kMapPlaces) {
      final p = geo.project(c.lon, c.lat);
      canvas.drawCircle(p, 2.6, Paint()..color = AppColors.ink);
      _label(canvas, c.name, p + const Offset(5, -3), alignY: 1, color: AppColors.ink);
    }

    // the bubbles, the largest first so that the small ones stay visible
    for (final b in bubbles) {
      _drawBubble(canvas, b);
    }

    // the chosen site and the site under the mouse
    for (final key in <int?>[selected, hover]) {
      if (key == null) continue;
      for (final b in bubbles) {
        if (b.key != key) continue;
        canvas.drawCircle(
          b.at,
          b.radius + 3,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = key == hover ? 2.2 : 1.6,
        );
      }
    }
    final named = hover ?? selected;
    if (named != null) {
      for (final b in bubbles) {
        if (b.key == named) _drawName(canvas, b, size);
      }
    }
  }

  void _drawBubble(Canvas canvas, _Bubble b) {
    var total = 0;
    var parts = 0;
    for (final v in b.segments) {
      total += v;
      if (v > 0) parts++;
    }
    final rect = Rect.fromCircle(center: b.at, radius: b.radius);
    if (total <= 0) return;
    if (parts <= 1) {
      var colour = AppColors.muted;
      for (var i = 0; i < b.segments.length; i++) {
        if (b.segments[i] > 0) colour = AppColors.museum(_museums[i]);
      }
      canvas.drawCircle(b.at, b.radius, Paint()..color = colour.withAlpha(215));
    } else {
      var start = -math.pi / 2;
      for (var i = 0; i < b.segments.length; i++) {
        if (b.segments[i] <= 0) continue;
        final sweep = 2 * math.pi * b.segments[i] / total;
        canvas.drawArc(rect, start, sweep, true, Paint()..color = AppColors.museum(_museums[i]).withAlpha(215));
        start += sweep;
      }
    }
    canvas.drawCircle(
      b.at,
      b.radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawName(Canvas canvas, _Bubble b, Size size) {
    final tp = _layoutText(
      b.name,
      const TextStyle(fontFamily: kSans, fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
    );
    final boxW = tp.width + 12;
    final boxH = tp.height + 6;
    var x = b.at.dx + b.radius + 6;
    if (x + boxW > size.width) x = b.at.dx - b.radius - 6 - boxW;
    var y = b.at.dy - boxH / 2;
    if (y < 2) y = 2;
    if (y + boxH > size.height - 2) y = size.height - 2 - boxH;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, boxW, boxH), const Radius.circular(3));
    canvas.drawRRect(box, Paint()..color = Colors.white);
    canvas.drawRRect(
      box,
      Paint()
        ..color = AppColors.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(x + 6, y + 3));
  }

  void _label(Canvas canvas, String text, Offset at, {double alignY = 0, bool italic = false, Color? color}) {
    final style = _mapText.copyWith(
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color ?? AppColors.muted,
    );
    final tp = _layoutText(text, style);
    tp.paint(canvas, Offset(at.dx, at.dy - tp.height * alignY));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) {
    return old.bubbles != bubbles || old.selected != selected || old.hover != hover || old.geo.width != geo.width || old.geo.view != geo.view;
  }
}
