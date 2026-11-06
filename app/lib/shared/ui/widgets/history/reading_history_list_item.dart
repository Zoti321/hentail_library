import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_typography.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Overflow menu entry on the history list row.
class ReadingHistoryMoreMenuEntry {
  const ReadingHistoryMoreMenuEntry({required this.label, this.onSelected});

  final String label;
  final VoidCallback? onSelected;
}

/// 上次阅读日期：`{YYYY}年{MM}月{DD}日`（如 2026年06月15日）。
final DateFormat ReadingHistoryLastReadDateFormat = DateFormat('yyyy年MM月dd日');

String readingHistoryLastReadDateLabel(DateTime lastReadTime) {
  return ReadingHistoryLastReadDateFormat.format(lastReadTime);
}

/// 阅读历史列表行：封面 + 标题 + 进度条与页码 + 上次阅读日期 + 继续阅读 / 更多。
///
/// 行级 hover / press 由 [M3ECard] 提供；state layer 动效使用 M3E 标准 token，减少动效时为 0。
/// 尺寸见 [ReadingHistoryListItemMetrics]。
class ReadingHistoryListItem extends StatelessWidget {
  const ReadingHistoryListItem({
    super.key,
    required this.title,
    required this.cover,
    required this.currentPage,
    required this.totalPages,
    required this.lastReadTime,
    this.onTap,
    this.onContinueReading,
    this.moreMenuEntries = const <ReadingHistoryMoreMenuEntry>[],
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
  final List<ReadingHistoryMoreMenuEntry> moreMenuEntries;
  final bool enabled;

  /// When null, resolved from [MediaQuery] width.
  final WindowSizeClass? sizeClass;

  static double itemExtent(BuildContext context) {
    final WindowSizeClass window = sizeClassOf(context);
    return ReadingHistoryListItemMetrics.specFor(window).rowHeight;
  }

  static WindowSizeClass sizeClassOf(BuildContext context) {
    return windowSizeClassOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass window = sizeClass ?? windowSizeClassOf(context);
    final ReadingHistoryListItemSpec spec =
        ReadingHistoryListItemMetrics.specFor(window);

    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;

    final String progressLabel = l10n.readingProgressPageOfTotal(
      currentPage,
      totalPages,
    );
    final String dateLabel = readingHistoryLastReadDateLabel(lastReadTime);
    final double progress = currentPage / totalPages;

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
              style: readingHistoryListItemTitleStyle(type, scheme),
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: M3EProgressIndicator.linear(
                    value: progress,
                    color: scheme.primary,
                    trackColor: scheme.surfaceContainerHighest,
                    semanticsLabel: progressLabel,
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  progressLabel,
                  maxLines: 1,
                  style: readingHistoryListItemProgressStyle(type, scheme),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Text(
              dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: readingHistoryListItemTimeStyle(type, scheme),
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
      moreButton = AnchoredMenu(
        enabled: enabled,
        position: M3EMenuAnchorPosition.bottomEnd,
        children: <M3EMenuEntry>[
          for (final ReadingHistoryMoreMenuEntry entry in moreMenuEntries)
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
          SizedBox(width: spec.actionGap),
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
        children: <Widget>[coverLeading, info, actions],
      ),
    );

    final BorderRadius radius = BorderRadius.circular(spec.containerRadius);
    final Duration stateDuration = LabMotion.motionDurationOf(
      context,
      M3EMotion.short3,
    );

    return SizedBox(
      height: spec.rowHeight,
      width: double.infinity,
      child: M3ECard(
        variant: M3ECardVariant.filled,
        color: scheme.surfaceContainer,
        elevation: 0,
        padding: EdgeInsets.zero,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        enabled: enabled,
        trackHover: true,
        animationDuration: stateDuration,
        animationCurve: M3EMotion.standard,
        onPressed: enabled && onTap != null ? onTap : null,
        semanticLabel: title,
        child: row,
      ),
    );
  }
}
