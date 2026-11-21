import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_controller.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_state.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash/trash_actions.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash/widgets/trash_list_item.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/navigation/pop_or_go_home.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const double _kTrashLoadMoreThreshold = 400;

/// 回收站页（MD3E 生产版）：跨全部 Library 的 Comic trash，可恢复或永久删除。
///
/// 页头与列表各自细粒度 select，避免勾选或 `isLoadingMore` 带动整页重建。
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  bool _handleScroll(ScrollUpdateNotification notification, WidgetRef ref) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent > 0 &&
        metrics.pixels >= metrics.maxScrollExtent - _kTrashLoadMoreThreshold) {
      unawaited(ref.read(trashPageControllerProvider.notifier).loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return ColoredBox(
      color: labBrowseCanvasColor(scheme),
      child: SafeArea(
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (ScrollUpdateNotification notification) =>
              _handleScroll(notification, ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: PageHeaderDelegate(
                  layout: layout,
                  child: _TrashHeader(
                    onOpenNavigation: appShellPageNavigationOpener(context),
                    onBack: () => popOrGoHome(context),
                  ),
                ),
              ),
              const _TrashBody(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 列表区：loading / error / empty / 列表字段各自 select。
class _TrashBody extends ConsumerWidget {
  const _TrashBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      horizontal,
      layout.headerToBodyGap,
      horizontal,
      layout.bodyBottomInset,
    );

    // 无条件订阅，避免 loading/error/data 分支切换时变更 watch 集合。
    final bool initialLoading = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.isLoading && !async.hasValue,
      ),
    );
    final Object? loadError = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.hasError ? async.error : null,
      ),
    );
    final List<TrashedComic> items = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.asData?.value.items ?? const <TrashedComic>[],
      ),
    );
    final int totalCount = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.asData?.value.totalCount ?? 0,
      ),
    );
    final Set<String> selectedIds = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.asData?.value.selectedIds ?? const <String>{},
      ),
    );
    final bool isLoadingMore = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.asData?.value.isLoadingMore ?? false,
      ),
    );

    if (initialLoading) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: layout.stateTopInset),
            child: const Center(child: M3EProgressIndicator.circular()),
          ),
        ),
      );
    }

    if (loadError != null) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: layout.stateTopInset),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Symbols.cloud_off, size: 48, color: scheme.outline),
                    SizedBox(height: theme.spacing.sm),
                    Text(
                      l10n.shellLoadFailed,
                      textAlign: TextAlign.center,
                      style: theme.typeScale.titleMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return SliverPadding(
        padding: padding,
        sliver: const SliverToBoxAdapter(child: _TrashEmptyState()),
      );
    }

    final TrashPageController controller = ref.read(
      trashPageControllerProvider.notifier,
    );

    return SliverPadding(
      padding: padding,
      sliver: SliverMainAxisGroup(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Text(
              l10n.trashPageSummary(totalCount),
              style: theme.typeScale.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: layout.listItemGap)),
          TrashListSliver(
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final TrashedComic item = items[index];
              final String comicId = item.comic.comicId;
              return TrashListItem(
                key: ValueKey<String>(comicId),
                item: item,
                selected: selectedIds.contains(comicId),
                onToggleSelected: () => controller.toggleSelected(comicId),
              );
            },
          ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: M3EProgressIndicator.circular()),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrashHeader extends ConsumerWidget {
  const _TrashHeader({this.onOpenNavigation, this.onBack});

  final VoidCallback? onOpenNavigation;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final bool hasItems = ref.watch(
      trashPageControllerProvider.select((AsyncValue<TrashPageState> async) {
        final TrashPageState? state = async.asData?.value;
        return state != null && !state.isEmpty;
      }),
    );
    final int selectedCount = ref.watch(
      trashPageControllerProvider.select(
        (AsyncValue<TrashPageState> async) =>
            async.asData?.value.selectedIds.length ?? 0,
      ),
    );
    final bool hasSelection = selectedCount > 0;

    TrashPageState? readState() =>
        ref.read(trashPageControllerProvider).asData?.value;

    return LibraryToolbarRow(
      title: PageTitle(l10n.navTrash),
      onBack: onBack,
      onOpenNavigation: onOpenNavigation,
      menuTooltip: l10n.shellOpenNavMenu,
      menuSemanticLabel: l10n.shellOpenNavMenu,
      trailing: <Widget>[
        if (hasSelection)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.sm + 2,
                  vertical: theme.spacing.xs,
                ),
                child: Text(
                  l10n.trashSelectedCount(selectedCount),
                  style: theme.typeScale.labelLarge.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        M3EIconButton(
          icon: Icon(
            Symbols.restore,
            size: LibraryPageHeaderMetrics.actionIconSize,
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
                    ? () {
                        final TrashPageState? state = readState();
                        if (state == null) {
                          return;
                        }
                        unawaited(
                          restoreTrashedComics(
                            context,
                            ref,
                            state.selectedItems
                                .map((TrashedComic item) => item.comic.comicId)
                                .toList(),
                          ),
                        );
                      }
                    : () => restoreAllTrashedComics(context, ref)
              : null,
        ),
        const SizedBox(width: 4),
        M3EIconButton(
          icon: Icon(
            Symbols.delete_forever,
            size: LibraryPageHeaderMetrics.actionIconSize,
            color: hasItems ? scheme.error : scheme.onSurfaceVariant,
          ),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: hasSelection ? l10n.trashPurgeSelected : l10n.trashPurgeAll,
          semanticLabel: hasSelection
              ? l10n.trashPurgeSelected
              : l10n.trashPurgeAll,
          onPressed: hasItems
              ? hasSelection
                    ? () {
                        final TrashPageState? state = readState();
                        if (state == null) {
                          return;
                        }
                        unawaited(
                          purgeTrashedComics(context, ref, state.selectedItems),
                        );
                      }
                    : () {
                        final TrashPageState? state = readState();
                        if (state == null) {
                          return;
                        }
                        unawaited(
                          purgeAllTrashedComics(
                            context,
                            ref,
                            state.allPurgeCounts,
                          ),
                        );
                      }
              : null,
        ),
      ],
    );
  }
}

class _TrashEmptyState extends StatelessWidget {
  const _TrashEmptyState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: PageLayoutSpec.of(context).stateTopInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Symbols.delete_sweep, size: 48, color: scheme.outline),
              SizedBox(height: theme.spacing.sm),
              Text(
                l10n.trashEmptyTitle,
                textAlign: TextAlign.center,
                style: theme.typeScale.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                l10n.trashEmptyDescription,
                textAlign: TextAlign.center,
                style: theme.typeScale.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
