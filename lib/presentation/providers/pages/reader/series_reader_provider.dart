import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/model/entity/series_reading_history.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/widgets/reader_route_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reader_provider.g.dart';

class ReaderSeriesContextData {
  const ReaderSeriesContextData({
    required this.navContext,
    required this.preferredPageIndex,
  });
  final ReaderNavContextData navContext;
  final int? preferredPageIndex;
}

/// Loads a [Series] by name for reader navigation (series read mode).
@riverpod
Future<Series?> seriesByNameForReader(Ref ref, String seriesName) async {
  if (seriesName.isEmpty) {
    return null;
  }
  return ref.read(librarySeriesRepoProvider).findByName(seriesName);
}

@riverpod
Future<SeriesReadingHistory?> seriesReadingProgressForReader(
  Ref ref,
  String seriesName,
) async {
  if (seriesName.isEmpty) {
    return null;
  }
  return ref
      .read(readingHistoryRepoProvider)
      .getSeriesReadingBySeriesName(seriesName);
}

@riverpod
Future<ReaderSeriesContextData> readerSeriesContextForReader(
  Ref ref, {
  required String comicId,
  required bool isSeriesMode,
  String? seriesName,
}) async {
  if (!isSeriesMode || seriesName == null || seriesName.isEmpty) {
    final String title = await _readComicTitle(ref, comicId);
    return ReaderSeriesContextData(
      navContext: buildReaderNavContextData(
        items: <ReaderComicListItem>[
          ReaderComicListItem(comicId: comicId, title: title, order: 0),
        ],
        currentComicId: comicId,
        preferredPageIndex: null,
      ),
      preferredPageIndex: null,
    );
  }
  final Series? series = await ref.watch(
    seriesByNameForReaderProvider(seriesName).future,
  );
  final List<ReaderComicListItem> seriesItems = await _buildSeriesItems(
    ref,
    series,
  );
  final SeriesReadingHistory? progress = await ref.watch(
    seriesReadingProgressForReaderProvider(seriesName).future,
  );
  final int? preferredPageIndex = progress?.lastReadComicId == comicId
      ? progress?.pageIndex
      : null;
  return ReaderSeriesContextData(
    navContext: buildReaderNavContextData(
      items: seriesItems,
      currentComicId: comicId,
      preferredPageIndex: preferredPageIndex,
      seriesName: seriesName,
    ),
    preferredPageIndex: preferredPageIndex,
  );
}

Future<String> _readComicTitle(Ref ref, String comicId) async {
  final comic = await ref.read(comicRepoProvider).findById(comicId);
  final String fallbackTitle = comicId.length > 12
      ? '${comicId.substring(0, 12)}…'
      : comicId;
  return comic?.title ?? fallbackTitle;
}

Future<List<ReaderComicListItem>> _buildSeriesItems(
  Ref ref,
  Series? series,
) async {
  if (series == null || series.items.isEmpty) {
    return const <ReaderComicListItem>[];
  }
  final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  final List<ReaderComicListItem> items = <ReaderComicListItem>[];
  for (final SeriesItem item in sortedItems) {
    final String title = await _readComicTitle(ref, item.comicId);
    items.add(
      ReaderComicListItem(
        comicId: item.comicId,
        title: title,
        order: item.order,
      ),
    );
  }
  return items;
}
