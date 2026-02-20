import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/add_comics_to_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/rename_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/reorder_series_items_dialog.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailActions extends ConsumerWidget {
  const SeriesDetailActions({
    super.key,
    required this.series,
    required this.sortedItems,
  });
  final Series series;
  final List<SeriesItem> sortedItems;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ButtonStyle primarySeriesToolbarStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(
          onPressed: () async {
            if (sortedItems.isEmpty) {
              showInfoToast(context, '系列内暂无漫画');
              return;
            }
            final SeriesReadingHistory? seriesProgress = await ref
                .read(readingHistoryRepoProvider)
                .getSeriesReadingBySeriesName(series.name);
            String comicIdToOpen = sortedItems.first.comicId;
            if (seriesProgress != null) {
              final String lastId = seriesProgress.lastReadComicId;
              final bool lastStillInSeries = sortedItems.any(
                (SeriesItem e) => e.comicId == lastId,
              );
              if (lastStillInSeries) {
                comicIdToOpen = lastId;
              }
            }
            appRouter.pushNamed(
              ReaderRouteArgs.readerRouteName,
              queryParameters: ReaderRouteArgs(
                comicId: comicIdToOpen,
                readType: ReaderRouteArgs.readTypeSeries,
                seriesName: series.name,
              ).toQueryParameters(),
            );
          },
          icon: const Icon(LucideIcons.bookOpen, size: 16),
          label: const Text('阅读系列'),
          style: primarySeriesToolbarStyle,
        ),
        GhostButton.icon(
          tooltip: '添加漫画',
          semanticLabel: '添加漫画',
          icon: LucideIcons.plus,
          onPressed: () async {
            await showDialog<void>(
              context: context,
              builder: (BuildContext context) => AddComicsToSeriesDialog(
                key: ValueKey<String>(series.name),
                series: series,
              ),
            );
          },
        ),
        GhostButton.icon(
          tooltip: '调整顺序',
          semanticLabel: '调整顺序',
          icon: LucideIcons.arrowUpDown,
          onPressed: () {
            if (series.items.length < 2) {
              showInfoToast(context, '至少需要 2 本漫画才能调整顺序');
              return;
            }
            showDialog<void>(
              context: context,
              builder: (BuildContext context) =>
                  ReorderSeriesItemsDialog(series: series),
            );
          },
        ),
        GhostButton.icon(
          tooltip: '重命名',
          semanticLabel: '重命名',
          icon: LucideIcons.squarePen,
          onPressed: () async {
            final String? newName = await showDialog<String>(
              context: context,
              builder: (BuildContext context) =>
                  RenameSeriesDialog(series: series),
            );
            if (newName != null && context.mounted) {
              showSuccessToast(context, '已重命名');
              context.goNamed(
                '系列详情',
                pathParameters: <String, String>{'name': newName},
              );
            }
          },
        ),
      ],
    );
  }
}
