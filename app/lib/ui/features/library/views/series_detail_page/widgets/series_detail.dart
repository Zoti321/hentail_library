import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/pagination/library_pagination_bar.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/detail_primary_row_layout.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_comics_grid.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_cover.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_header.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_info_sections.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_pagination_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeriesDetail extends ConsumerStatefulWidget {
  const SeriesDetail({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<SeriesDetail> createState() => _SeriesDetailState();
}

class _SeriesDetailState extends ConsumerState<SeriesDetail> {
  final GlobalKey _gridSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToGridTop() {
    final BuildContext? gridContext = _gridSectionKey.currentContext;
    if (gridContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      gridContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(
      seriesDetailComicsCatalogControllerProvider(widget.series.id).select(
        (AsyncValue<SeriesDetailComicsCatalogState> async) =>
            async.value?.pagination.page,
      ),
      (int? previous, int? next) {
        if (previous == null || next == null || previous == next) {
          return;
        }
        _scrollToGridTop();
      },
    );
    ref.listen<int>(seriesDetailActivePageSizeProvider, (int? previous, int next) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToGridTop();
    });

    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double horizontalPadding = detailContentHorizontalPadding(context);
    final AsyncValue<SeriesDetailComicsCatalogState> catalogAsync = ref.watch(
      seriesDetailComicsCatalogControllerProvider(widget.series.id),
    );
    final AsyncValue<SeriesComicsMetadata?> metadataAsync = ref.watch(
      seriesComicsMetadataProvider(widget.series.id),
    );
    final SeriesComicsMetadata? metadata = metadataAsync.value;
    final bool hasMetadata = metadata?.hasMetadataBlock ?? false;
    final double sectionGap = tokens.spacing.xl + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SeriesDetailHeader(series: widget.series),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              tokens.spacing.xl,
              horizontalPadding,
              tokens.spacing.xl + 8,
            ),
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildPrimarySection(
                          context,
                          tokens,
                          cs,
                          hasR18: metadata?.hasR18 ?? false,
                        ),
                        SizedBox(height: sectionGap),
                        if (hasMetadata) ...<Widget>[
                          SeriesDetailMetadataBlock(
                            authors: metadata!.authors,
                            tags: metadata.tags,
                          ),
                          SizedBox(height: sectionGap),
                        ],
                        Divider(
                          height: 1,
                          thickness: 1 / MediaQuery.devicePixelRatioOf(context),
                          color: cs.hentai.borderSubtle,
                        ),
                        SizedBox(height: tokens.spacing.lg),
                        KeyedSubtree(
                          key: _gridSectionKey,
                          child: _buildComicsSection(catalogAsync),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
                    .slideY(
                      begin: 0.03,
                      duration: 260.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimarySection(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme cs, {
    required bool hasR18,
  }) {
    return DetailPrimaryRowLayout(
      cover: SeriesDetailCover(series: widget.series),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.md,
        children: <Widget>[
          Tooltip(
            message: widget.series.name,
            waitDuration: const Duration(milliseconds: 2000),
            child: SelectableText(
              widget.series.name,
              maxLines: 2,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: cs.hentai.textPrimary,
                height: 1.25,
              ),
            ),
          ),
          SeriesDetailSummaryMetaRow(
            series: widget.series,
            hasR18: hasR18,
          ),
        ],
      ),
    );
  }

  Widget _buildComicsSection(
    AsyncValue<SeriesDetailComicsCatalogState> catalogAsync,
  ) {
    // skipLoadingOnReload: revision bump（如阅读进度写入）时保留网格高度，避免 scroll clamp 回顶。
    return catalogAsync.when(
      skipLoadingOnReload: true,
      data: (SeriesDetailComicsCatalogState catalog) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SeriesDetailPaginationBar(
              seriesId: widget.series.id,
              page: catalog.pagination.page,
              totalPages: catalog.pagination.totalPages,
              isLoading: catalogAsync.isLoading,
              placement: LibraryPaginationPlacement.top,
            ),
            SeriesDetailComicsGrid(
              comics: catalog.items,
              isLoading: catalogAsync.isLoading,
            ),
            SeriesDetailPaginationBar(
              seriesId: widget.series.id,
              page: catalog.pagination.page,
              totalPages: catalog.pagination.totalPages,
              isLoading: catalogAsync.isLoading,
              placement: LibraryPaginationPlacement.bottom,
            ),
          ],
        );
      },
      loading: () => const SeriesDetailComicsGrid(
        comics: <Comic>[],
        isLoading: true,
      ),
      error: (Object error, StackTrace _) => _SeriesDetailComicsError(
        error: error,
        onRetry: () => ref
            .read(
              seriesDetailComicsCatalogControllerProvider(
                widget.series.id,
              ).notifier,
            )
            .refresh(),
      ),
    );
  }
}

class _SeriesDetailComicsError extends StatelessWidget {
  const _SeriesDetailComicsError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
      child: Column(
        spacing: tokens.spacing.sm,
        children: <Widget>[
          Text(
            '漫画列表加载失败',
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.hentai.textSecondary,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
