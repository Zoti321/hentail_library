import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/detail_primary_row_layout.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_external_exit.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_mode.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_cover.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_header.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_info_sections.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_members_section.dart';
import 'package:hentai_library/ui/features/shell/state/metadata_refresh_controller.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
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

  void _exitReorderForExternalChange() {
    if (!ref.read(seriesReorderModeProvider(widget.series.id))) {
      return;
    }
    ref
        .read(seriesReorderModeProvider(widget.series.id).notifier)
        .exitForExternalChange();
  }

  void _reloadFullMembers() {
    ref.invalidate(seriesReorderControllerProvider(widget.series.id));
  }

  @override
  Widget build(BuildContext context) {
    final bool reorderMode = ref.watch(
      seriesReorderModeProvider(widget.series.id),
    );
    // 打开详情即预拉全量成员，供浏览窗口与 reorder 共用。
    ref.watch(seriesReorderControllerProvider(widget.series.id));

    ref.listen<bool>(
      scanLibraryControllerProvider.select((ScanLibraryState s) => s.running),
      (bool? previous, bool next) {
        if (!shouldExitSeriesReorderAfterScan(
          previousRunning: previous,
          nextRunning: next,
        )) {
          return;
        }
        _exitReorderForExternalChange();
        _reloadFullMembers();
      },
    );
    ref.listen<MetadataRefreshState>(metadataRefreshControllerProvider, (
      MetadataRefreshState? previous,
      MetadataRefreshState next,
    ) {
      if (!shouldExitSeriesReorderAfterMetadataRefresh(
        previous: previous,
        next: next,
        seriesId: widget.series.id,
      )) {
        return;
      }
      _exitReorderForExternalChange();
      _reloadFullMembers();
    });
    ref.listen<bool>(seriesReorderModeProvider(widget.series.id), (
      bool? previous,
      bool next,
    ) {
      if ((previous ?? false) && !next) {
        _reloadFullMembers();
      }
    });

    ref.listen<int>(seriesDetailActivePageSizeProvider, (
      int? previous,
      int next,
    ) {
      if (reorderMode) {
        return;
      }
      if (previous == null || previous == next) {
        return;
      }
      _scrollToGridTop();
    });

    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double horizontalPadding = detailContentHorizontalPadding(context);
    final AsyncValue<SeriesComicsMetadata?> metadataAsync = ref.watch(
      seriesComicsMetadataProvider(widget.series.id),
    );
    final SeriesComicsMetadata? metadata = metadataAsync.value;
    final bool hasMetadata = metadata?.hasMetadataBlock ?? false;
    final double sectionGap = tokens.spacing.xl + 8;

    final Widget upper = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildPrimarySection(
          context,
          tokens,
          cs,
          hasR18: metadata?.hasR18 ?? false,
          languages: metadata?.languages ?? const <String>[],
        ),
        SizedBox(height: sectionGap),
        if (hasMetadata) ...<Widget>[
          SeriesDetailMetadataBlock(
            authors: metadata!.authors,
            tags: metadata.tags,
            parodies: metadata.parodies,
            characters: metadata.characters,
          ),
          SizedBox(height: sectionGap),
        ],
        Divider(
          height: 1,
          thickness: 1 / MediaQuery.devicePixelRatioOf(context),
          color: cs.hentai.borderSubtle,
        ),
        SizedBox(height: tokens.spacing.lg),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SeriesDetailHeader(series: widget.series),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  tokens.spacing.xl,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: IgnorePointer(
                    ignoring: reorderMode,
                    child: upper
                        .animate()
                        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
                        .slideY(
                          begin: 0.03,
                          duration: 260.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  tokens.spacing.xl + 8,
                ),
                sliver: SeriesDetailMembersSection(
                  seriesId: widget.series.id,
                  scrollController: _scrollController,
                  gridSectionKey: _gridSectionKey,
                ),
              ),
            ],
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
    required List<String> languages,
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
            languages: languages,
          ),
        ],
      ),
    );
  }
}
