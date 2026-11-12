import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:hentai_library/design-system/util/navigation_rail_icon.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// MD3E shell bottom navigation ([M3ENavigationBar]) for medium- viewports.
class ExpressiveNavigationBar extends StatelessWidget {
  const ExpressiveNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
  });

  final List<ExpressiveNavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final int resolvedIndex = destinations.isEmpty
        ? 0
        : selectedIndex.clamp(0, destinations.length - 1);

    return M3ENavigationBar(
      destinations: <M3ENavigationBarDestination>[
        for (final ExpressiveNavigationRailDestination destination
            in destinations)
          M3ENavigationBarDestination(
            icon: navigationRailIconWidget(
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              selected: false,
            ),
            selectedIcon: navigationRailIconWidget(
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              selected: true,
            ),
            label: destination.label,
          ),
      ],
      selectedIndex: resolvedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: backgroundColor,
      size: M3ENavBarSize.small,
      labelBehavior: M3ENavBarLabelBehavior.alwaysShow,
    );
  }
}
