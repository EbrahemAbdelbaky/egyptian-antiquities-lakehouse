import 'package:flutter/material.dart';

import 'art.dart';
import 'brand.dart';
import 'data/fmt.dart';
import 'data/gold_data.dart';
import 'screens/documentation_gaps_screen.dart';
import 'screens/hierarchy_screen.dart';
import 'screens/machine_learning_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/quality_checks_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/structure_screen.dart';
import 'screens/time_types_sites_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class _NavItem {
  const _NavItem(this.label, this.art);
  final String label;

  /// the name of the motif in art.dart that marks this screen
  final String art;
}

/// The eight screens. The position in this list is the screen number used by AppShell.
const List<_NavItem> _navItems = <_NavItem>[
  _NavItem('Overview', 'lotus'),
  _NavItem('Structure', 'djed'),
  _NavItem('Hierarchy', 'cartouche'),
  _NavItem('Documentation gaps', 'papyrus'),
  _NavItem('Time, types and sites', 'scarab'),
  _NavItem('Quality checks', 'feather'),
  _NavItem('Machine learning', 'ibis'),
  _NavItem('Sources and licences', 'ankh'),
];

class _NavGroup {
  const _NavGroup(this.title, this.items);
  final String title;
  final List<int> items;
}

const List<_NavGroup> _navGroups = <_NavGroup>[
  _NavGroup('Explore the model', <int>[0, 1, 2]),
  _NavGroup('Analyse', <int>[3, 4, 6]),
  _NavGroup('Verify', <int>[5]),
  _NavGroup('About', <int>[7]),
];

class _Plan {
  const _Plan(this.lead, this.items);
  final String lead;
  final List<String> items;
}

/// What each screen that is not built yet will show (the number is the position in _navItems).
const Map<int, _Plan> _plans = <int, _Plan>{};

/// A navigation panel on the left on a wide window; on a narrow one (phone) a top bar with a menu button.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.data});

  final GoldData data;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  Widget _screen() {
    switch (_index) {
      case 0:
        return OverviewScreen(
          data: widget.data,
          onOpen: (i) => setState(() => _index = i),
        );
      case 1:
        return StructureScreen(data: widget.data);
      case 2:
        return HierarchyScreen(data: widget.data);
      case 3:
        return DocumentationGapsScreen(data: widget.data);
      case 4:
        return TimeTypesSitesScreen(data: widget.data);
      case 5:
        return QualityChecksScreen(data: widget.data);
      case 6:
        return MachineLearningScreen(data: widget.data);
      case 7:
        return SourcesScreen(data: widget.data);
      default:
        return _plannedScreen();
    }
  }

  /// A screen that is not built yet says what it will show. The data for it is already in the export.
  Widget _plannedScreen() {
    final plan = _plans[_index];
    final item = _navItems[_index];
    return PageScaffold(
      title: item.label,
      subtitle: 'This screen is built in a later step.',
      art: item.art,
      children: <Widget>[
        Panel(
          title: 'What this screen will show',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (plan != null) ...<Widget>[
                Text(plan.lead, style: AppText.lead),
                const SizedBox(height: 12),
                for (final line in plan.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 10),
                          child: ArtMark('ankh', width: 14, color: AppColors.goldDeep),
                        ),
                        Expanded(child: Text(line, style: AppText.body)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final nav = _NavPanel(
          data: widget.data,
          selected: _index,
          onSelect: (i) {
            setState(() => _index = i);
            if (narrow) _scaffoldKey.currentState?.closeDrawer();
          },
        );
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.paper,
          appBar: narrow
              ? AppBar(
                  backgroundColor: AppColors.sidebar,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  titleSpacing: 0,
                  title: Row(
                    children: <Widget>[
                      const BrandMark(size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _navItems[_index].label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, thickness: 1, color: AppColors.line),
                  ),
                )
              : null,
          drawer: narrow
              ? Drawer(
                  width: 292,
                  backgroundColor: AppColors.sidebar,
                  shape: const RoundedRectangleBorder(),
                  child: nav,
                )
              : null,
          body: narrow
              ? _screen()
              : Row(
                  children: <Widget>[
                    SizedBox(width: 268, child: nav),
                    Expanded(child: _screen()),
                  ],
                ),
        );
      },
    );
  }
}

class _NavPanel extends StatelessWidget {
  const _NavPanel({
    required this.data,
    required this.selected,
    required this.onSelect,
  });

  final GoldData data;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 30, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          BrandMark(size: 34),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gold Explorer',
                              style: TextStyle(
                                fontFamily: kSerif,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('Egyptian Antiquities Provenance Lakehouse', style: AppText.small),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: AppColors.line,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    children: <Widget>[
                      for (final group in _navGroups) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              fontFamily: kSans,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        for (final i in group.items)
                          _NavTile(
                            item: _navItems[i],
                            selected: i == selected,
                            onTap: () => onSelect(i),
                          ),
                      ],
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: AppColors.line,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Gold layer of ${data.databaseName}', style: AppText.small),
                      Text('Exported ${fmtStamp(data.exportedAt)}', style: AppText.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const StrataStrip(),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? AppColors.lapis.withAlpha(22) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? AppColors.gold : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Center(
                    child: ArtMark(
                      item.art,
                      width: 20,
                      color: selected ? AppColors.lapis : AppColors.muted,
                      soft: selected ? const Color(0xFF9DB5D6) : const Color(0xFFC9CED6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? AppColors.ink : const Color(0xFF364152),
                    ),
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
