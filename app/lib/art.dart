import 'package:flutter/material.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------------------------
// Egyptian motifs drawn from path data. Each one marks the screen it stands for:
//   sematawy (the hero of the Overview), lotus (Overview in the menu), djed (Structure), cartouche (Hierarchy), papyrus (Documentation gaps),
//   scarab (Time, types and sites), feather of Maat (Quality checks), ibis of Thoth (Machine learning),
//   and the ankh, used for bullets.
// Each motif is a list of shapes (absolute SVG-style paths: M L C Q Z). 'p' is the main colour and 's' the soft one.
// ---------------------------------------------------------------------------------------------

class ArtShape {
  const ArtShape(this.d, {this.fill, this.stroke, this.sw = 0, this.round = true, this.alpha = 1});

  final String d;
  final String? fill;
  final String? stroke;
  final double sw;
  final bool round;
  final double alpha;
}

class ArtSpec {
  const ArtSpec(this.w, this.h, this.shapes);

  final double w;
  final double h;
  final List<ArtShape> shapes;
}

final Map<String, Path> _pathCache = <String, Path>{};

/// Reads a path made of absolute M, L, C, Q and Z commands.
Path _parsePath(String d) {
  final cached = _pathCache[d];
  if (cached != null) return cached;
  final path = Path();
  final tokens = RegExp(r'[MLCQZ]|-?[0-9]+\.?[0-9]*').allMatches(d).map((m) => m.group(0) ?? '').toList();
  var i = 0;
  var cmd = '';
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'M' || t == 'L' || t == 'C' || t == 'Q' || t == 'Z') {
      cmd = t;
      i++;
      if (cmd == 'Z') path.close();
      continue;
    }
    if (cmd == 'M') {
      path.moveTo(next(), next());
      cmd = 'L';
    } else if (cmd == 'L') {
      path.lineTo(next(), next());
    } else if (cmd == 'C') {
      path.cubicTo(next(), next(), next(), next(), next(), next());
    } else if (cmd == 'Q') {
      path.quadraticBezierTo(next(), next(), next(), next());
    } else {
      i++;
    }
  }
  _pathCache[d] = path;
  return path;
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter(this.spec, this.primary, this.soft);

  final ArtSpec spec;
  final Color primary;
  final Color soft;

  Color? _colour(String? key, double alpha) {
    if (key == null) return null;
    Color c;
    if (key == 'p') {
      c = primary;
    } else if (key == 's') {
      c = soft;
    } else {
      c = Color(int.parse('FF${key.substring(1)}', radix: 16));
    }
    return alpha < 1 ? c.withAlpha((alpha * 255).round()) : c;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / spec.w, size.height / spec.h);
    for (final s in spec.shapes) {
      final path = _parsePath(s.d);
      final fill = _colour(s.fill, s.alpha);
      if (fill != null) {
        canvas.drawPath(path, Paint()..style = PaintingStyle.fill..color = fill);
      }
      final stroke = _colour(s.stroke, s.alpha);
      if (stroke != null && s.sw > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s.sw
            ..strokeCap = s.round ? StrokeCap.round : StrokeCap.butt
            ..strokeJoin = StrokeJoin.round
            ..color = stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) {
    return old.spec != spec || old.primary != primary || old.soft != soft;
  }
}

/// One motif at a given [width]; the height follows the shape of the motif.
class ArtMark extends StatelessWidget {
  const ArtMark(this.name, {super.key, this.width = 24, this.color = AppColors.ink, this.soft});

  final String name;
  final double width;
  final Color color;
  final Color? soft;

  @override
  Widget build(BuildContext context) {
    final spec = kArt[name];
    if (spec == null) return SizedBox(width: width, height: width);
    return SizedBox(
      width: width,
      height: width * spec.h / spec.w,
      child: CustomPaint(
        painter: _ArtPainter(spec, color, soft ?? (Color.lerp(color, Colors.white, 0.6) ?? color)),
      ),
    );
  }
}

const Map<String, ArtSpec> kArt = <String, ArtSpec>{
  'djed': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M21.50,12.00 L26.50,12.00 L28.00,40.00 L20.00,40.00 Z', fill: 'p'),
    ArtShape('M16.00,40.00 L32.00,40.00 L32.00,43.60 L16.00,43.60 Z', fill: 'p'),
    ArtShape('M15.00,4.00 L33.00,4.00 L33.00,8.40 L15.00,8.40 Z', fill: 'p'),
    ArtShape('M12.00,10.00 L36.00,10.00 L36.00,14.40 L12.00,14.40 Z', fill: 'p'),
    ArtShape('M12.00,16.00 L36.00,16.00 L36.00,20.40 L12.00,20.40 Z', fill: 'p'),
    ArtShape('M15.00,22.00 L33.00,22.00 L33.00,26.40 L15.00,26.40 Z', fill: 'p'),
  ]),
  'papyrus': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M9,10 L39,10 L39,32 L36,35 L38,38 L9,38 Z', stroke: 'p', sw: 3, round: false),
    ArtShape('M13.00,24.00 C13.00,31.73 11.21,38.00 9.00,38.00 C6.79,38.00 5.00,31.73 5.00,24.00 C5.00,16.27 6.79,10.00 9.00,10.00 C11.21,10.00 13.00,16.27 13.00,24.00 Z', fill: 's', stroke: 'p', sw: 2.6),
    ArtShape('M16.00,17.00 L32.00,17.00', stroke: 'p', sw: 3),
    ArtShape('M16.00,24.00 L21.00,24.00', stroke: 'p', sw: 3),
    ArtShape('M28.00,24.00 L32.00,24.00', stroke: 'p', sw: 3),
    ArtShape('M16.00,31.00 L23.00,31.00', stroke: 'p', sw: 3),
  ]),
  'ibis': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M13,26 C15,20 25,18 32,21 C38,23 43,29 45,37 C39,35 36,38 29,38 C20,38 12,33 13,26 Z', fill: 'p'),
    ArtShape('M17,25 C9,22 8,15 12,9', stroke: 'p', sw: 3.2),
    ArtShape('M15.50,8.40 C15.50,10.00 14.20,11.30 12.60,11.30 C11.00,11.30 9.70,10.00 9.70,8.40 C9.70,6.80 11.00,5.50 12.60,5.50 C14.20,5.50 15.50,6.80 15.50,8.40 Z', fill: 'p'),
    ArtShape('M10.6,7.4 C5,7.4 1.6,11.6 1.6,19.5 C3.6,14.5 6.6,12.2 11.4,11.4 Z', fill: 'p'),
    ArtShape('M13.50,7.80 C13.50,8.30 13.10,8.70 12.60,8.70 C12.10,8.70 11.70,8.30 11.70,7.80 C11.70,7.30 12.10,6.90 12.60,6.90 C13.10,6.90 13.50,7.30 13.50,7.80 Z', fill: 's'),
    ArtShape('M24.00,38.00 L24.00,46.50', stroke: 'p', sw: 2.2),
    ArtShape('M29.00,38.00 L29.00,46.50', stroke: 'p', sw: 2.2),
    ArtShape('M20.50,46.50 L27.50,46.50', stroke: 'p', sw: 2),
    ArtShape('M25.50,46.50 L32.50,46.50', stroke: 'p', sw: 2),
  ]),
  'ankh': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M32.50,15.00 C32.50,21.08 28.69,26.00 24.00,26.00 C19.31,26.00 15.50,21.08 15.50,15.00 C15.50,8.92 19.31,4.00 24.00,4.00 C28.69,4.00 32.50,8.92 32.50,15.00 Z', stroke: 'p', sw: 5, round: false),
    ArtShape('M24.00,26.00 L24.00,44.00', stroke: 'p', sw: 5.4, round: false),
    ArtShape('M10.00,31.00 L38.00,31.00', stroke: 'p', sw: 5.4, round: false),
  ]),
  'feather': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M24,3 C36,11 38,27 30,38 L24,45 L18,38 C10,27 12,11 24,3 Z', fill: 's', stroke: 'p', sw: 2.6),
    ArtShape('M24.00,9.00 L24.00,45.00', stroke: 'p', sw: 2.6),
    ArtShape('M24.00,18.00 L31.00,13.00', stroke: 'p', sw: 2),
    ArtShape('M24.00,26.00 L33.00,20.00', stroke: 'p', sw: 2),
    ArtShape('M24.00,18.00 L17.00,13.00', stroke: 'p', sw: 2),
    ArtShape('M24.00,26.00 L15.00,20.00', stroke: 'p', sw: 2),
  ]),
  'scarab': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M29.00,10.00 C29.00,12.76 26.76,15.00 24.00,15.00 C21.24,15.00 19.00,12.76 19.00,10.00 C19.00,7.24 21.24,5.00 24.00,5.00 C26.76,5.00 29.00,7.24 29.00,10.00 Z', fill: 's'),
    ArtShape('M36.00,30.00 C36.00,38.28 30.63,45.00 24.00,45.00 C17.37,45.00 12.00,38.28 12.00,30.00 C12.00,21.72 17.37,15.00 24.00,15.00 C30.63,15.00 36.00,21.72 36.00,30.00 Z', fill: 'p'),
    ArtShape('M31.00,15.50 C31.00,18.26 27.87,20.50 24.00,20.50 C20.13,20.50 17.00,18.26 17.00,15.50 C17.00,12.74 20.13,10.50 24.00,10.50 C27.87,10.50 31.00,12.74 31.00,15.50 Z', fill: 'p'),
    ArtShape('M24.00,19.00 L24.00,45.00', stroke: 's', sw: 1.6),
    ArtShape('M12.00,24.00 L4.00,20.00', stroke: 'p', sw: 2.6),
    ArtShape('M12.00,32.00 L3.00,34.00', stroke: 'p', sw: 2.6),
    ArtShape('M13.00,40.00 L6.00,45.00', stroke: 'p', sw: 2.6),
    ArtShape('M36.00,24.00 L44.00,20.00', stroke: 'p', sw: 2.6),
    ArtShape('M36.00,32.00 L45.00,34.00', stroke: 'p', sw: 2.6),
    ArtShape('M35.00,40.00 L42.00,45.00', stroke: 'p', sw: 2.6),
  ]),
  'lotus': ArtSpec(40, 32, <ArtShape>[
    ArtShape('M20.00,26.00 Q17.39,16.35 7.39,16.15 Q10.00,25.80 20.00,26.00 Z', fill: 'p'),
    ArtShape('M20.00,26.00 Q30.00,25.80 32.61,16.15 Q22.61,16.35 20.00,26.00 Z', fill: 'p'),
    ArtShape('M20.00,26.00 Q21.47,13.04 10.36,6.23 Q8.89,19.18 20.00,26.00 Z', fill: 'p', stroke: 's', sw: 0.9),
    ArtShape('M20.00,26.00 Q31.11,19.18 29.64,6.23 Q18.53,13.04 20.00,26.00 Z', fill: 'p', stroke: 's', sw: 0.9),
    ArtShape('M20.00,26.00 Q28.00,13.00 20.00,0.00 Q12.00,13.00 20.00,26.00 Z', fill: 's', stroke: 'p', sw: 1.6),
    ArtShape('M13.00,26.00 L27.00,26.00 L27.00,29.40 L13.00,29.40 Z', fill: 'p'),
  ]),
  'cartouche': ArtSpec(48, 48, <ArtShape>[
    ArtShape('M15,12 L33,12 C39.6,12 45,17.4 45,24 C45,30.6 39.6,36 33,36 L15,36 C8.4,36 3,30.6 3,24 C3,17.4 8.4,12 15,12 Z', fill: 's', stroke: 'p', sw: 3.2),
    ArtShape('M36.00,7.00 L36.00,41.00', stroke: 'p', sw: 3.2, round: false),
    ArtShape('M15.60,24.00 C15.60,25.44 14.44,26.60 13.00,26.60 C11.56,26.60 10.40,25.44 10.40,24.00 C10.40,22.56 11.56,21.40 13.00,21.40 C14.44,21.40 15.60,22.56 15.60,24.00 Z', fill: 'p'),
    ArtShape('M23.10,24.00 C23.10,25.44 21.94,26.60 20.50,26.60 C19.06,26.60 17.90,25.44 17.90,24.00 C17.90,22.56 19.06,21.40 20.50,21.40 C21.94,21.40 23.10,22.56 23.10,24.00 Z', fill: 'p'),
    ArtShape('M30.60,24.00 C30.60,25.44 29.44,26.60 28.00,26.60 C26.56,26.60 25.40,25.44 25.40,24.00 C25.40,22.56 26.56,21.40 28.00,21.40 C29.44,21.40 30.60,22.56 30.60,24.00 Z', fill: 'p'),
  ]),
  'sematawy': ArtSpec(64, 56, <ArtShape>[
    ArtShape('M32,52 C32,43 14,43 14,34', stroke: 'p', sw: 3.2),
    ArtShape('M32,52 C32,43 50,43 50,34', stroke: 'p', sw: 3.2),
    ArtShape('M17.80,34.50 C17.80,35.83 16.10,36.90 14.00,36.90 C11.90,36.90 10.20,35.83 10.20,34.50 C10.20,33.17 11.90,32.10 14.00,32.10 C16.10,32.10 17.80,33.17 17.80,34.50 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L1.42,24.83', stroke: 'p', sw: 1.6),
    ArtShape('M2.72,24.83 C2.72,25.55 2.14,26.13 1.42,26.13 C0.70,26.13 0.12,25.55 0.12,24.83 C0.12,24.11 0.70,23.53 1.42,23.53 C2.14,23.53 2.72,24.11 2.72,24.83 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L5.65,23.97', stroke: 'p', sw: 1.6),
    ArtShape('M6.95,23.97 C6.95,24.69 6.37,25.27 5.65,25.27 C4.93,25.27 4.35,24.69 4.35,23.97 C4.35,23.25 4.93,22.67 5.65,22.67 C6.37,22.67 6.95,23.25 6.95,23.97 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L6.84,19.82', stroke: 'p', sw: 1.6),
    ArtShape('M8.14,19.82 C8.14,20.54 7.56,21.12 6.84,21.12 C6.12,21.12 5.54,20.54 5.54,19.82 C5.54,19.10 6.12,18.52 6.84,18.52 C7.56,18.52 8.14,19.10 8.14,19.82 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L10.97,21.08', stroke: 'p', sw: 1.6),
    ArtShape('M12.27,21.08 C12.27,21.80 11.69,22.38 10.97,22.38 C10.25,22.38 9.67,21.80 9.67,21.08 C9.67,20.36 10.25,19.78 10.97,19.78 C11.69,19.78 12.27,20.36 12.27,21.08 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L14.00,18.00', stroke: 'p', sw: 1.6),
    ArtShape('M15.30,18.00 C15.30,18.72 14.72,19.30 14.00,19.30 C13.28,19.30 12.70,18.72 12.70,18.00 C12.70,17.28 13.28,16.70 14.00,16.70 C14.72,16.70 15.30,17.28 15.30,18.00 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L17.03,21.08', stroke: 'p', sw: 1.6),
    ArtShape('M18.33,21.08 C18.33,21.80 17.75,22.38 17.03,22.38 C16.31,22.38 15.73,21.80 15.73,21.08 C15.73,20.36 16.31,19.78 17.03,19.78 C17.75,19.78 18.33,20.36 18.33,21.08 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L21.16,19.82', stroke: 'p', sw: 1.6),
    ArtShape('M22.46,19.82 C22.46,20.54 21.88,21.12 21.16,21.12 C20.44,21.12 19.86,20.54 19.86,19.82 C19.86,19.10 20.44,18.52 21.16,18.52 C21.88,18.52 22.46,19.10 22.46,19.82 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L22.35,23.97', stroke: 'p', sw: 1.6),
    ArtShape('M23.65,23.97 C23.65,24.69 23.07,25.27 22.35,25.27 C21.63,25.27 21.05,24.69 21.05,23.97 C21.05,23.25 21.63,22.67 22.35,22.67 C23.07,22.67 23.65,23.25 23.65,23.97 Z', fill: 'p'),
    ArtShape('M14.00,33.00 L26.58,24.83', stroke: 'p', sw: 1.6),
    ArtShape('M27.88,24.83 C27.88,25.55 27.30,26.13 26.58,26.13 C25.86,26.13 25.28,25.55 25.28,24.83 C25.28,24.11 25.86,23.53 26.58,23.53 C27.30,23.53 27.88,24.11 27.88,24.83 Z', fill: 'p'),
    ArtShape('M50.00,34.00 Q47.72,24.86 38.39,26.17 Q40.67,35.31 50.00,34.00 Z', fill: 's', stroke: 'p', sw: 1.1),
    ArtShape('M50.00,34.00 Q59.33,35.31 61.61,26.17 Q52.28,24.86 50.00,34.00 Z', fill: 's', stroke: 'p', sw: 1.1),
    ArtShape('M50.00,34.00 Q51.66,21.79 40.61,16.34 Q38.95,28.55 50.00,34.00 Z', fill: 's', stroke: 'p', sw: 1.1),
    ArtShape('M50.00,34.00 Q61.05,28.55 59.39,16.34 Q48.34,21.79 50.00,34.00 Z', fill: 's', stroke: 'p', sw: 1.1),
    ArtShape('M50.00,34.00 Q57.80,21.50 50.00,9.00 Q42.20,21.50 50.00,34.00 Z', fill: 'p'),
    ArtShape('M24.00,41.00 L40.00,41.00 L40.00,44.00 L24.00,44.00 Z', fill: 's', stroke: 'p', sw: 1),
    ArtShape('M24.00,47.00 L40.00,47.00 L40.00,50.00 L24.00,50.00 Z', fill: 's', stroke: 'p', sw: 1),
    ArtShape('M38.40,17.00 C38.40,20.53 35.53,23.40 32.00,23.40 C28.47,23.40 25.60,20.53 25.60,17.00 C25.60,13.47 28.47,10.60 32.00,10.60 C35.53,10.60 38.40,13.47 38.40,17.00 Z', fill: 'p'),
    ArtShape('M35.20,17.00 C35.20,18.77 33.77,20.20 32.00,20.20 C30.23,20.20 28.80,18.77 28.80,17.00 C28.80,15.23 30.23,13.80 32.00,13.80 C33.77,13.80 35.20,15.23 35.20,17.00 Z', fill: 's'),
  ]),
};

