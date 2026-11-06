import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Shell [ExpressiveNavigationRail] 主目的地图标（Material Symbols；选中态由 fill=1 呈现）。
abstract final class ShellRailSymbols {
  static const IconData home = Symbols.home;
  static const IconData library = Symbols.auto_stories;
  static const IconData metadata = Symbols.layers;
  static const IconData settings = Symbols.settings;
}

/// Primary shell destination indices for the **Lab default** rail
/// ([labDefaultShellRailDestinations]).
abstract final class ShellNavigation {
  static const int homeDestinationIndex = 0;
  static const int libraryDestinationIndex = 1;
  static const int managementDestinationIndex = 2;
  static const int settingsDestinationIndex = 3;

  /// [ExpressiveNavigationRail.selectedIndex]：无对应 Rail 目的地（如 `/history`）。
  static const int noDestinationIndex = -1;

  static const double librarySecondaryPanelWidth = 280;
}

/// One shell rail slot with stable [navId] for production routing.
class ShellRailDestination {
  const ShellRailDestination({
    required this.navId,
    required this.label,
    required this.icon,
    IconData? selectedIcon,
    this.isLibraryFlyoutAnchor = false,
  }) : selectedIcon = selectedIcon ?? icon;

  final String navId;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isLibraryFlyoutAnchor;

  ExpressiveNavigationRailDestination toNavigationDestination() {
    return ExpressiveNavigationRailDestination(
      label: label,
      icon: icon,
      selectedIcon: selectedIcon,
    );
  }
}

int shellLibraryAnchorIndex(List<ShellRailDestination> destinations) {
  return destinations.indexWhere(
    (ShellRailDestination destination) => destination.isLibraryFlyoutAnchor,
  );
}

int shellDestinationIndexForNavId(
  List<ShellRailDestination> destinations,
  String navId,
) {
  if (navId.isEmpty) {
    return ShellNavigation.noDestinationIndex;
  }
  final int index = destinations.indexWhere(
    (ShellRailDestination destination) => destination.navId == navId,
  );
  return index >= 0 ? index : ShellNavigation.noDestinationIndex;
}

String shellNavIdForDestinationIndex(
  List<ShellRailDestination> destinations,
  int index,
) {
  if (index < 0 || index >= destinations.length) {
    return destinations.first.navId;
  }
  return destinations[index].navId;
}

int shellSettingsDestinationIndex(List<ShellRailDestination> destinations) {
  final int index = destinations.indexWhere(
    (ShellRailDestination destination) => destination.navId == 'settings',
  );
  return index >= 0 ? index : destinations.length - 1;
}

List<ExpressiveNavigationRailDestination> navigationDestinationsFromShell(
  List<ShellRailDestination> destinations,
) {
  return destinations
      .map(
        (ShellRailDestination destination) =>
            destination.toNavigationDestination(),
      )
      .toList(growable: false);
}

/// Navigation inputs passed to [DesktopShellPaneBuilder].
class ShellNavigationSnapshot {
  const ShellNavigationSnapshot({
    required this.destinationIndex,
    required this.selectedLibraryId,
    required this.selectedLibraryDisplayName,
    this.onBackToPreviousDestination,
  });

  final int destinationIndex;
  final String selectedLibraryId;
  final String selectedLibraryDisplayName;

  /// compact 下从设置等目的地返回上一目的地；expanded+ 或无上一目的地时为 null。
  final VoidCallback? onBackToPreviousDestination;
}

/// Builds the main pane for [DesktopShell].
typedef DesktopShellPaneBuilder = Widget Function(
  BuildContext context,
  ShellNavigationSnapshot navigation,
);

/// Lab / Widgetbook shell rail specs (no 回收站).
List<ShellRailDestination> labDefaultShellRailDestinations(
  AppLocalizations l10n,
) {
  return <ShellRailDestination>[
    ShellRailDestination(
      navId: 'home',
      label: l10n.navHome,
      icon: ShellRailSymbols.home,
    ),
    ShellRailDestination(
      navId: 'library',
      label: l10n.libraryTitle,
      icon: ShellRailSymbols.library,
      isLibraryFlyoutAnchor: true,
    ),
    ShellRailDestination(
      navId: 'metadata',
      label: l10n.navMetadata,
      icon: ShellRailSymbols.metadata,
    ),
    ShellRailDestination(
      navId: 'settings',
      label: l10n.navSettings,
      icon: ShellRailSymbols.settings,
    ),
  ];
}

/// Default shell destinations aligned with production nav labels ([AppNavigation]).
List<ExpressiveNavigationRailDestination> defaultNavigationRailDestinations(
  AppLocalizations l10n,
) {
  return navigationDestinationsFromShell(labDefaultShellRailDestinations(l10n));
}
