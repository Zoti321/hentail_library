import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Shell [Md3eNavigationRail] 主目的地图标（Material Symbols；选中态由 fill=1 呈现）。
abstract final class Md3eShellRailSymbols {
  static const IconData home = Symbols.home;
  static const IconData library = Symbols.auto_stories;
  static const IconData metadata = Symbols.layers;
  static const IconData settings = Symbols.settings;
}

/// Primary shell destination indices for the **Lab default** rail
/// ([md3eLabDefaultShellRailDestinations]).
abstract final class Md3eShellNavigation {
  static const int homeDestinationIndex = 0;
  static const int libraryDestinationIndex = 1;
  static const int managementDestinationIndex = 2;
  static const int settingsDestinationIndex = 3;

  /// [Md3eNavigationRail.selectedIndex]：无对应 Rail 目的地（如 `/history`）。
  static const int noDestinationIndex = -1;

  static const double librarySecondaryPanelWidth = 280;
}

/// One shell rail slot with stable [navId] for production routing.
class Md3eShellRailDestination {
  const Md3eShellRailDestination({
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

  Md3eNavigationRailDestination toNavigationDestination() {
    return Md3eNavigationRailDestination(
      label: label,
      icon: icon,
      selectedIcon: selectedIcon,
    );
  }
}

int md3eShellLibraryAnchorIndex(List<Md3eShellRailDestination> destinations) {
  return destinations.indexWhere(
    (Md3eShellRailDestination destination) => destination.isLibraryFlyoutAnchor,
  );
}

int md3eShellDestinationIndexForNavId(
  List<Md3eShellRailDestination> destinations,
  String navId,
) {
  if (navId.isEmpty) {
    return Md3eShellNavigation.noDestinationIndex;
  }
  final int index = destinations.indexWhere(
    (Md3eShellRailDestination destination) => destination.navId == navId,
  );
  return index >= 0 ? index : Md3eShellNavigation.noDestinationIndex;
}

String md3eShellNavIdForDestinationIndex(
  List<Md3eShellRailDestination> destinations,
  int index,
) {
  if (index < 0 || index >= destinations.length) {
    return destinations.first.navId;
  }
  return destinations[index].navId;
}

int md3eShellSettingsDestinationIndex(
  List<Md3eShellRailDestination> destinations,
) {
  final int index = destinations.indexWhere(
    (Md3eShellRailDestination destination) => destination.navId == 'settings',
  );
  return index >= 0 ? index : destinations.length - 1;
}

List<Md3eNavigationRailDestination> md3eNavigationDestinationsFromShell(
  List<Md3eShellRailDestination> destinations,
) {
  return destinations
      .map(
        (Md3eShellRailDestination destination) =>
            destination.toNavigationDestination(),
      )
      .toList(growable: false);
}

/// Navigation inputs passed to [Md3eDesktopShellPaneBuilder].
class Md3eShellNavigationSnapshot {
  const Md3eShellNavigationSnapshot({
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

/// Builds the main pane for [Md3eDesktopShell].
typedef Md3eDesktopShellPaneBuilder = Widget Function(
  BuildContext context,
  Md3eShellNavigationSnapshot navigation,
);

/// Lab / Widgetbook shell rail specs (no 回收站).
List<Md3eShellRailDestination> md3eLabDefaultShellRailDestinations(
  AppLocalizations l10n,
) {
  return <Md3eShellRailDestination>[
    Md3eShellRailDestination(
      navId: 'home',
      label: l10n.navHome,
      icon: Md3eShellRailSymbols.home,
    ),
    Md3eShellRailDestination(
      navId: 'library',
      label: l10n.libraryTitle,
      icon: Md3eShellRailSymbols.library,
      isLibraryFlyoutAnchor: true,
    ),
    Md3eShellRailDestination(
      navId: 'metadata',
      label: l10n.navMetadata,
      icon: Md3eShellRailSymbols.metadata,
    ),
    Md3eShellRailDestination(
      navId: 'settings',
      label: l10n.navSettings,
      icon: Md3eShellRailSymbols.settings,
    ),
  ];
}

/// Default shell destinations aligned with production nav labels ([AppNavigation]).
List<Md3eNavigationRailDestination> md3eDefaultNavigationRailDestinations(
  AppLocalizations l10n,
) {
  return md3eNavigationDestinationsFromShell(
    md3eLabDefaultShellRailDestinations(l10n),
  );
}
