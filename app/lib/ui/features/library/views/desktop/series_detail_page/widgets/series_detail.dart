import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/desktop/series_detail_page/widgets/series_detail_comics_grid.dart';
import 'package:hentai_library/ui/features/library/views/desktop/series_detail_page/widgets/series_detail_cover.dart';
import 'package:hentai_library/ui/features/library/views/desktop/series_detail_page/widgets/series_detail_header.dart';
import 'package:hentai_library/ui/features/library/views/desktop/series_detail_page/widgets/series_detail_info_sections.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeriesDetail extends HookConsumerWidget {
  const SeriesDetail({super.key, required this.series});

  final Series series;

  static const double _coverWidth = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final int changeGeneration = ref.watch(
      comicAggregateProvider.select(
        (ComicAggregateState state) => state.changeGeneration,
      ),
    );
    final Future<List<Comic>> comicsFuture = useMemoized(
      () => ref.read(comicRepoProvider).getAll(),
      <Object?>[changeGeneration, series.id],
    );
    final AsyncSnapshot<List<Comic>> comicsSnapshot = useFuture(comicsFuture);
    final Map<String, Comic> comicsById = comicsByIdFromList(
      comicsSnapshot.data ?? <Comic>[],
    );
    final bool hasMetadata = seriesDetailHasMetadataBlock(
      sortedItems,
      comicsById,
    );
    final double sectionGap = tokens.spacing.xl + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SeriesDetailHeader(series: series),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              tokens.layout.contentHorizontalPadding,
              tokens.spacing.xl,
              tokens.layout.contentHorizontalPadding,
              tokens.spacing.xl + 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildPrimaryRow(context, tokens, cs, comicsById, sortedItems),
                SizedBox(height: sectionGap),
                if (hasMetadata) ...<Widget>[
                  SeriesDetailMetadataBlock(
                    sortedItems: sortedItems,
                    comicsById: comicsById,
                  ),
                  SizedBox(height: sectionGap),
                ],
                Divider(
                  height: 1,
                  thickness: 1 / MediaQuery.devicePixelRatioOf(context),
                  color: cs.hentai.borderSubtle,
                ),
                SizedBox(height: tokens.spacing.lg),
                SeriesDetailComicsGrid(
                  sortedItems: sortedItems,
                  comicsById: comicsById,
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

  Widget _buildPrimaryRow(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme cs,
    Map<String, Comic> comicsById,
    List<SeriesItem> sortedItems,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: _coverWidth,
          child: SeriesDetailCover(series: series),
        ),
        SizedBox(width: tokens.spacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spacing.md,
            children: <Widget>[
              Tooltip(
                message: series.name,
                waitDuration: const Duration(milliseconds: 2000),
                child: SelectableText(
                  series.name,
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
                series: series,
                comicsById: comicsById,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
