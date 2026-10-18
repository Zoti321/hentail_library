import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/comic_trash/comic_purge_policy.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/widgets/comic_confirm_purge_dialog.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_controller.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_state.dart';
import 'package:hentai_library/shared/ui/layout/page_header_layout.dart';
import 'package:hentai_library/shared/ui/layout/page_pinned_header_delegate.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_page/widgets/trash_comic_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kTrashLoadMoreThreshold = 400;

/// 「已删除」页：跨全部 Library 的 Comic trash 列表，可恢复或永久删除。
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  static const double _headerExtent = kPageHeaderVerticalPadding * 2 + 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final PageHeaderLayoutTier layoutTier = pageHeaderLayoutTierForWidth(
          constraints.maxWidth,
        );
        final double horizontalPadding = pageHeaderHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = pageHeaderInnerMaxWidth(
          layoutTier,
          constraints.maxWidth,
        );
        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (ScrollUpdateNotification notification) {
            final ScrollMetrics metrics = notification.metrics;
            if (metrics.maxScrollExtent > 0 &&
                metrics.pixels >=
                    metrics.maxScrollExtent - _kTrashLoadMoreThreshold) {
              ref.read(trashPageControllerProvider.notifier).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: PagePinnedHeaderDelegate(
                  extent: TrashPage._headerExtent,
                  child: PageContentWidthAlign(
                    horizontalPadding: horizontalPadding,
                    maxWidth: innerMaxWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kPageHeaderVerticalPadding,
                      ),
                      child: _TrashHeader(
                        layoutTier: layoutTier,
                        onOpenNavigation: appShellPageNavigationOpener(context),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: PageContentWidthAlign(
                  horizontalPadding: horizontalPadding,
                  maxWidth: innerMaxWidth,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: tokens.layout.contentVerticalPadding,
                      bottom: tokens.layout.contentAreaPadding.bottom,
                    ),
                    child: const _TrashBody(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrashHeader extends ConsumerWidget {
  const _TrashHeader({required this.layoutTier, this.onOpenNavigation});

  final PageHeaderLayoutTier layoutTier;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final TrashPageState? state = ref
        .watch(trashPageControllerProvider)
        .asData
        ?.value;
    final bool hasItems = state != null && !state.isEmpty;
    final int selectedCount = state?.selectedIds.length ?? 0;
    final bool hasSelection = selectedCount > 0;
    final List<Widget> actions = <Widget>[
      if (hasSelection)
        Text(
          l10n.trashSelectedCount(selectedCount),
          style: TextStyle(fontSize: 13, color: cs.hentai.textSecondary),
        ),
      if (hasSelection) SizedBox(width: tokens.spacing.sm),
      _TrashHeaderAction(
        layoutTier: layoutTier,
        icon: LucideIcons.undo2,
        text: hasSelection ? l10n.trashRestoreSelected : l10n.trashRestoreAll,
        onPressed: hasItems
            ? hasSelection
                  ? () => restoreTrashedComics(
                      context,
                      ref,
                      state.selectedItems
                          .map((TrashedComic item) => item.comic.comicId)
                          .toList(),
                    )
                  : () => restoreAllTrashedComics(context, ref)
            : null,
      ),
      _TrashHeaderAction(
        layoutTier: layoutTier,
        icon: LucideIcons.trash2,
        text: hasSelection ? l10n.trashPurgeSelected : l10n.trashPurgeAll,
        foregroundColor: cs.hentai.contextMenuDanger,
        hoverColor: cs.hentai.contextMenuDanger.withAlpha(24),
        overlayColor: cs.hentai.contextMenuDanger.withAlpha(20),
        onPressed: hasItems
            ? hasSelection
                  ? () => purgeTrashedComics(context, ref, state.selectedItems)
                  : () => purgeAllTrashedComics(
                      context,
                      ref,
                      state.allPurgeCounts,
                    )
            : null,
      ),
    ];

    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (onOpenNavigation != null) ...<Widget>[
                    GhostButton.icon(
                      icon: LucideIcons.menu,
                      semanticLabel: l10n.shellOpenNavMenu,
                      tooltip: '',
                      foregroundColor: cs.hentai.iconDefault,
                      hoverColor: theme.hoverColor,
                      overlayColor: theme.hoverColor,
                      onPressed: onOpenNavigation,
                    ),
                    SizedBox(width: tokens.spacing.sm),
                  ],
                  Text(
                    l10n.navTrash,
                    style: pageHeaderTitleStyle(cs, layoutTier),
                  ),
                ],
              ),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}

class _TrashHeaderAction extends StatelessWidget {
  const _TrashHeaderAction({
    required this.layoutTier,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.foregroundColor,
    this.hoverColor,
    this.overlayColor,
  });

  final PageHeaderLayoutTier layoutTier;
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? hoverColor;
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) {
    if (layoutTier == PageHeaderLayoutTier.compact) {
      return GhostButton.icon(
        icon: icon,
        tooltip: text,
        semanticLabel: text,
        foregroundColor: foregroundColor,
        hoverColor: hoverColor,
        overlayColor: overlayColor,
        onPressed: onPressed,
      );
    }
    return GhostButton.iconText(
      icon: icon,
      text: text,
      foregroundColor: foregroundColor,
      hoverColor: hoverColor,
      overlayColor: overlayColor,
      onPressed: onPressed,
    );
  }
}

class _TrashBody extends ConsumerWidget {
  const _TrashBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final AsyncValue<TrashPageState> async = ref.watch(
      trashPageControllerProvider,
    );
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object _, StackTrace _) => Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            l10n.shellLoadFailed,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.hentai.textSecondary,
            ),
          ),
        ),
      ),
      data: (TrashPageState state) {
        if (state.isEmpty) {
          return const _TrashEmptyState();
        }
        final TrashPageController controller = ref.read(
          trashPageControllerProvider.notifier,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.trashPageSummary(state.totalCount),
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: theme.colorScheme.hentai.textTertiary,
              ),
            ),
            const SizedBox(height: kPageHeaderSearchToListSpacing),
            for (final TrashedComic item in state.items)
              TrashComicTile(
                key: ValueKey<String>(item.comic.comicId),
                item: item,
                selected: state.selectedIds.contains(item.comic.comicId),
                onToggleSelected: () =>
                    controller.toggleSelected(item.comic.comicId),
              ),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        );
      },
    );
  }
}

class _TrashEmptyState extends StatelessWidget {
  const _TrashEmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            Icon(LucideIcons.trash2, size: 48, color: cs.hentai.textTertiary),
            Text(
              l10n.trashEmptyTitle,
              style: TextStyle(fontSize: 15, color: cs.hentai.textPrimary),
            ),
            Text(
              l10n.trashEmptyDescription,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.hentai.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> restoreTrashedComics(
  BuildContext context,
  WidgetRef ref,
  List<String> comicIds,
) async {
  final AppLocalizations l10n = context.l10n;
  try {
    final int restored = await ref
        .read(trashPageControllerProvider.notifier)
        .restore(comicIds);
    if (context.mounted) {
      showSuccessToast(context, l10n.trashRestoredToast(restored));
    }
  } catch (err) {
    if (context.mounted) {
      showErrorToast(context, err);
    }
  }
}

Future<void> restoreAllTrashedComics(
  BuildContext context,
  WidgetRef ref,
) async {
  final AppLocalizations l10n = context.l10n;
  try {
    final int restored = await ref
        .read(trashPageControllerProvider.notifier)
        .restoreAll();
    if (context.mounted && restored > 0) {
      showSuccessToast(context, l10n.trashRestoredToast(restored));
    }
  } catch (err) {
    if (context.mounted) {
      showErrorToast(context, err);
    }
  }
}

Future<void> purgeTrashedComics(
  BuildContext context,
  WidgetRef ref,
  List<TrashedComic> items,
) async {
  if (items.isEmpty) {
    return;
  }
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => items.length == 1
        ? ComicConfirmPurgeDialog(
            title: items.single.comic.title,
            isLocal: !items.single.isRemote,
          )
        : ComicConfirmPurgeDialog.batch(counts: countPurgeTargets(items)),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await _runPurge(
    context,
    () => ref
        .read(trashPageControllerProvider.notifier)
        .purge(items.map((TrashedComic item) => item.comic.comicId).toList()),
  );
}

Future<void> purgeAllTrashedComics(
  BuildContext context,
  WidgetRef ref,
  PurgeTargetCounts counts,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) =>
        ComicConfirmPurgeDialog.batch(counts: counts),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await _runPurge(
    context,
    () => ref.read(trashPageControllerProvider.notifier).purgeAll(),
  );
}

Future<void> _runPurge(
  BuildContext context,
  Future<ComicPurgeResult> Function() purge,
) async {
  final AppLocalizations l10n = context.l10n;
  try {
    final ComicPurgeResult result = await purge();
    if (!context.mounted) {
      return;
    }
    switch (purgeSummaryKindFor(result)) {
      case PurgeSummaryKind.nothing:
        break;
      case PurgeSummaryKind.allSucceeded:
        showSuccessToast(
          context,
          l10n.trashPurgeSucceededToast(result.succeeded),
        );
      case PurgeSummaryKind.partial:
        showInfoToast(
          context,
          l10n.trashPurgePartialToast(result.succeeded, result.failed),
        );
      case PurgeSummaryKind.allFailed:
        showErrorToast(context, l10n.trashPurgeFailedToast(result.failed));
    }
  } catch (err) {
    if (context.mounted) {
      showErrorToast(context, err);
    }
  }
}
