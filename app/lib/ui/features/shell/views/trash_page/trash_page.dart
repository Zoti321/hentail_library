import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/comic_purge_policy.dart';
import 'package:hentai_library/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_purge_dialog.dart';
import 'package:hentai_library/ui/features/shell/view_models/trash_page_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/trash_page_state.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/history_layout_constants.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/widgets/history_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/features/shell/views/trash_page/widgets/trash_comic_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kTrashLoadMoreThreshold = 400;

/// 「已删除」页：跨全部 Library 的 Comic trash 列表，可恢复或永久删除。
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final HistoryLayoutTier layoutTier = historyLayoutTierForWidth(
          constraints.maxWidth,
        );
        final double horizontalPadding = historyContentHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = historyInnerContentMaxWidth(
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
              SliverToBoxAdapter(
                child: PageContentWidthAlign(
                  horizontalPadding: horizontalPadding,
                  maxWidth: innerMaxWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: kHistoryHeaderVerticalPadding,
                    ),
                    child: _TrashHeader(
                      layoutTier: layoutTier,
                      onOpenNavigation: appShellPageNavigationOpener(context),
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

  final HistoryLayoutTier layoutTier;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final l10n = context.l10n;
    final TrashPageState? state = ref
        .watch(trashPageControllerProvider)
        .asData
        ?.value;
    final bool selectionMode = state?.selectionMode ?? false;
    final bool hasItems = state != null && !state.isEmpty;
    final int selectedCount = state?.selectedIds.length ?? 0;
    final TrashPageController controller = ref.read(
      trashPageControllerProvider.notifier,
    );

    final List<Widget> actions = selectionMode
        ? <Widget>[
            Text(
              l10n.trashSelectedCount(selectedCount),
              style: TextStyle(fontSize: 13, color: cs.hentai.textSecondary),
            ),
            const SizedBox(width: 8),
            GhostButton.text(
              text: l10n.trashSelectAll,
              onPressed: hasItems ? controller.toggleSelectAllLoaded : null,
            ),
            GhostButton.iconText(
              icon: LucideIcons.undo2,
              text: l10n.trashRestore,
              onPressed: selectedCount > 0
                  ? () => restoreTrashedComics(
                      context,
                      ref,
                      state!.selectedItems
                          .map((TrashedComic item) => item.comic.comicId)
                          .toList(),
                    )
                  : null,
            ),
            GhostButton.iconText(
              icon: LucideIcons.trash2,
              text: l10n.trashPurge,
              foregroundColor: cs.hentai.contextMenuDanger,
              hoverColor: cs.hentai.contextMenuDanger.withAlpha(24),
              overlayColor: cs.hentai.contextMenuDanger.withAlpha(20),
              onPressed: selectedCount > 0
                  ? () => purgeTrashedComics(context, ref, state!.selectedItems)
                  : null,
            ),
            GhostButton.text(
              text: l10n.trashExitSelection,
              onPressed: controller.exitSelection,
            ),
          ]
        : <Widget>[
            GhostButton.iconText(
              icon: LucideIcons.squareCheck,
              text: l10n.trashSelect,
              onPressed: hasItems ? controller.enterSelection : null,
            ),
            GhostButton.iconText(
              icon: LucideIcons.trash2,
              text: l10n.trashPurgeAll,
              foregroundColor: cs.hentai.contextMenuDanger,
              hoverColor: cs.hentai.contextMenuDanger.withAlpha(24),
              overlayColor: cs.hentai.contextMenuDanger.withAlpha(20),
              onPressed: hasItems
                  ? () => purgeAllTrashedComics(
                      context,
                      ref,
                      state.allPurgeCounts,
                    )
                  : null,
            ),
          ];

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: <Widget>[
        Row(
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
              const SizedBox(width: 8),
            ],
            Text(l10n.navTrash, style: historyPageTitleStyle(cs, layoutTier)),
          ],
        ),
        Row(mainAxisSize: MainAxisSize.min, children: actions),
      ],
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
            const SizedBox(height: kHistorySearchToListSpacing),
            for (final TrashedComic item in state.items)
              TrashComicTile(
                key: ValueKey<String>(item.comic.comicId),
                item: item,
                selectionMode: state.selectionMode,
                selected: state.selectedIds.contains(item.comic.comicId),
                onToggleSelected: () =>
                    controller.toggleSelected(item.comic.comicId),
                onRestore: () => restoreTrashedComics(context, ref, <String>[
                  item.comic.comicId,
                ]),
                onPurge: () =>
                    purgeTrashedComics(context, ref, <TrashedComic>[item]),
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
