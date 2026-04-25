import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/library_return_breadcrumb.dart';
import 'actions.dart';
import 'series_comic_items_card.dart';
import 'series_detail_card.dart';
import 'adaptiv_series_cover.dart';
import 'package:hentai_library/theme/theme.dart';

class SeriesDetail extends ConsumerWidget {
  const SeriesDetail({super.key, required this.series});

  final Series series;

  static const double _kContentWidthRatio = 0.8;
  static const double _kContentHeightRatio = 0.8;
  static const double _kContentMinWidth = 980;
  static const double _kContentMaxWidth = 1320;
  static const double _kContentMinHeight = 560;
  static const double _kContentMaxHeight = 920;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final int count = series.items.length;

    return Container(
      color: cs.winBackground,
      padding: .symmetric(
        horizontal: tokens.spacing.lg + 8,
        vertical: tokens.spacing.lg + 8,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size mediaSize = MediaQuery.sizeOf(context);
          final double parentWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : mediaSize.width;
          final double parentHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : mediaSize.height;
          final double targetWidth = (parentWidth * _kContentWidthRatio).clamp(
            _kContentMinWidth,
            _kContentMaxWidth,
          );
          final double targetHeight = (parentHeight * _kContentHeightRatio)
              .clamp(_kContentMinHeight, _kContentMaxHeight);
          final double panelWidth = math.min(parentWidth, targetWidth);
          final double panelHeight = math.min(parentHeight, targetHeight);

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LibraryReturnBreadcrumb(
                    trailingLabel: series.name,
                    trailingTooltip: series.name,
                  ),
                  SizedBox(height: tokens.spacing.md + 4),
                  Expanded(
                    child: SeriesDetailCard(
                      maxWidth: targetWidth,
                      padding: EdgeInsets.all(tokens.spacing.xl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            flex: 2,
                            child: Center(
                              child: AdaptiveSeriesCover(series: series),
                            ),
                          ),
                          SizedBox(width: tokens.spacing.lg + 16),
                          Flexible(
                            flex: 3,
                            child: _buildRightColumn(
                              tokens: tokens,
                              colorScheme: cs,
                              sortedItems: sortedItems,
                              count: count,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleBlock({
    required ColorScheme colorScheme,
    required int count,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          series.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '包含 $count 本',
          style: TextStyle(color: colorScheme.textTertiary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRightColumn({
    required AppThemeTokens tokens,
    required ColorScheme colorScheme,
    required List<SeriesItem> sortedItems,
    required int count,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: .min,
      spacing: 16,
      children: <Widget>[
        _buildTitleBlock(colorScheme: colorScheme, count: count),
        SeriesDetailActions(series: series, sortedItems: sortedItems),
        Flexible(
          child: SeriesComicItemsCard(
            colorScheme: colorScheme,
            listCardRadius: tokens.radius.lg,
            sortedItems: sortedItems,
            seriesName: series.name,
          ),
        ),
      ],
    );
  }
}
