import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
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
            final String comicIdToOpen = sortedItems.first.comicId;
            appRouter.pushNamed(
              ReaderRouteArgs.readerRouteName,
              queryParameters: ReaderRouteArgs(
                comicId: comicIdToOpen,
                readType: ReaderRouteArgs.readTypeSeries,
                seriesId: series.id,
              ).toQueryParameters(),
            );
          },
          icon: const Icon(LucideIcons.bookOpen, size: 16),
          label: const Text('阅读系列'),
          style: primarySeriesToolbarStyle,
        ),
      ],
    );
  }
}
