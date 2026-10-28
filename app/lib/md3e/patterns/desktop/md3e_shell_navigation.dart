import 'package:flutter/widgets.dart';

/// Primary shell destination indices (aligned with [md3eDefaultNavigationRailDestinations]).
abstract final class Md3eShellNavigation {
  static const int homeDestinationIndex = 0;
  static const int libraryDestinationIndex = 1;
  static const int managementDestinationIndex = 2;
  static const int historyDestinationIndex = 3;
  static const int settingsDestinationIndex = 4;

  static const double librarySecondaryPanelWidth = 280;
}

/// Navigation inputs passed to [Md3eDesktopShellPaneBuilder].
class Md3eShellNavigationSnapshot {
  const Md3eShellNavigationSnapshot({
    required this.destinationIndex,
    required this.selectedLibraryDisplayName,
  });

  final int destinationIndex;
  final String selectedLibraryDisplayName;
}

/// Builds the main pane for [Md3eDesktopShell].
typedef Md3eDesktopShellPaneBuilder =
    Widget Function(
      BuildContext context,
      Md3eShellNavigationSnapshot navigation,
    );
