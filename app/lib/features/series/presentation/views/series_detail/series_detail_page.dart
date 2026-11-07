import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/comic/public/comic_detail_return_series.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_size_notifier.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_cover.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_entry.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_layout.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/features/comic/public/di/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/metadata_refresh_toasts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

export 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_layout.dart';
export 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';

/// 生产系列详情页（MD3E）：服务端分页的漫画网格经映射层渲染 [SeriesDetailLayout]。
class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Series?> seriesAsync = ref.watch(
      seriesByIdStateProvider(seriesId),
    );

    return M3ETheme(
      data: withAppFontFamily(M3ETheme.of(context)),
      child: ColoredBox(
        color: M3ETheme.of(context).colorScheme.surface,
        child: seriesAsync.when(
          data: (Series? series) {
            if (series == null) {
              final AppLocalizations l10n = context.l10n;
              final String id = seriesId.trim();
              return DetailNotFoundStatus(
                icon: LucideIcons.library,
                label: l10n.seriesDetailNotFound(
                  id.isNotEmpty ? id : l10n.seriesDetailUnknown,
                ),
              );
            }
            return _SeriesDetailContent(series: series);
          },
          loading: () => const DetailLoadingStatus(),
          error: (Object error, StackTrace _) => DetailErrorStatus(
            label: context.l10n.seriesDetailLoadFailed(error.toString()),
          ),
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
        ),
      ),
    );
  }
}

class _SeriesDetailContent extends ConsumerStatefulWidget {
  const _SeriesDetailContent({required this.series});

  final Series series;

  @override
  ConsumerState<_SeriesDetailContent> createState() =>
      _SeriesDetailContentState();
}

class _SeriesDetailContentState extends ConsumerState<_SeriesDetailContent> {
  @override
  void dispose() {
    exitCatalogSelectionFromContext(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SeriesDetailLoaded(series: widget.series);
  }
}

/// 订阅系列元数据；目录分页下沉到 [_SeriesDetailCatalogLayout]。
class _SeriesDetailLoaded extends ConsumerWidget {
  const _SeriesDetailLoaded({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SeriesComicsMetadata? metadata = ref
        .watch(seriesComicsMetadataProvider(series.id))
        .value;
    return _SeriesDetailCatalogLayout(series: series, metadata: metadata);
  }
}

/// 只订阅目录与页大小，组装 [SeriesDetailLayout]。
class _SeriesDetailCatalogLayout extends ConsumerWidget {
  const _SeriesDetailCatalogLayout({
    required this.series,
    required this.metadata,
  });

  final Series series;
  final SeriesComicsMetadata? metadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String seriesId = series.id;
    final SeriesDetailComicsCatalogState? catalog = ref
        .watch(seriesDetailComicsCatalogControllerProvider(seriesId))
        .value;
    final int pageSize = ref.watch(seriesDetailActivePageSizeProvider);
    final int page = catalog?.pagination.page ?? 1;
    final int totalPages = catalog?.pagination.totalPages ?? 1;
    final List<SeriesComicPageItem> items =
        catalog?.items ?? const <SeriesComicPageItem>[];

    final SeriesDetailViewObject entry = seriesDetailEntry(
      series: series,
      cover: SeriesDetailCover(seriesId: seriesId),
      metadata: metadata,
      pageItems: items,
      page: page,
      pageSize: pageSize,
      comicCoverBuilder: (String comicId, int index) => ComicCoverContent(
        comicId: comicId,
        gridIndex: index,
        coverViewportScope: CoverViewportScopes.seriesDetail(seriesId),
      ),
    );
    final AppLocalizations l10n = context.l10n;

    return SeriesDetailLayout(
      entry: entry,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      onPageChanged: (int target) => ref
          .read(seriesDetailComicsCatalogControllerProvider(seriesId).notifier)
          .setPage(target),
      onPageSizeChanged: (int size) =>
          ref.read(seriesDetailPageSizeProvider.notifier).setPageSize(size),
      onBack: () => DetailBackHeader.popOrGoLibrary(context),
      onEdit: () => showSeriesMetadataEdit(context: context, series: series),
      moreMenuEntries: <M3EMenuNode>[
        M3EMenuEntry(
          label: l10n.refreshMetadata,
          leading: const Icon(LucideIcons.refreshCw),
          onPressed: () => _refreshMetadata(context, ref, series),
        ),
        M3EMenuEntry(
          label: l10n.catalogSelectionEnter,
          leading: const Icon(LucideIcons.squareCheck),
          onPressed: () => ref
              .read(catalogSelectionProvider.notifier)
              .enter(CatalogSelectionHost.seriesDetail),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailShowInExplorer,
          leading: const Icon(LucideIcons.folderOpen),
          onPressed: () => _showInExplorer(context, series),
        ),
      ],
      onAuthorTap: (String name) =>
          openAuthorDetailByName(context: context, ref: ref, name: name),
      onComicTap: (int globalIndex) {
        final int localIndex = globalIndex - (page - 1) * pageSize;
        if (localIndex < 0 || localIndex >= items.length) {
          return;
        }
        ref.read(comicDetailReturnSeriesProvider.notifier).remember(seriesId);
        ref
            .read(appRouterProvider)
            .pushNamed(
              ContentBreadcrumbLabels.comicDetail,
              pathParameters: <String, String>{
                'id': items[localIndex].comic.comicId,
              },
            );
      },
    );
  }
}

Future<void> _refreshMetadata(
  BuildContext context,
  WidgetRef ref,
  Series series,
) async {
  try {
    final MetadataRefreshBatchResult result = await ref
        .read(libraryMetadataRefreshCommandPortProvider)
        .refreshSeries(seriesId: series.id, name: series.name);
    if (!context.mounted) {
      return;
    }
    showMetadataRefreshBatchToast(context, result);
  } catch (err) {
    if (context.mounted) {
      showErrorSnackbar(context, err);
    }
  }
}

void _showInExplorer(BuildContext context, Series series) {
  final AppLocalizations l10n = context.l10n;
  showInFileExplorer(series.folderPath).catchError((
    Object error,
    StackTrace stackTrace,
  ) {
    if (!context.mounted) {
      return;
    }
    if (error is AppException) {
      showErrorSnackbar(context, error);
      return;
    }
    showErrorSnackbar(
      context,
      AppException(
        l10n.comicDetailShowInExplorerFailed,
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  });
}
