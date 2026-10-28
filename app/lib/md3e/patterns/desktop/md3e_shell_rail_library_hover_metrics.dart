import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_navigation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Approximate vertical slot of the library destination on [M3ENavigationRail].
abstract final class Md3eShellRailLibraryHoverMetrics {
  static double destinationTop({
    required M3ENavigationRailTheme theme,
    required bool railExtended,
    required int destinationIndex,
  }) {
    const double menuBlockHeight = 56;
    final double itemStride = railExtended
        ? theme.itemExpandedHeight + theme.itemVerticalGap
        : theme.itemCollapsedHeight + theme.itemVerticalGap;

    return theme.topSpace +
        theme.destinationTopPadding +
        menuBlockHeight +
        destinationIndex * itemStride;
  }

  static double destinationHeight({
    required M3ENavigationRailTheme theme,
    required bool railExtended,
  }) {
    return railExtended ? theme.itemExpandedHeight : theme.itemCollapsedHeight;
  }

  static int get libraryDestinationIndex =>
      Md3eShellNavigation.libraryDestinationIndex;
}
