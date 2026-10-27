import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item_metrics.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item_typography.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Overflow menu entry on the history list row.
class Md3eReadingHistoryMoreMenuEntry {
  const Md3eReadingHistoryMoreMenuEntry({
    required this.label,
    this.onSelected,
  });

  final String label;
  final VoidCallback? onSelected;
}

/// 阅读历史列表行：封面 + 标题 + 页码进度 + 上次阅读时间 + 继续阅读 / 更多。
///
/// 行级 hover / press 由 [M3ECard] elevated 提供；尺寸见 [Md3eReadingHistoryListItemMetrics]。
class Md3eReadingHistoryListItem extends StatelessWidget {
  const Md3eReadingHistoryListItem({
    super.key,
    required this.title,
    required this.cover,
    required this.currentPage,
    required this.totalPages,
    required this.lastReadTime,
    this.onTap,
    this.onContinueReading,
    this.moreMenuEntries = const <Md3eReadingHistoryMoreMenuEntry>[],
    this.enabled = true,
    this.sizeClass,
  }) : assert(currentPage >= 0),
       assert(totalPages > 0),
       assert(currentPage <= totalPages);

  final String title;
  final Widget cover;
  final int currentPage;
  final int totalPages;
  final DateTime lastReadTime;
  final VoidCallback? onTap;
  final VoidCallback? onContinueReading;
  final List<Md3eReadingHistoryMoreMenuEntry> moreMenuEntries;
  final bool enabled;

  /// When null, resolved from [MediaQuery] width.
  final Md3eWindowSizeClass? sizeClass;

  static double itemExtent(BuildContext context) {
    final Md3eWindowSizeClass window = sizeClassOf(context);
    return Md3eReadingHistoryListItemMetrics.specFor(window).rowHeight;
  }

  static Md3eWindowSizeClass sizeClassOf(BuildContext context) {
    return md3eWindowSizeClassOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass window =
        sizeClass ?? md3eWindowSizeClassOf(context);
    final Md3eReadingHistoryListItemSpec spec =
        Md3eReadingHistoryListItemMetrics.specFor(window);

    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;

    final String progressLabel = l10n.readingProgressPageOfTotal(
      currentPage,
      totalPages,
    );
    final String timeLabel = l10n.relativeTimeAgo(lastReadTime);

    final Widget coverLeading = ClipRRect(
      borderRadius: BorderRadius.circular(spec.coverRadius),
      child: SizedBox(
        width: spec.coverWidth,
        height: spec.coverHeight,
        child: cover,
      ),
    );

    final Widget info = Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spec.infoHorizontalGap),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: md3eReadingHistoryListItemTitleStyle(type, scheme),
            ),
            SizedBox(height: spacing.xs),
            Text(
              progressLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: md3eReadingHistoryListItemProgressStyle(type, scheme),
            ),
            SizedBox(height: spacing.xs),
            Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: md3eReadingHistoryListItemTimeStyle(type, scheme),
            ),
          ],
        ),
      ),
    );

    final M3EIconButtonSize actionSize = spec.actionButtonSize;

    final Widget? continueButton = onContinueReading == null
        ? null
        : M3EIconButton(
            icon: const Icon(Icons.menu_book_rounded),
            variant: M3EIconButtonVariant.tonal,
            size: actionSize,
            tooltip: l10n.homeContinueReading,
            semanticLabel: l10n.homeContinueReading,
            onPressed: enabled ? onContinueReading : null,
          );

    Widget? moreButton;
    if (moreMenuEntries.isNotEmpty) {
      moreButton = Md3eAnchoredMenu(
        enabled: enabled,
        position: M3EMenuAnchorPosition.bottomEnd,
        children: <M3EMenuEntry>[
          for (final Md3eReadingHistoryMoreMenuEntry entry in moreMenuEntries)
            M3EMenuEntry(
              label: entry.label,
              enabled: enabled && entry.onSelected != null,
              onPressed: entry.onSelected,
            ),
        ],
        anchorBuilder: (BuildContext context, VoidCallback open) {
          return M3EIconButton(
            icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
            variant: M3EIconButtonVariant.standard,
            size: actionSize,
            tooltip: l10n.metadataMoreActions,
            onPressed: enabled ? open : null,
          );
        },
      );
    }

    final Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ?continueButton,
        if (continueButton != null && moreButton != null)
          const SizedBox(width: 4),
        ?moreButton,
      ],
    );

    final Widget row = Padding(
      padding: EdgeInsets.fromLTRB(
        spec.horizontalPadding,
        spec.verticalPadding,
        spec.horizontalPadding - 4,
        spec.verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          coverLeading,
          info,
          actions,
        ],
      ),
    );

    final BorderRadius radius = BorderRadius.circular(spec.containerRadius);

    return SizedBox(
      height: spec.rowHeight,
      width: double.infinity,
      child: M3ECard(
        variant: M3ECardVariant.filled,
        color: scheme.surfaceContainerLow,
        elevation: 0,
        padding: EdgeInsets.zero,
        borderRadius: radius,
        border: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
        clipBehavior: Clip.antiAlias,
        enabled: enabled,
        trackHover: true,
        onPressed: enabled && onTap != null ? onTap : null,
        semanticLabel: title,
        child: row,
      ),
    );
  }
}
