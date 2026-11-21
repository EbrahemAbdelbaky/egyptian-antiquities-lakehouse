import 'package:flutter/material.dart';

import '../data/gold_data.dart';
import '../widgets.dart';
import 'sites_tab.dart';
import 'time_tab.dart';
import 'types_tab.dart';

/// Three views of the artifacts that are not about the rulers: when they entered the museums, what they are, and where
/// they were found. Everything is read from three views of Gold: v_gap_by_accession_year, v_gap_by_object_type, v_site_map.
class TimeTypesSitesScreen extends StatefulWidget {
  const TimeTypesSitesScreen({super.key, required this.data});

  final GoldData data;

  @override
  State<TimeTypesSitesScreen> createState() => _TimeTypesSitesScreenState();
}

class _TimeTypesSitesScreenState extends State<TimeTypesSitesScreen> {
  int _tab = 0;

  Widget _content() {
    switch (_tab) {
      case 1:
        return TypesTab(key: const ValueKey<String>('types'), data: widget.data);
      case 2:
        return SitesTab(key: const ValueKey<String>('sites'), data: widget.data);
      default:
        return TimeTab(key: const ValueKey<String>('time'), data: widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Time, types and sites',
      subtitle: 'When the artifacts entered the museums, what they are, and where they were found.',
      art: 'scarab',
      children: <Widget>[
        const AboutBox(
          lines: <String>[
            'Besides its ruler and period, Gold keeps three more facts about an artifact: the year the museum acquired it, what kind of object it is, '
                'and the place where it was found. This screen shows each of them and how well the artifacts are documented along it.',
            'Time. Only the Met and Cleveland give an accession year; the Louvre has none in Gold, so it does not appear in this tab. '
                'The average of a decade is weighted by the number of artifacts, and a hollow point is a decade with fewer than 30 artifacts.',
            'Object types. Each museum names its types in its own words: the Louvre in French and in free text, the Met in free English, '
                'and Cleveland with 27 fixed classes. The three lists are therefore not merged, and a type is shown exactly as written. '
                'The English words in italics are this project\'s own translation of common French terms. They are not part of the data.',
            'Find sites. A site is on the map only when Silver linked its name to Wikidata, which gives it coordinates. Silver links the site names '
                'of all three museums: the Met names directly, the Louvre French names without accents and through a short list of corrections made by hand. '
                'Where a Louvre text names only a part of a site (a tomb in the Valley of the Kings, for example), the site is linked as an approximate area. '
                'The distance between the artifacts that have a find site and those on the map is a gap in linking, not a gap in the collections. '
                'The outline of Egypt is drawn by hand for orientation.',
            'The numbers come from the Gold views v_gap_by_accession_year, v_gap_by_object_type and v_site_map.',
          ],
        ),
        const SizedBox(height: 18),
        AppTabs(
          labels: const <String>['Time', 'Object types', 'Find sites'],
          selected: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 22),
        _content(),
      ],
    );
  }
}
