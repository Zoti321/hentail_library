import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/comic/public/comic_detail_return_series.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_facade_notifier.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_size_notifier.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_md3e_cover.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_md3e_entry.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_page.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
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

/// 生产系列详情页（MD3E）：服务端分页的漫画网格经映射层渲染 [Md3eSeriesDetailPage]。
class SeriesDetailMd3ePage extends ConsumerWidget {
  const SeriesDetailMd3ePage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Series?> seriesAsync = ref.watch(
      seriesByIdStateProvider(seriesId),
    );

    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
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
            return _SeriesDetailMd3eContent(series: series);
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

class _SeriesDetailMd3eContent extends ConsumerStatefulWidget {
  const _SeriesDetailMd3eContent({required this.series});

  final Series series;

  @override
  ConsumerState<_SeriesDetailMd3eContent> createState() =>
      _SeriesDetailMd3eContentState();
}

class _SeriesDetailMd3eContentState
    extends ConsumerState<_SeriesDetailMd3eContent> {
  @override
  void dispose() {
    exitCatalogSelectionFromContext(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Series series = widget.series;
    final String seriesId = series.id;
    final SeriesComicsMetadata? metadata = ref
        .watch(seriesComicsMetadataProvider(seriesId))
        .value;
    final SeriesDetailPageFacadeState facade = ref.watch(
      seriesDetailPageFacadeProvider(seriesId),
    );
    final SeriesDetailComicsCatalogState? catalog = facade.catalog.value;
    final int pageSize = facade.pageSize;
    final int page = catalog?.pagination.page ?? 1;
    final int totalPages = catalog?.pagination.totalPages ?? 1;
    final List<SeriesComicPageItem> items =
        catalog?.items ?? const <SeriesComicPageItem>[];

    final Md3eSeriesDetailEntry entry = seriesDetailMd3eEntry(
      series: series,
      cover: SeriesDetailMd3eCover(seriesId: seriesId),
      metadata: metadata,
      pageItems: items,
      page: page,
      pageSize: pageSize,
      comicCoverBuilder: (String comicId) =>
          ComicCoverContent(comicId: comicId),
    );
    final AppLocalizations l10n = context.l10n;

    return Md3eSeriesDetailPage(
      entry: entry,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      onPageChanged: (int target) => ref
          .read(seriesDetailPageFacadeProvider(seriesId).notifier)
          .setPage(target),
      onPageSizeChanged: (int size) =>
          ref.read(seriesDetailPageSizeProvider.notifier).setPageSize(size),
      onBack: () => DetailBackHeader.popOrGoLibrary(context),
      onEdit: () =>
          showSeriesMetadataEditMd3e(context: context, series: series),
      moreMenuEntries: <M3EMenuNode>[
        M3EMenuEntry(
          label: l10n.refreshMetadata,
          leading: const Icon(LucideIcons.refreshCw),
          onPressed: () => _refreshMetadata(context),
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

  Future<void> _refreshMetadata(BuildContext context) async {
    try {
      final MetadataRefreshBatchResult result = await ref
          .read(libraryMetadataRefreshCommandPortProvider)
          .refreshSeries(seriesId: widget.series.id, name: widget.series.name);
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
    showInFileExplorer(series.folderPath)
        .catchError((Object error, StackTrace stackTrace) {
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
}
