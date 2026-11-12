import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/util/navigation_rail_icon.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/shell/shell_navigation.dart'
    show defaultNavigationRailDestinations;

/// Layout metrics from Figma `ExpressiveNavigationRail` `41:1577` (MASTER §5.6).
abstract final class ExpressiveNavigationRailMetrics {
  static const double collapsedWidth = 80;
  static const double expandedWidth = 256;
}

/// One primary shell destination (home / library / manage / history / settings).
class ExpressiveNavigationRailDestination {
  const ExpressiveNavigationRailDestination({
    required this.label,
    required this.icon,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// MD3E shell navigation rail ([M3ENavigationRail] + lab theme overrides).
class ExpressiveNavigationRail extends StatelessWidget {
  const ExpressiveNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    this.onMenuPressed,
    this.modality = M3ENavigationRailModality.standard,
    this.hideWhenCollapsed = false,
    this.onDismissModal,
    this.controller,
  });

  final List<ExpressiveNavigationRailDestination> destinations;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onMenuPressed;
  final M3ENavigationRailModality modality;
  final bool hideWhenCollapsed;
  final VoidCallback? onDismissModal;
  final M3ENavigationRailController? controller;

  @override
  Widget build(BuildContext context) {
    return M3ENavigationRail(
      type: extended
          ? M3ENavigationRailType.expanded
          : M3ENavigationRailType.collapsed,
      modality: modality,
      hideWhenCollapsed: hideWhenCollapsed,
      onDismissModal: onDismissModal,
      controller: controller,
      expandedWidth: ExpressiveNavigationRailMetrics.expandedWidth,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      expandTooltip: context.l10n.navRailExpand,
      collapseTooltip: context.l10n.navRailCollapse,
      onTypeChanged: (_) => onMenuPressed?.call(),
      sections: <M3ENavigationRailSection>[
        M3ENavigationRailSection(
          destinations: <M3ENavigationRailDestination>[
            for (final ExpressiveNavigationRailDestination destination
                in destinations)
              M3ENavigationRailDestination(
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
        ),
      ],
    );
  }
}
