import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Layout metrics from Figma `NavigationRail` `41:1577` (MASTER §5.6).
abstract final class Md3eNavigationRailMetrics {
  static const double collapsedWidth = 80;
  static const double expandedWidth = 256;
}

/// One primary shell destination (home / library / history / settings).
class Md3eNavigationRailDestination {
  const Md3eNavigationRailDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// MD3E shell navigation rail ([M3ENavigationRail] + lab theme overrides).
class Md3eNavigationRail extends StatelessWidget {
  const Md3eNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    this.onMenuPressed,
  });

  final List<Md3eNavigationRailDestination> destinations;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return M3ENavigationRail(
      type: extended
          ? M3ENavigationRailType.expanded
          : M3ENavigationRailType.collapsed,
      expandedWidth: Md3eNavigationRailMetrics.expandedWidth,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      expandTooltip: '展开导航',
      collapseTooltip: '收起导航',
      onTypeChanged: (_) => onMenuPressed?.call(),
      sections: <M3ENavigationRailSection>[
        M3ENavigationRailSection(
          destinations: <M3ENavigationRailDestination>[
            for (final Md3eNavigationRailDestination destination
                in destinations)
              M3ENavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      ],
    );
  }
}

/// Default four destinations matching Figma `41:1577` labels and icons.
List<Md3eNavigationRailDestination> md3eDefaultNavigationRailDestinations() {
  return const <Md3eNavigationRailDestination>[
    Md3eNavigationRailDestination(
      label: '首页',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    Md3eNavigationRailDestination(
      label: '书库',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
    ),
    Md3eNavigationRailDestination(
      label: '历史',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    Md3eNavigationRailDestination(
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];
}
