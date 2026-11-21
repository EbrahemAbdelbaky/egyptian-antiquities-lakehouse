import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------------------------
// The picture of the Gold layer: eight tables as boxes, the foreign keys of the database as arrows.
// The positions are fixed (the picture is drawn once); the arrows are read from the database.
// ---------------------------------------------------------------------------------------------

const double _boxW = 190;
const double _boxH = 92;
const double _canvasW = 1040;
const double _canvasH = 530;

class _Node {
  const _Node(this.name, this.x, this.y);
  final String name;
  final double x;
  final double y;
}

const List<_Node> _nodes = <_Node>[
  _Node('dim_era', 20, 223),
  _Node('dim_ruler', 275, 223),
  _Node('fact_artifact', 545, 223),
  _Node('dim_museum', 830, 223),
  _Node('dim_site', 545, 30),
  _Node('ml_dataset', 830, 30),
  _Node('map_reign_to_ruler', 275, 420),
  _Node('ruler_name_variant', 545, 420),
];

class _Edge {
  const _Edge(this.from, this.to, this.column, {this.dashed = false});
  final String from;
  final String to;
  final String column;
  final bool dashed;
}

/// Where the rows shown under a table come from (small tables in full, large tables as a sample).
const Map<String, String> _previewSource = <String, String>{
  'dim_museum': 'dim_museum',
  'dim_era': 'dim_era',
  'dim_ruler': 'dim_ruler',
  'map_reign_to_ruler': 'map_reign_to_ruler',
  'ruler_name_variant': 'ruler_name_variant',
  'dim_site': 'sample_dim_site',
  'fact_artifact': 'sample_fact_artifact',
  'ml_dataset': 'sample_ml_dataset',
};

class StructureScreen extends StatefulWidget {
  const StructureScreen({super.key, required this.data});

  final GoldData data;

  @override
  State<StructureScreen> createState() => _StructureScreenState();
}

class _StructureScreenState extends State<StructureScreen> {
  String _selected = 'fact_artifact';
  int _tab = 0;

  void _select(String name) => setState(() => _selected = name);

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final info = <String, Rec>{
      for (final t in data.rows('table_info')) toStr(t['table_name']): t,
    };
    final fks = data.rows('table_fks');

    final edges = <_Edge>[
      for (final f in fks)
        _Edge(toStr(f['from_table']), toStr(f['to_table']), toStr(f['from_column'])),
      const _Edge('ml_dataset', 'fact_artifact', 'artifact_key', dashed: true),
    ];

    final rects = <String, Rect>{
      for (final n in _nodes) n.name: Rect.fromLTWH(n.x, n.y, _boxW, _boxH),
    };

    return PageScaffold(
      title: 'Structure of the Gold layer',
      subtitle: 'Eight tables. Click a table to see its columns, its keys and its rows.',
      art: 'djed',
      children: <Widget>[
        const AboutBox(
          lines: <String>[
            'The hierarchy asked for is period, then ruler, then artifact: dim_era (the periods) is the top, '
                'dim_ruler (each ruler belongs to one period) is the middle, and fact_artifact (one row per artifact) is the bottom. '
                'An artifact reaches its period only through its ruler.',
            'Artifacts whose museum names no ruler point to a "(no ruler recorded)" row of their own period, so all artifacts are kept.',
            'Because dim_ruler points to dim_era, the dimensions are not all attached to the fact table directly. '
                'That makes the model a snowflake, not a star.',
            'Solid arrows are foreign keys read from the database. The dashed arrow is not a foreign key: '
                'ml_dataset is cut from fact_artifact and shares its artifact_key.',
          ],
        ),
        const SizedBox(height: 18),
        Panel(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: _canvasW,
                height: _canvasH,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EdgesPainter(
                          edges: edges,
                          rects: rects,
                          selected: _selected,
                        ),
                      ),
                    ),
                    for (final n in _nodes)
                      Positioned(
                        left: n.x,
                        top: n.y,
                        width: _boxW,
                        height: _boxH,
                        child: _TableBox(
                          name: n.name,
                          kind: toStr(info[n.name]?['kind']),
                          rowCount: toInt(info[n.name]?['row_count']),
                          selected: n.name == _selected,
                          onTap: () => _select(n.name),
                        ),
                      ),
                    const Positioned(
                      left: 20,
                      top: 130,
                      child: Text(
                        'period  →  ruler  →  artifact',
                        style: TextStyle(
                          fontFamily: kSerif,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.goldDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
              const SizedBox(height: 12),
              const _Legend(),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _TableDetail(
          data: data,
          table: _selected,
          info: info[_selected],
          tab: _tab,
          onTab: (t) => setState(() => _tab = t),
          onSelect: _select,
        ),
      ],
    );
  }
}

/// What the colours and the two kinds of arrow in the diagram mean.
class _Legend extends StatelessWidget {
  const _Legend();

  Widget _swatch(String kind) {
    final color = AppColors.tableKind(kind);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            border: Border.all(color: color, width: 1.4),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(kind, style: AppText.small),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _swatch('Fact'),
        _swatch('Dimension'),
        _swatch('Mapping'),
        _swatch('ML dataset'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(width: 26, height: 2.4, color: AppColors.gold),
            const SizedBox(width: 7),
            const Text('Foreign key', style: AppText.small),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < 3; i++) ...<Widget>[
              Container(width: 6, height: 2.4, color: AppColors.gold),
              const SizedBox(width: 3),
            ],
            const SizedBox(width: 4),
            const Text('Shared key (not a foreign key)', style: AppText.small),
          ],
        ),
      ],
    );
  }
}

class _TableBox extends StatelessWidget {
  const _TableBox({
    required this.name,
    required this.kind,
    required this.rowCount,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String kind;
  final int rowCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.tableKind(kind);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(30) : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: selected ? 3 : 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                kind,
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color.lerp(color, Colors.black, 0.38) ?? color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kMono,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text('${fmtInt(rowCount)} rows', style: AppText.small),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
    required this.edges,
    required this.rects,
    required this.selected,
  });

  final List<_Edge> edges;
  final Map<String, Rect> rects;
  final String selected;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final a = rects[e.from];
      final b = rects[e.to];
      if (a == null || b == null) continue;
      final active = e.from == selected || e.to == selected;
      final color = active ? AppColors.gold : AppColors.edge;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.6 : 1.5
        ..color = color;
      final start = _edgePoint(a, b.center);
      final end = _edgePoint(b, a.center);
      if (e.dashed) {
        _dashedLine(canvas, start, end, stroke);
      } else {
        canvas.drawLine(start, end, stroke);
      }
      _arrowHead(canvas, start, end, color);
    }
  }

  /// The point where the line from the middle of [r] towards [target] leaves the rectangle.
  static Offset _edgePoint(Rect r, Offset target) {
    final c = r.center;
    final dx = target.dx - c.dx;
    final dy = target.dy - c.dy;
    if (dx == 0 && dy == 0) return c;
    final sx = dx == 0 ? double.infinity : (r.width / 2) / dx.abs();
    final sy = dy == 0 ? double.infinity : (r.height / 2) / dy.abs();
    final s = sx < sy ? sx : sy;
    return Offset(c.dx + dx * s, c.dy + dy * s);
  }

  static void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    const dash = 7.0;
    const gap = 5.0;
    var d = 0.0;
    while (d < len) {
      final e = math.min(d + dash, len);
      canvas.drawLine(
        Offset(a.dx + dx * d / len, a.dy + dy * d / len),
        Offset(a.dx + dx * e / len, a.dy + dy * e / len),
        paint,
      );
      d += dash + gap;
    }
  }

  static void _arrowHead(Canvas canvas, Offset from, Offset tip, Color color) {
    final dx = tip.dx - from.dx;
    final dy = tip.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len;
    final uy = dy / len;
    const size = 11.0;
    final left = Offset(
      tip.dx - ux * size + uy * size * 0.5,
      tip.dy - uy * size - ux * size * 0.5,
    );
    final right = Offset(
      tip.dx - ux * size - uy * size * 0.5,
      tip.dy - uy * size + ux * size * 0.5,
    );
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) {
    return oldDelegate.selected != selected || oldDelegate.edges != edges;
  }
}

// ---------------------------------------------------------------------------------------------
// Detail of the selected table: what a row is, then three tabs (columns, relations, rows).
// ---------------------------------------------------------------------------------------------

/// One plain sentence per table, for a reader who has not seen the database.
const Map<String, String> _plain = <String, String>{
  'dim_museum': 'The three museums whose collections are in Gold, with their country and the licence of their data.',
  'dim_era': 'The periods of Egyptian history. Each ruler belongs to one period.',
  'dim_ruler': 'The rulers, one row each. A ruler found in several museums is one row, linked by its Wikidata number.',
  'dim_site': 'The find places (sites), with coordinates where Wikidata has them.',
  'map_reign_to_ruler': 'Connects the reign text a museum wrote on a record to the ruler in dim_ruler.',
  'ruler_name_variant': 'How each museum spells the name of a ruler. The museums keep their own spelling here.',
  'fact_artifact': 'The centre of the model: one row per artifact, with its museum, ruler, site and documentation score.',
  'ml_dataset': 'A table cut from fact_artifact for machine learning. It shares the artifact_key.',
};

String _capital(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _TableDetail extends StatelessWidget {
  const _TableDetail({
    required this.data,
    required this.table,
    required this.info,
    required this.tab,
    required this.onTab,
    required this.onSelect,
  });

  final GoldData data;
  final String table;
  final Rec? info;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final meta = info ?? <String, dynamic>{};
    final kind = toStr(meta['kind']);
    final color = AppColors.tableKind(kind);
    final total = toInt(meta['row_count']);

    final columns = data
        .rows('table_columns')
        .where((c) => toStr(c['table_name']) == table)
        .toList();
    final fks = data.rows('table_fks');
    final references = fks.where((f) => toStr(f['from_table']) == table).toList();
    final referencedBy = fks.where((f) => toStr(f['to_table']) == table).toList();
    final fkByColumn = <String, String>{
      for (final f in references)
        toStr(f['from_column']): '${toStr(f['to_table'])}.${toStr(f['to_column'])}',
    };

    final sourceName = _previewSource[table] ?? table;
    final previewRows = data.rows(sourceName);
    final isSample = sourceName.startsWith('sample_');
    final previewColumns =
        previewRows.isEmpty ? <String>[] : previewRows.first.keys.toList();

    final sharedKey = table == 'fact_artifact' || table == 'ml_dataset';
    final relationCount = references.length + referencedBy.length + (sharedKey ? 1 : 0);
    final plain = _plain[table];
    final current = tab.clamp(0, 2).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              table,
              style: AppText.h1.copyWith(fontFamily: kMono, fontSize: 27),
            ),
            Pill(kind, color: color, filled: true),
          ],
        ),
        const SizedBox(height: 6),
        if (plain != null) Text(plain, style: AppText.lead),
        const SizedBox(height: 4),
        Text(
          '${fmtInt(total)} rows. ${_capital(toStr(meta['one_row_is']))}.',
          style: AppText.small,
        ),
        const SizedBox(height: 18),
        AppTabs(
          labels: <String>[
            'Columns (${columns.length})',
            'Relations ($relationCount)',
            isSample ? 'Sample rows' : 'All rows (${fmtInt(previewRows.length)})',
          ],
          selected: current,
          onSelect: onTab,
        ),
        const SizedBox(height: 16),
        if (current == 0)
          _columnsPanel(columns, fkByColumn)
        else if (current == 1)
          _relationsPanel(references, referencedBy, sharedKey)
        else
          _rowsPanel(previewRows, previewColumns, isSample, total),
      ],
    );
  }

  // ---- Columns -----------------------------------------------------------------------------

  Widget _columnsPanel(List<Rec> columns, Map<String, String> fkByColumn) {
    const header = TextStyle(
      fontFamily: kSans,
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    );
    return Panel(
      caption: fkByColumn.isEmpty
          ? null
          : 'A column marked FK holds the key of another table. Click the table name under it to open that table.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                SizedBox(width: 30, child: Text('#', style: header)),
                Expanded(flex: 5, child: Text('Column', style: header)),
                Expanded(flex: 4, child: Text('Type', style: header)),
                SizedBox(width: 132, child: Text('Keys', style: header)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.line),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: columns.length,
              separatorBuilder: (context, i) =>
                  const Divider(height: 1, thickness: 1, color: AppColors.track),
              itemBuilder: (context, i) => _columnRow(columns[i], fkByColumn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnRow(Rec c, Map<String, String> fkByColumn) {
    final name = toStr(c['column_name']);
    final isKey = c['is_primary_key'] == true;
    final target = fkByColumn[name];
    final nullable = c['is_nullable'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 30,
            child: Text('${toInt(c['column_id'])}', style: AppText.small),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: AppText.mono),
                if (target != null)
                  _tableLink(
                    'points to $target',
                    target.split('.').first,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(toStr(c['data_type']), style: AppText.small),
          ),
          SizedBox(
            width: 132,
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: <Widget>[
                if (isKey) const Pill('PK', color: AppColors.gold, filled: true),
                if (target != null) const Pill('FK', color: AppColors.lapis, filled: true),
                if (!nullable && !isKey) const Pill('NOT NULL', color: AppColors.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Relations ---------------------------------------------------------------------------

  Widget _relationsPanel(List<Rec> references, List<Rec> referencedBy, bool sharedKey) {
    return Panel(
      caption: 'Read from the foreign keys of the database. Click a table name to open it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveRow(
            stretch: false,
            breakpoint: 700,
            gap: 28,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Points to', style: AppText.h3),
                  const SizedBox(height: 2),
                  const Text('Keys this table holds', style: AppText.small),
                  const SizedBox(height: 8),
                  if (references.isEmpty)
                    const Text('None. This table does not point to another one.', style: AppText.small)
                  else
                    for (final f in references)
                      _relationRow(
                        toStr(f['from_column']),
                        toStr(f['to_table']),
                        toStr(f['to_column']),
                      ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Pointed to by', style: AppText.h3),
                  const SizedBox(height: 2),
                  const Text('Tables that hold a key of this one', style: AppText.small),
                  const SizedBox(height: 8),
                  if (referencedBy.isEmpty)
                    const Text('No table points to this one.', style: AppText.small)
                  else
                    for (final f in referencedBy)
                      _relationRow(
                        toStr(f['from_column']),
                        toStr(f['from_table']),
                        null,
                      ),
                ],
              ),
            ],
          ),
          if (sharedKey) ...<Widget>[
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
            const SizedBox(height: 14),
            const Text('Shared key, not a foreign key', style: AppText.h3),
            const SizedBox(height: 6),
            Text(
              table == 'fact_artifact'
                  ? 'ml_dataset is cut from this table and shares its artifact_key.'
                  : 'This table is cut from fact_artifact and shares its artifact_key.',
              style: AppText.body,
            ),
          ],
        ],
      ),
    );
  }

  /// [column] of this table, pointing to [tableName] (and its [targetColumn] when this table holds the key).
  Widget _relationRow(String column, String tableName, String? targetColumn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: <Widget>[
          Text(column, style: AppText.mono),
          const Icon(Icons.arrow_right_alt, size: 20, color: AppColors.goldDeep),
          _tableLink(
            targetColumn == null ? tableName : '$tableName.$targetColumn',
            tableName,
          ),
        ],
      ),
    );
  }

  /// A table name that opens that table when clicked.
  Widget _tableLink(String text, String tableName) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelect(tableName),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: kMono,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.lapis,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ---- Rows --------------------------------------------------------------------------------

  Widget _rowsPanel(List<Rec> previewRows, List<String> previewColumns, bool isSample, int total) {
    return Panel(
      title: isSample
          ? 'Sample rows (${previewRows.length} of ${fmtInt(total)})'
          : 'All rows (${fmtInt(previewRows.length)})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isSample
                ? (table == 'fact_artifact'
                    ? 'A fixed sample: 15 artifacts from each museum, the same rows every time. Long texts are cut. NULL means the value is missing or does not apply.'
                    : 'A fixed sample spread over the whole table, the same rows every time. Long texts are cut. NULL means the value is missing or does not apply.')
                : 'Scroll sideways for more columns. NULL means the value is missing or does not apply.',
            style: AppText.small,
          ),
          const SizedBox(height: 10),
          TableViewer(columns: previewColumns, rows: previewRows),
        ],
      ),
    );
  }
}
