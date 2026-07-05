import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/library/views/desktop/series_detail_page/widgets/widgets.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return ColoredBox(
      color: cs.surface,
      child: seriesAsync.when(
        data: (List<Series> list) {
          Series? found;
          for (final Series series in list) {
            if (series.id == seriesId) {
              found = series;
              break;
            }
          }
          if (found == null) {
            return SeriesNotFound(seriesId: seriesId);
          }
          return SeriesDetail(series: found);
        },
        loading: () => const SeriesDetailLoading(),
        error: (Object error, StackTrace _) => SeriesDetailError(error: error),
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      ),
    );
  }
}
