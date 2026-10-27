import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_display_target_tabs.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Body-top catalog row: display-target tabs (start) + active count (end).
///
/// Scrolls with the grid/list; the pinned header is title + actions only.
class Md3eLibraryCatalogToolbar extends StatelessWidget {
  const Md3eLibraryCatalogToolbar({
    super.key,
    required this.displayTarget,
    required this.comicCount,
    required this.seriesCount,
    required this.onDisplayTargetChanged,
  });

  final LibraryDisplayTarget displayTarget;
  final int comicCount;
  final int seriesCount;
  final ValueChanged<LibraryDisplayTarget> onDisplayTargetChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    final String countLabel = displayTarget == LibraryDisplayTarget.comics
        ? l10n.comicCount(comicCount)
        : l10n.librarySeriesCount(seriesCount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Md3eLibraryDisplayTargetTabs(
            displayTarget: displayTarget,
            sizeClass: sizeClass,
            centered: false,
            onChanged: onDisplayTargetChanged,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          countLabel,
          style: type.labelLarge.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
