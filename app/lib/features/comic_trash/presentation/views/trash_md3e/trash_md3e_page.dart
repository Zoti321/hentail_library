import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_title.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_controller.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_state.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_md3e/trash_md3e_actions.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_md3e/widgets/trash_md3e_list_item.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/pinned_toolbar_chrome.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const double _kTrashLoadMoreThreshold = 400;

/// 「已删除」页（MD3E 生产版）：跨全部 Library 的 Comic trash，可恢复或永久删除。
class TrashMd3ePage extends ConsumerWidget {
  const TrashMd3ePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(scheme),
      child: NotificationListener<ScrollUpdateNotification>(
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
              delegate: Md3ePageHeaderDelegate(
                layout: layout,
                child: _TrashHeader(
                  onOpenNavigation: appShellPageNavigationOpener(context),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                layout.headerToBodyGap,
                horizontal,
                layout.bodyBottomInset,
              ),
              sliver: const SliverToBoxAdapter(child: _TrashBody()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashHeader extends ConsumerWidget {
  const _TrashHeader({this.onOpenNavigation});

  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final TrashPageState? state = ref
        .watch(trashPageControllerProvider)
        .asData
        ?.value;
    final bool hasItems = state != null && !state.isEmpty;
    final int selectedCount = state?.selectedIds.length ?? 0;
    final bool hasSelection = selectedCount > 0;

    return Md3ePinnedToolbarChrome(
      child: Row(
        children: <Widget>[
          if (onOpenNavigation != null) ...<Widget>[
            M3EIconButton(
              icon: const Icon(Symbols.menu),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.shellOpenNavMenu,
              semanticLabel: l10n.shellOpenNavMenu,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: Md3ePageTitle(l10n.navTrash)),
          if (hasSelection)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                l10n.trashSelectedCount(selectedCount),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          M3EIconButton(
            icon: Icon(
              Symbols.restore,
              size: Md3eLibraryPageHeaderMetrics.actionIconSize,
              color: scheme.onSurfaceVariant,
            ),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.sm,
            tooltip: hasSelection
                ? l10n.trashRestoreSelected
                : l10n.trashRestoreAll,
            semanticLabel: hasSelection
                ? l10n.trashRestoreSelected
                : l10n.trashRestoreAll,
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
          const SizedBox(width: 4),
          M3EIconButton(
            icon: Icon(
              Symbols.delete_forever,
              size: Md3eLibraryPageHeaderMetrics.actionIconSize,
              color: hasItems ? scheme.error : scheme.onSurfaceVariant,
            ),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.sm,
            tooltip: hasSelection
                ? l10n.trashPurgeSelected
                : l10n.trashPurgeAll,
            semanticLabel: hasSelection
                ? l10n.trashPurgeSelected
                : l10n.trashPurgeAll,
            onPressed: hasItems
                ? hasSelection
                      ? () => purgeTrashedComics(
                          context,
                          ref,
                          state.selectedItems,
                        )
                      : () => purgeAllTrashedComics(
                          context,
                          ref,
                          state.allPurgeCounts,
                        )
                : null,
          ),
        ],
      ),
    );
  }
}

class _TrashBody extends ConsumerWidget {
  const _TrashBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
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
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ),
      data: (TrashPageState state) {
        if (state.isEmpty) {
          return _TrashEmptyState(scheme: scheme);
        }
        final TrashPageController controller = ref.read(
          trashPageControllerProvider.notifier,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.trashPageSummary(state.totalCount),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final TrashedComic item in state.items)
              TrashMd3eListItem(
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
  const _TrashEmptyState({required this.scheme});

  final M3EColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            Icon(Symbols.delete, size: 48, color: scheme.outline),
            Text(
              l10n.trashEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.onSurface),
            ),
            Text(
              l10n.trashEmptyDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
