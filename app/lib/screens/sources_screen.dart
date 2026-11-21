import 'package:flutter/material.dart';

import '../data/fmt.dart';
import '../data/gold_data.dart';
import '../theme.dart';
import '../widgets.dart';

/// The date the Louvre file (exported from collections.louvre.fr) was loaded into Bronze (bronze.load_log, 2026-11-13 16:09).
/// The Etalab licence asks for the date of the data next to the credit.
const String kLouvreDataDate = '13 November 2026';

/// The date the Pleiades file was loaded into Bronze (bronze.load_log, 2026-11-13 11:33). The DOI below is the one of the whole dataset series
/// (every release), so the credit stays correct whichever release the download was.
const String kPleiadesDate = '13 November 2026';
const String kPleiadesCredit = 'Pleiades Datasets (all releases: DOI 10.5281/zenodo.1193921), loaded into this project on $kPleiadesDate';

/// Where the data comes from, under which licence, and how each source is credited.
/// The museum rows are read from dim_museum (data_license, image_license, source_url); the rest is text.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key, required this.data});

  final GoldData data;

  @override
  Widget build(BuildContext context) {
    final museums = data.rows('dim_museum');
    return PageScaffold(
      title: 'Sources and licences',
      subtitle: 'Where the data comes from, under which licence, and how each source is credited.',
      art: 'ankh',
      children: <Widget>[
        const AboutBox(
          initiallyOpen: true,
          lines: <String>[
            'This site publishes counts, percentages and small samples of museum records (title, object number, object type and date text). '
                'It shows no museum image and loads none. For any object, the museum\'s own page is the reference.',
            'The licences below were checked on 21 November 2026. The Met, Cleveland and Wikidata data are released as CC0 and need no credit; '
                'they are credited here anyway. The Louvre texts need a credit and the date of the data, and Pleiades needs attribution.',
          ],
        ),
        const SizedBox(height: 22),
        Panel(
          title: 'Museum records',
          caption: 'The licence, the image licence and the source address of each museum are read from the Gold table dim_museum.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < museums.length; i++) ...<Widget>[
                if (i > 0) const _Rule(),
                _MuseumBlock(museum: museums[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Panel(
          title: 'Linked reference data',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Entry('Wikidata', 'Rulers (names, aliases, Q numbers) and sites (coordinates). Released as CC0. https://www.wikidata.org'),
              _Entry(
                'Pleiades',
                'Ancient places, used to check the sites. Licence CC BY 3.0. $kPleiadesCredit. Tom Elliott, Richard Talbert, Roger Bagnall, '
                    'Jeffrey Becker, Sarah Bond, Sean Gillies, Lindsay Holman, Ryan Horne, Gabe Moss, Adam Rabinowitz, Elizabeth Robinson, '
                    'Brian Turner. https://pleiades.stoa.org',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Panel(
          title: 'Images',
          child: Text(
            'This site shows no museum images. Louvre images are not open by licence: the Louvre allows medium-size images only for private, '
            'scientific and educational use, and licenses any commercial use. The Met and Cleveland images are open only for works in the public domain.',
            style: AppText.body,
          ),
        ),
        const SizedBox(height: 18),
        const Panel(
          title: 'Independence',
          child: Text(
            'This is a university project in data mining and data warehousing. It is not endorsed by, or connected to, the museums or the other '
            'data providers named on this page. The numbers describe how open records are documented; they are not statements about the collections themselves.',
            style: AppText.body,
          ),
        ),
        const SizedBox(height: 18),
        const Panel(
          title: 'Fonts',
          caption: 'The licence texts are in the licenses folder published with this site.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Entry('Serif', 'TeX Gyre Pagella, GUST Font License. The files are subsets (glyphs removed, nothing else changed), renamed Gold Serif.'),
              _Entry('Sans', 'Carlito, SIL Open Font License 1.1. The files are subsets (glyphs removed, nothing else changed), renamed Gold Sans because the licence reserves the name Carlito.'),
              _Entry('Mono', 'DejaVu Sans Mono, Bitstream Vera and DejaVu licence.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _MuseumBlock extends StatelessWidget {
  const _MuseumBlock({required this.museum});

  final Rec museum;

  @override
  Widget build(BuildContext context) {
    final name = toStr(museum['museum_name']);
    final full = toStr(museum['museum_full_name']);
    final country = toStr(museum['country']);
    final isLouvre = name == 'Louvre';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(country.isEmpty ? full : '$full ($country)', style: AppText.h3),
        const SizedBox(height: 8),
        _Entry('Data licence', toStr(museum['data_license'])),
        _Entry('Images', toStr(museum['image_license'])),
        _Entry('Source', toStr(museum['source_url'])),
        if (isLouvre)
          _Entry(
            'Credit',
            'Musée du Louvre, collections.louvre.fr. Data exported from that site and loaded into this project on $kLouvreDataDate. Used under the Etalab Open Licence; '
                'the Louvre does not endorse this project.',
          ),
      ],
    );
  }
}

/// A label on the left and a value on the right (the value can be selected and copied).
class _Entry extends StatelessWidget {
  const _Entry(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 104, child: Text(label, style: AppText.small)),
          Expanded(child: SelectableText(value, style: AppText.body)),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: AppColors.line),
    );
  }
}
