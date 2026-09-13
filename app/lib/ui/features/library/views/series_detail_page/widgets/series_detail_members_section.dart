import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/pagination/library_pagination_bar.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/series_members_page_window.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_mode.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_comic_card.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_comics_grid.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_pagination_bar.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 系列详情成员区：浏览 / Series reorder mode 共用同一网格（#121）。
///
/// 全量预拉就绪后始终挂全量 children（分页只滚动窗口），避免进模式换树打断长按直拖。
class SeriesDetailMembersSection extends HookConsumerWidget {
  const SeriesDetailMembersSection({
    super.key,
    required this.seriesId,
    required this.scrollController,
    required this.gridSectionKey,
  });

  final String seriesId;
  final ScrollController scrollController;
  final GlobalKey gridSectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool reorderMode = ref.watch(seriesReorderModeProvider(seriesId));
    final AsyncValue<List<SeriesComicPageItem>> membersAsync = ref.watch(
      seriesReorderControllerProvider(seriesId),
    );
    final int pageSize = ref.watch(seriesDetailActivePageSizeProvider);
    final ValueNotifier<int> page = useState(1);

    final List<SeriesComicPageItem>? allMembers = membersAsync.asData?.value;
    if (allMembers == null) {
      if (reorderMode || membersAsync.hasError) {
        return _MembersStatusSliver(
          seriesId: seriesId,
          membersAsync: membersAsync,
        );
      }
      final AsyncValue<SeriesDetailComicsCatalogState> catalogAsync = ref.watch(
        seriesDetailComicsCatalogControllerProvider(seriesId),
      );
      return _CatalogFallbackSliver(
        seriesId: seriesId,
        catalogAsync: catalogAsync,
        gridSectionKey: gridSectionKey,
      );
    }

    final int totalPages = seriesMembersTotalPages(
      totalCount: allMembers.length,
      pageSize: pageSize,
    );
    if (page.value > totalPages) {
      page.value = totalPages;
    }

    final GlobalKey gridViewKey = useMemoized(GlobalKey.new);
    final List<GlobalKey> itemKeys = useMemoized(
      () => List<GlobalKey>.generate(allMembers.length, (_) => GlobalKey()),
      <Object>[allMembers.length],
    );
    final ValueNotifier<bool> reorderScheduled = useState(false);

    useEffect(() {
      if (reorderMode || allMembers.isEmpty) {
        return null;
      }
      final int targetIndex = (page.value - 1) * pageSize;
      if (targetIndex < 0 || targetIndex >= itemKeys.length) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? target = itemKeys[targetIndex].currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            alignment: 0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
      return null;
    }, <Object?>[page.value, pageSize, reorderMode, allMembers.length]);

    final AppThemeTokens tokens = context.tokens;
    final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final SliverGridDelegate gridDelegate = libraryGridDelegateForTokens(
      tokens,
      layoutTier,
    );

    final List<Widget> children = <Widget>[
      for (int i = 0; i < allMembers.length; i++)
        KeyedSubtree(
          key: ValueKey<String>(allMembers[i].comic.comicId),
          child: KeyedSubtree(
            key: itemKeys[i],
            child: SeriesDetailComicCard(
              seriesId: seriesId,
              item: allMembers[i],
              gridIndex: i,
              reorderMode: reorderMode,
              onTap: () {
                if (reorderMode) {
                  return;
                }
                ref
                    .read(comicDetailReturnSeriesProvider.notifier)
                    .remember(seriesId);
                appRouter.pushNamed(
                  '漫画详情',
                  pathParameters: <String, String>{
                    'id': allMembers[i].comic.comicId,
                  },
                );
              },
            ),
          ),
        ),
    ];

    void goToPage(int next) {
      page.value = next.clamp(1, totalPages);
    }

    return SliverMainAxisGroup(
      slivers: <Widget>[
        if (!reorderMode)
          SliverToBoxAdapter(
            key: gridSectionKey,
            child: SeriesDetailPaginationBar(
              seriesId: seriesId,
              page: page.value,
              totalPages: totalPages,
              placement: LibraryPaginationPlacement.top,
              onFirst: () => goToPage(1),
              onPrevious: () => goToPage(page.value - 1),
              onNext: () => goToPage(page.value + 1),
              onLast: () => goToPage(totalPages),
            ),
          )
        else
          SliverToBoxAdapter(
            key: gridSectionKey,
            child: const SizedBox.shrink(),
          ),
        SliverToBoxAdapter(
          child: ReorderableBuilder<SeriesComicPageItem>(
            scrollController: scrollController,
            longPressDelay: const Duration(milliseconds: 120),
            enableDraggable: true,
            onDragStarted: (int _) {
              ref.read(seriesReorderModeProvider(seriesId).notifier).enter();
              ref
                  .read(seriesReorderControllerProvider(seriesId).notifier)
                  .beginDrag();
            },
            onDragEnd: (int _) {
              // onDragEnd 先于 onReorder；若即将落库则由 reorder.finally endDrag。
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!reorderScheduled.value) {
                  ref
                      .read(seriesReorderControllerProvider(seriesId).notifier)
                      .endDrag();
                }
              });
            },
            onReorder:
                (ReorderedListFunction<SeriesComicPageItem> reorderFunction) {
                  reorderScheduled.value = true;
                  final List<SeriesComicPageItem> updated = reorderFunction(
                    allMembers,
                  );
                  ref
                      .read(seriesReorderControllerProvider(seriesId).notifier)
                      .reorder(updated)
                      .catchError((Object error) {
                        if (context.mounted) {
                          showErrorToast(context, error);
                        }
                      })
                      .whenComplete(() {
                        reorderScheduled.value = false;
                      });
                },
            children: children,
            builder: (List<Widget> reorderedChildren) {
              return GridView(
                key: gridViewKey,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: tokens.spacing.md),
                gridDelegate: gridDelegate,
                children: reorderedChildren,
              );
            },
          ),
        ),
        if (!reorderMode)
          SliverToBoxAdapter(
            child: SeriesDetailPaginationBar(
              seriesId: seriesId,
              page: page.value,
              totalPages: totalPages,
              placement: LibraryPaginationPlacement.bottom,
              onFirst: () => goToPage(1),
              onPrevious: () => goToPage(page.value - 1),
              onNext: () => goToPage(page.value + 1),
              onLast: () => goToPage(totalPages),
            ),
          ),
      ],
    );
  }
}

class _MembersStatusSliver extends ConsumerWidget {
  const _MembersStatusSliver({
    required this.seriesId,
    required this.membersAsync,
  });

  final String seriesId;
  final AsyncValue<List<SeriesComicPageItem>> membersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    if (membersAsync.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
        child: Column(
          spacing: tokens.spacing.sm,
          children: <Widget>[
            Text(
              l10n.seriesDetailComicsLoadFailed,
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(seriesReorderControllerProvider(seriesId)),
              child: Text(l10n.shellRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogFallbackSliver extends ConsumerWidget {
  const _CatalogFallbackSliver({
    required this.seriesId,
    required this.catalogAsync,
    required this.gridSectionKey,
  });

  final String seriesId;
  final AsyncValue<SeriesDetailComicsCatalogState> catalogAsync;
  final GlobalKey gridSectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return catalogAsync.when(
      skipLoadingOnReload: true,
      data: (SeriesDetailComicsCatalogState catalog) {
        return SliverMainAxisGroup(
          slivers: <Widget>[
            SliverToBoxAdapter(
              key: gridSectionKey,
              child: SeriesDetailPaginationBar(
                seriesId: seriesId,
                page: catalog.pagination.page,
                totalPages: catalog.pagination.totalPages,
                placement: LibraryPaginationPlacement.top,
              ),
            ),
            SeriesDetailComicsGridSliver(
              seriesId: seriesId,
              items: catalog.items,
              isLoading: catalogAsync.isLoading,
            ),
            SliverToBoxAdapter(
              child: SeriesDetailPaginationBar(
                seriesId: seriesId,
                page: catalog.pagination.page,
                totalPages: catalog.pagination.totalPages,
                placement: LibraryPaginationPlacement.bottom,
              ),
            ),
          ],
        );
      },
      loading: () => SeriesDetailComicsGridSliver(
        seriesId: seriesId,
        items: const <SeriesComicPageItem>[],
        isLoading: true,
      ),
      error: (Object error, StackTrace _) {
        final AppThemeTokens tokens = context.tokens;
        final ColorScheme cs = Theme.of(context).colorScheme;
        final AppLocalizations l10n = context.l10n;
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
            child: Column(
              spacing: tokens.spacing.sm,
              children: <Widget>[
                Text(
                  l10n.seriesDetailComicsLoadFailed,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    color: cs.hentai.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(
                        seriesDetailComicsCatalogControllerProvider(
                          seriesId,
                        ).notifier,
                      )
                      .refresh(),
                  child: Text(l10n.shellRetry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
