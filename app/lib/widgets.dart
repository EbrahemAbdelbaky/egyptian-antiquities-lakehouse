import 'package:flutter/material.dart';

import 'art.dart';
import 'brand.dart';
import 'data/gold_data.dart';
import 'theme.dart';

/// Page frame. With a [hero] the page opens with it (full width) and the title is inside the hero;
/// without one, the page opens with the symbol of the screen ([art]) beside a title, a one-line lead
/// and a short frieze.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.art,
    this.hero,
    required this.children,
  });

  final String title;
  final String? subtitle;

  /// the name of the motif (in art.dart) that stands for this screen
  final String? art;
  final Widget? hero;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final top = hero;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final pad = narrow ? 16.0 : 36.0;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (top != null) top,
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, top == null ? 34 : 30, pad, 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (top == null) ...<Widget>[
                          _PageTitle(title: title, lead: subtitle, art: art, narrow: narrow),
                          const SizedBox(height: 28),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.lead, required this.art, required this.narrow});

  final String title;
  final String? lead;
  final String? art;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final text = lead;
    final motif = art;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: narrow ? AppText.h1.copyWith(fontSize: 28) : AppText.h1),
        if (text != null) ...<Widget>[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(text, style: AppText.lead),
          ),
        ],
        const SizedBox(height: 18),
        const Frieze(height: 11, width: 200),
      ],
    );
    if (motif == null) return heading;
    final plate = narrow ? 60.0 : 84.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SymbolPlate(art: motif, size: plate),
        SizedBox(width: narrow ? 14 : 22),
        Expanded(child: heading),
      ],
    );
  }
}

/// The symbol of a screen, in gold on a deep blue plate: the same colours as the hero of the Overview.
class _SymbolPlate extends StatelessWidget {
  const _SymbolPlate({required this.art, required this.size});

  final String art;
  final double size;

  @override
  Widget build(BuildContext context) {
    // a clip instead of a border: a border on one side only cannot be combined with rounded corners
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        color: AppColors.lapisDeep,
        child: Stack(
          children: <Widget>[
            Center(
              child: ArtMark(art, width: size * 0.64, color: AppColors.goldLeaf, soft: const Color(0xFF2F63AE)),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: ColoredBox(color: AppColors.goldLeaf),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section heading: serif title, an optional note, and a hairline under it.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final extra = note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const LotusMark(width: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: AppText.h2)),
            ],
          ),
          if (extra != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(extra, style: AppText.small),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.line),
        ],
      ),
    );
  }
}

/// A white panel with a serif title, a hairline under the title, and an optional figure caption at the bottom.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    this.title,
    this.trailing,
    this.caption,
    this.padding = const EdgeInsets.all(22),
    required this.child,
  });

  final String? title;
  final Widget? trailing;
  final String? caption;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    final extra = trailing;
    final legend = caption;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (heading != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(heading, style: AppText.h2)),
                if (extra != null) extra,
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.line),
            const SizedBox(height: 16),
          ],
          child,
          if (legend != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(legend, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

/// A big number with a label (kept for the screens that show one figure on its own).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.color = AppColors.lapis,
  });

  final String label;
  final String value;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final note = caption;
    return Container(
      width: 218,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppText.small),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(note, style: AppText.small),
          ],
        ],
      ),
    );
  }
}

/// One figure of the key-figures strip.
class KeyFigure {
  const KeyFigure(this.label, this.value, {this.caption, this.color = AppColors.lapis});

  final String label;
  final String value;
  final String? caption;
  final Color color;
}

/// A ruled strip of key figures, like the first table of a paper: no separate cards, just columns divided by hairlines.
class KeyFigures extends StatelessWidget {
  const KeyFigures({super.key, required this.items});

  final List<KeyFigure> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1000 ? 6 : (constraints.maxWidth >= 640 ? 3 : 2);
        final narrow = cols == 2;
        final rows = <Widget>[];
        for (var start = 0; start < items.length; start += cols) {
          final cells = <Widget>[];
          for (var i = start; i < start + cols; i++) {
            final isLastInRow = i == start + cols - 1;
            final isLastRow = start + cols >= items.length;
            cells.add(
              Expanded(
                child: i < items.length
                    ? _cell(items[i], narrow, !isLastInRow, !isLastRow)
                    : const SizedBox.shrink(),
              ),
            );
          }
          rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
        }
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.lapis, width: 2),
              bottom: BorderSide(color: AppColors.line),
            ),
          ),
          child: Column(children: rows),
        );
      },
    );
  }

  Widget _cell(KeyFigure f, bool narrow, bool dividerRight, bool dividerBottom) {
    final note = f.caption;
    return Container(
      padding: EdgeInsets.fromLTRB(narrow ? 14 : 18, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          right: dividerRight ? const BorderSide(color: AppColors.line) : BorderSide.none,
          bottom: dividerBottom ? const BorderSide(color: AppColors.line) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(f.label, style: AppText.small),
          const SizedBox(height: 2),
          Text(
            f.value,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: narrow ? 30 : 36,
              fontWeight: FontWeight.w700,
              color: f.color,
              height: 1.15,
            ),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(note, style: AppText.small),
          ],
        ],
      ),
    );
  }
}

/// A small square-cornered label. The text is a darker shade of the colour so it stays readable.
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = AppColors.lapis,
    this.filled = false,
  });

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final textColor = Color.lerp(color, Colors.black, 0.38) ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kSans,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : textColor,
        ),
      ),
    );
  }
}

/// "About this screen": a short plain-English explanation, collapsed until opened.
class AboutBox extends StatefulWidget {
  const AboutBox({super.key, required this.lines, this.initiallyOpen = false});

  final List<String> lines;
  final bool initiallyOpen;

  @override
  State<AboutBox> createState() => _AboutBoxState();
}

class _AboutBoxState extends State<AboutBox> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.aboutBg,
        border: Border(left: BorderSide(color: AppColors.lapis, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info_outline, size: 18, color: AppColors.lapis),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('About this screen', style: AppText.aboutTitle),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.lapis,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final line in widget.lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(line, style: AppText.body),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A row of a catalogue entry: label, dotted leader, value.
class LedgerRow extends StatelessWidget {
  const LedgerRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(label, style: AppText.small),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(fontFamily: kSans, fontSize: 12, color: AppColors.edge),
              ),
            ),
          ),
          Text(value, style: AppText.value),
        ],
      ),
    );
  }
}

/// A label, a bar and a value text. The bar is hatched: the hatched length is the share that is missing,
/// the way an excavation drawing hatches what was not recorded.
class BarRow extends StatelessWidget {
  const BarRow({
    super.key,
    required this.label,
    required this.fraction,
    required this.valueText,
    required this.color,
    this.labelWidth = 110,
    this.valueWidth = 210,
  });

  final String label;
  final double fraction;
  final String valueText;
  final Color color;
  final double labelWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    final f = fraction < 0 ? 0.0 : (fraction > 1 ? 1.0 : fraction);
    final bar = CustomPaint(
      size: const Size(double.infinity, 14),
      painter: _HatchBarPainter(fraction: f, color: color),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppText.body),
                const SizedBox(height: 4),
                bar,
                const SizedBox(height: 4),
                Text(valueText, style: AppText.small),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: labelWidth,
                child: Text(label, style: AppText.body, overflow: TextOverflow.ellipsis),
              ),
              Expanded(child: bar),
              const SizedBox(width: 14),
              SizedBox(width: valueWidth, child: Text(valueText, style: AppText.small)),
            ],
          ),
        );
      },
    );
  }
}

class _HatchBarPainter extends CustomPainter {
  const _HatchBarPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(full, Paint()..color = AppColors.track);

    var w = size.width * fraction;
    if (fraction > 0 && w < 3) w = 3;
    if (w <= 0) return;
    final part = Rect.fromLTWH(0, 0, w, size.height);

    canvas.drawRect(part, Paint()..color = color.withAlpha(46));
    canvas.save();
    canvas.clipRect(part);
    final hatch = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = -size.height; x < w; x += 5) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), hatch);
    }
    canvas.restore();
    canvas.drawRect(
      part.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HatchBarPainter old) {
    return old.fraction != fraction || old.color != color;
  }
}

/// Lays the children side by side on a wide window and one under the other on a narrow one.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 900,
    this.gap = 16,
    this.stretch = true,
  });

  final List<Widget> children;
  final double breakpoint;
  final double gap;

  /// true: all children get the same height (only for children without scrolling parts)
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;
        final items = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) {
            items.add(wide ? SizedBox(width: gap) : SizedBox(height: gap));
          }
          items.add(wide ? Expanded(child: children[i]) : children[i]);
        }
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          );
        }
        if (stretch) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        );
      },
    );
  }
}

/// A scrollable table of rows: fixed column widths, horizontal scrollbar, NULL shown in grey italics.
class TableViewer extends StatefulWidget {
  const TableViewer({
    super.key,
    required this.columns,
    required this.rows,
    this.height = 340,
  });

  final List<String> columns;
  final List<Rec> rows;
  final double height;

  @override
  State<TableViewer> createState() => _TableViewerState();
}

class _TableViewerState extends State<TableViewer> {
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  static String _text(dynamic v) {
    if (v == null) return 'NULL';
    if (v is double) {
      final s = v.toStringAsFixed(4);
      return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return '$v';
  }

  List<double> _widths() {
    final out = <double>[];
    final sample = widget.rows.length > 60 ? widget.rows.sublist(0, 60) : widget.rows;
    for (final c in widget.columns) {
      var longest = (c.length * 1.15).ceil(); // the column name is bold, so it needs a little more room than the cells
      for (final r in sample) {
        final len = _text(r[c]).length;
        if (len > longest) longest = len;
      }
      final w = longest * 7.2 + 28;
      out.add(w < 96 ? 96.0 : (w > 340 ? 340.0 : w));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.columns;
    final rows = widget.rows;
    if (rows.isEmpty || cols.isEmpty) {
      return const Text('No rows.', style: AppText.small);
    }
    final widths = _widths();
    var total = 0.0;
    for (final w in widths) {
      total += w;
    }
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: total,
              child: Column(
                children: <Widget>[
                  Container(
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.headerBg,
                      border: Border(bottom: BorderSide(color: AppColors.lapis, width: 1.5)),
                    ),
                    child: Row(
                      children: <Widget>[
                        for (var i = 0; i < cols.length; i++)
                          SizedBox(
                            width: widths[i],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  cols[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: kSans,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemExtent: 30,
                      itemBuilder: (context, index) {
                        final r = rows[index];
                        return Container(
                          color: index.isOdd ? AppColors.stripe : AppColors.surface,
                          child: Row(
                            children: <Widget>[
                              for (var i = 0; i < cols.length; i++)
                                SizedBox(
                                  width: widths[i],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _cell(r[cols[i]]),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(dynamic v) {
    if (v == null) {
      return const Text(
        'NULL',
        style: TextStyle(
          fontFamily: kSans,
          fontSize: 12.5,
          fontStyle: FontStyle.italic,
          color: Color(0xFF9AA1AD),
        ),
      );
    }
    final s = _text(v);
    final text = Text(
      s,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.cell,
    );
    if (s.length > 34) {
      return Tooltip(message: s, child: text);
    }
    return text;
  }
}

/// A row of tabs: the selected one is underlined in gold. On a narrow window the row scrolls sideways.
class AppTabs extends StatelessWidget {
  const AppTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < labels.length; i++)
              InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected ? AppColors.gold : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 14.5,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w400,
                      color: i == selected ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small button for a filter: outlined, filled with its colour when chosen.
class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.lapis,
    this.dot,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  /// a small square in the colour of a museum
  final Color? dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? color.withAlpha(28) : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: selected ? color : AppColors.line, width: selected ? 1.6 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (dot != null) ...<Widget>[
                  Container(width: 9, height: 9, color: dot),
                  const SizedBox(width: 7),
                ],
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kSans,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A white bar with one button per museum (and "All"): the museum filter of a screen.
class MuseumFilter extends StatelessWidget {
  const MuseumFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label = 'Museum',
  });

  /// the names on the buttons, for example All, Met, Cleveland, Louvre
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
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
          Text(label, style: AppText.small),
          for (final o in options)
            ChipButton(
              label: o,
              selected: selected == o,
              color: o == 'All' ? AppColors.lapis : AppColors.museum(o),
              dot: o == 'All' ? null : AppColors.museum(o),
              onTap: () => onChanged(o),
            ),
        ],
      ),
    );
  }
}

/// A one-line search box with a magnifier, used above lists (rulers, object types, sites).
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.width = 300,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppText.body,
        decoration: InputDecoration(
          hintText: hint,
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
    );
  }
}
