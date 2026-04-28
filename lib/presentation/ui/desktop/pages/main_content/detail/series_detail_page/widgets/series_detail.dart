import 'package:flutter/material.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/responsive_layout/detail_page_layout.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/library_return_breadcrumb.dart';
import 'actions.dart';
import 'series_comic_items_card.dart';
import 'series_detail_card.dart';
import 'series_detail_cover.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class SeriesDetail extends StatelessWidget {
  const SeriesDetail({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final int count = series.items.length;

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Tooltip(
          message: series.name,
          waitDuration: const Duration(milliseconds: 2000),
          child: SelectableText(
            series.name,
            maxLines: 1,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: cs.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '包含 $count 本',
          style: TextStyle(color: cs.textTertiary, fontSize: 12),
        ),
      ],
    );

    return DetailResponsiveLayout(
      header: LibraryReturnBreadcrumb(
        trailingLabel: series.name,
        trailingTooltip: series.name,
      ),
      headerSpacing: tokens.spacing.md + 4,
      bodyBuilder: (BuildContext context, DetailPanelSize panel) {
        return SeriesDetailCard(
          maxWidth: panel.targetWidth,
          padding: EdgeInsets.all(tokens.spacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 2,
                child: Center(child: SeriesDetailCover(series: series)),
              ),
              SizedBox(width: tokens.spacing.lg + 16),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: .min,
                  spacing: 16,
                  children: <Widget>[
                    titleBlock,
                    SeriesDetailActions(
                      series: series,
                      sortedItems: sortedItems,
                    ),
                    Flexible(
                      child: SeriesComicItemsCard(
                        colorScheme: cs,
                        listCardRadius: tokens.radius.lg,
                        sortedItems: sortedItems,
                        seriesName: series.name,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
