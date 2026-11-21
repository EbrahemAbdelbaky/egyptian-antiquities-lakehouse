import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'art.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------------------------
// The identity of the site: a sun disk in three bands, the three strata (Bronze, Silver, Gold), and a few
// motifs of Egyptian art, all drawn in code: the kheker frieze, the lotus, the cartouche.
// ---------------------------------------------------------------------------------------------

/// A sun disk cut into three bands: gold on top, silver, and bronze at the bottom.
/// These are the three layers of the pipeline, and the disk is the sun of Ra.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: const _MarkPainter());
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final gap = d * 0.05;
    final band = (d - gap * 2) / 3;
    const colors = <Color>[AppColors.goldLeaf, AppColors.silver, AppColors.bronze];
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, d, d)));
    for (var i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * (band + gap), d, band),
        Paint()..color = colors[i],
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A thin vertical strip in the three layer colours (gold at the top), used as the edge of the navigation.
class StrataStrip extends StatelessWidget {
  const StrataStrip({super.key, this.width = 4});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const Column(
        children: <Widget>[
          Expanded(flex: 3, child: ColoredBox(color: AppColors.goldLeaf, child: SizedBox.expand())),
          Expanded(flex: 2, child: ColoredBox(color: AppColors.silver, child: SizedBox.expand())),
          Expanded(flex: 2, child: ColoredBox(color: AppColors.bronze, child: SizedBox.expand())),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Motifs of Egyptian art
// ---------------------------------------------------------------------------------------------

/// The kheker frieze: a row of reed-bundle tops in blue, green and red with a gold band, standing on a gold line.
/// It ran along the top of Egyptian walls. With no [width] it fills the width it is given.
class Frieze extends StatelessWidget {
  const Frieze({super.key, this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height + 3,
      child: CustomPaint(
        size: Size(width ?? double.infinity, height + 3),
        painter: _FriezePainter(barHeight: height),
      ),
    );
  }
}

class _FriezePainter extends CustomPainter {
  const _FriezePainter({required this.barHeight});

  final double barHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final h = barHeight;
    final unit = h * 1.15;
    final bw = h * 0.62;
    final r = bw / 2;
    const colors = <Color>[AppColors.lapisBright, AppColors.faience, AppColors.carnelian];
    final band = Paint()..color = AppColors.goldLeaf;
    var i = 0;
    for (var x = 2.0; x + bw <= size.width; x += unit) {
      final bar = Path()
        ..moveTo(x, h)
        ..lineTo(x, r)
        ..arcToPoint(Offset(x + bw, r), radius: Radius.circular(r))
        ..lineTo(x + bw, h)
        ..close();
      canvas.drawPath(bar, Paint()..color = colors[i % colors.length]);
      canvas.drawRect(Rect.fromLTWH(x, h * 0.46, bw, h * 0.16), band);
      i++;
    }
    canvas.drawRect(Rect.fromLTWH(0, h, size.width, 2.4), band);
  }

  @override
  bool shouldRepaint(covariant _FriezePainter old) => old.barHeight != barHeight;
}

/// A small gold lotus, drawn from five petals. It marks the start of a section title.
class LotusMark extends StatelessWidget {
  const LotusMark({super.key, this.width = 26});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.8,
      child: const CustomPaint(painter: _LotusPainter()),
    );
  }
}

class _LotusPainter extends CustomPainter {
  const _LotusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 32);
    final fill = Paint()..color = AppColors.goldLeaf;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.goldDeep;

    void petal(double angle, double h, double w) {
      canvas.save();
      canvas.translate(20, 26);
      canvas.rotate(angle * math.pi / 180);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w, -h / 2, 0, -h)
        ..quadraticBezierTo(-w, -h / 2, 0, 0)
        ..close();
      canvas.drawPath(p, fill);
      canvas.drawPath(p, edge);
      canvas.restore();
    }

    petal(-52, 16, 6);
    petal(52, 16, 6);
    petal(-26, 22, 7);
    petal(26, 22, 7);
    petal(0, 26, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(13, 26, 14, 3), const Radius.circular(1.5)),
      Paint()..color = AppColors.goldDeep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A cartouche: the oval with a bar at one end in which the name of a king was written.
/// Used here for names of rulers and for the label of the Gold layer.
class Cartouche extends StatelessWidget {
  const Cartouche({
    super.key,
    required this.child,
    this.color = AppColors.goldDeep,
    this.background = AppColors.surface,
    this.compact = false,
  });

  final Widget child;
  final Color color;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final v = compact ? 4.0 : 6.0;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 18, v, compact ? 22 : 30, v),
          decoration: ShapeDecoration(
            color: background,
            shape: StadiumBorder(side: BorderSide(color: color, width: 1.8)),
          ),
          child: child,
        ),
        Positioned(
          right: compact ? 11 : 15,
          top: -4,
          bottom: -4,
          child: Container(width: 1.8, color: color),
        ),
      ],
    );
  }
}

/// The one big symbol of the Overview, beside the title: Sema-tawy, "the union of the two lands".
/// The papyrus of Lower Egypt and the lotus of Upper Egypt are tied together under the sun. It stands for Egypt
/// itself and, here, for three museums united in one layer.
class HeroEmblem extends StatelessWidget {
  const HeroEmblem({super.key, required this.art, this.size = 230});

  /// the name of the motif in art.dart
  final String art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF14365F)),
          ),
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldLeaf.withAlpha(110), width: 1.4),
            ),
          ),
          ArtMark(art, width: size * 0.74, color: AppColors.goldLeaf, soft: const Color(0xFF2F63AE)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// The hero of the Overview
// ---------------------------------------------------------------------------------------------

/// One layer of the section drawing: its name, one line about it, and its colours.
class StrataLayer {
  const StrataLayer({
    required this.name,
    required this.text,
    required this.fill,
    required this.textColor,
  });

  final String name;
  final String text;
  final Color fill;
  final Color textColor;
}

/// The top of the Overview: a frieze, the title beside one big symbol, and a section through three strata,
/// drawn the way an excavation section is drawn. The top stratum is Gold, the layer this site shows;
/// below it lie Silver and Bronze.
class StrataHero extends StatelessWidget {
  const StrataHero({
    super.key,
    required this.title,
    required this.lead,
    required this.layers,
    this.tag,
    this.art = 'sematawy',
  });

  final String title;
  final String lead;

  /// the symbol of the screen, shown large beside the title
  final String art;

  /// from the top stratum to the bottom one
  final List<StrataLayer> layers;

  /// a label shown in a cartouche at the right of the top stratum on a wide window
  final String? tag;

  static const double _margin = 12;
  static const double _tagReserve = 276;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final wide = constraints.maxWidth >= 1000;
        final pad = narrow ? 20.0 : 40.0;
        final bandH = narrow ? 84.0 : 62.0;
        final strataH = _margin + bandH * layers.length + 14;
        final tagText = tag;

        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: narrow ? 31 : 46,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                lead,
                style: TextStyle(
                  fontFamily: kSans,
                  fontSize: narrow ? 15 : 17,
                  color: const Color(0xFFC3CFE2),
                  height: 1.5,
                ),
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          color: AppColors.lapisDeep,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Frieze(height: 16),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, narrow ? 22 : 34, pad, narrow ? 26 : 34),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(child: textBlock),
                          const SizedBox(width: 28),
                          HeroEmblem(art: art, size: 240),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          HeroEmblem(art: art, size: narrow ? 132 : 160),
                          const SizedBox(height: 18),
                          textBlock,
                        ],
                      ),
              ),
              SizedBox(
                height: strataH,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StrataPainter(
                          top: _margin,
                          bandH: bandH,
                          fills: <Color>[for (final l in layers) l.fill],
                          pebbles: !narrow,
                        ),
                      ),
                    ),
                    for (var i = 0; i < layers.length; i++)
                      Positioned(
                        left: pad,
                        right: pad + ((i == 0 && tagText != null && !narrow) ? _tagReserve : 0),
                        top: _margin + bandH * i + 5,
                        height: bandH - 8,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _label(layers[i], narrow),
                        ),
                      ),
                    if (tagText != null && !narrow)
                      Positioned(
                        right: pad,
                        top: _margin + 5,
                        height: bandH - 8,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Cartouche(
                            compact: true,
                            color: layers.first.textColor,
                            background: Colors.transparent,
                            child: Text(
                              tagText,
                              style: TextStyle(
                                fontFamily: kSans,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: layers.first.textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(StrataLayer l, bool narrow) {
    if (narrow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.name,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: l.textColor,
            ),
          ),
          Text(
            l.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: kSans, fontSize: 13.5, color: l.textColor, height: 1.3),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          l.name,
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: l.textColor,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            l.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: kSans, fontSize: 15, color: l.textColor, height: 1.3),
          ),
        ),
      ],
    );
  }
}

/// Paints the strata: wavy contact lines, stipple, and a few outlined stones, like an excavation section drawing.
class _StrataPainter extends CustomPainter {
  const _StrataPainter({
    required this.top,
    required this.bandH,
    required this.fills,
    required this.pebbles,
  });

  final double top;
  final double bandH;
  final List<Color> fills;
  final bool pebbles;

  /// y of the contact line k (0 = the surface, 1 = between the first two layers, ...) at x
  double _edge(int k, double x) {
    final base = top + bandH * k;
    final a = k == 0 ? 6.5 : 4.5;
    return base + a * math.sin(x / 110 + k * 1.9) + a * 0.5 * math.sin(x / 37 + k * 0.7);
  }

  List<double> _xs(double width) {
    final out = <double>[];
    var x = 0.0;
    while (x < width) {
      out.add(x);
      x += 6;
    }
    out.add(width);
    return out;
  }

  Path _band(Size size, int k) {
    final xs = _xs(size.width);
    final p = Path()..moveTo(xs.first, _edge(k, xs.first));
    for (final x in xs.skip(1)) {
      p.lineTo(x, _edge(k, x));
    }
    if (k + 1 >= fills.length) {
      p.lineTo(size.width, size.height);
      p.lineTo(0, size.height);
    } else {
      for (final x in xs.reversed) {
        p.lineTo(x, _edge(k + 1, x));
      }
    }
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    final dark = Paint()
      ..color = const Color(0x2E000000)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final light = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var k = 0; k < fills.length; k++) {
      final path = _band(size, k);
      canvas.drawPath(path, Paint()..color = fills[k]);
      canvas.save();
      canvas.clipPath(path);
      final dotsDark = <Offset>[];
      final dotsLight = <Offset>[];
      final count = (size.width * bandH / 150).round();
      for (var i = 0; i < count; i++) {
        final x = rnd.nextDouble() * size.width;
        final y = top + bandH * k - 8 + rnd.nextDouble() * (bandH + 24);
        if (i.isEven) {
          dotsDark.add(Offset(x, y));
        } else {
          dotsLight.add(Offset(x, y));
        }
      }
      canvas.drawPoints(ui.PointMode.points, dotsDark, dark);
      canvas.drawPoints(ui.PointMode.points, dotsLight, light);
      canvas.restore();
    }

    if (pebbles && fills.length > 2) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0x55000000);
      final n = (size.width / 120).floor();
      for (var i = 0; i < n; i++) {
        final k = 1 + (i % 2);
        final x = size.width * (0.62 + 0.35 * rnd.nextDouble());
        final y = top + bandH * k + bandH * (0.3 + 0.4 * rnd.nextDouble());
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rnd.nextDouble() * math.pi);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: 14 + rnd.nextDouble() * 22,
            height: 8 + rnd.nextDouble() * 10,
          ),
          stroke,
        );
        canvas.restore();
      }
    }

    final contact = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0x59000000);
    final xs = _xs(size.width);
    for (var k = 0; k < fills.length; k++) {
      final line = Path()..moveTo(xs.first, _edge(k, xs.first));
      for (final x in xs.skip(1)) {
        line.lineTo(x, _edge(k, x));
      }
      canvas.drawPath(line, contact);
    }
  }

  @override
  bool shouldRepaint(covariant _StrataPainter old) {
    return old.top != top || old.bandH != bandH || old.pebbles != pebbles || old.fills.length != fills.length;
  }
}
