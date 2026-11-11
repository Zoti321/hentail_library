import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_browse/public/l10n/library_browse_l10n.dart';

/// Body-top catalog row: 漫画 / 系列 胶囊切换（与管理页同款 [SegmentedCapsuleBar]）+ 当前数量（末端）。
///
/// Scrolls with the grid/list; the pinned header is title + actions only.
class LibraryCatalogToolbar extends StatelessWidget {
  const LibraryCatalogToolbar({
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
          child: SegmentedCapsuleBar(
            segments: <SegmentedCapsuleSegment>[
              SegmentedCapsuleSegment(
                label: l10n.libraryDisplayTargetTabLabel(
                  LibraryDisplayTarget.comics,
                ),
              ),
              SegmentedCapsuleSegment(
                label: l10n.libraryDisplayTargetTabLabel(
                  LibraryDisplayTarget.series,
                ),
              ),
            ],
            selectedIndex: displayTarget == LibraryDisplayTarget.comics ? 0 : 1,
            onSelected: (int index) {
              onDisplayTargetChanged(
                index == 0
                    ? LibraryDisplayTarget.comics
                    : LibraryDisplayTarget.series,
              );
            },
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
