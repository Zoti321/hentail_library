import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/series_detail_page/widgets/widgets.dart';
import 'package:hentai_library/theme/theme.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesName});

  final String seriesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return Container(
      color: cs.winBackground,
      padding: .symmetric(
        horizontal: tokens.spacing.lg + 8,
        vertical: tokens.spacing.lg + 8,
      ),
      child: seriesAsync.when(
        data: (List<Series> list) {
          Series? found;
          for (final Series s in list) {
            if (s.name == seriesName) {
              found = s;
              break;
            }
          }

          if (found == null) {
            return SeriesNotFound(seriesName: seriesName);
          }

          return SeriesDetail(series: found);
        },
        loading: () => const SeriesDetailLoading(),
        error: (Object e, StackTrace _) => SeriesDetailError(error: e),
      ),
    );
  }
}
