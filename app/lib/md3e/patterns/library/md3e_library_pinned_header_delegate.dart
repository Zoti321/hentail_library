import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_pinned_toolbar_chrome_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Sticky library header with M3 elevation when content scrolls underneath.
class Md3eLibraryPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  Md3eLibraryPinnedHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool elevated = shrinkOffset > 0 || overlapsContent;
    final double elevation = elevated
        ? Md3ePinnedToolbarChromeMetrics.pinnedHeaderElevation
        : M3EElevation.level0;

    return Material(
      color: scheme.surface,
      elevation: elevation,
      shadowColor: scheme.shadow,
      surfaceTintColor: const Color(0x00000000),
      child: Align(alignment: Alignment.topCenter, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant Md3eLibraryPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
