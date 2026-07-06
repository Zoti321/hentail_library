import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/entity/series_reading_history.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reader_provider.g.dart';

class ReadSessionContextData {
  const ReadSessionContextData({
    required this.mode,
    required this.seriesId,
    required this.navContext,
    required this.preferredPageIndex,
  });

  final ReadSessionMode mode;
  final String? seriesId;
  final ReaderNavContextData navContext;
  final int? preferredPageIndex;

  bool get isSeriesRead => mode == ReadSessionMode.series;
}

@riverpod
Future<int?> comicReadingPageIndexForReader(Ref ref, String comicId) async {
  if (comicId.isEmpty) {
    return null;
  }
  final history = await ref
      .read(readingHistoryRepoProvider)
      .getByComicId(comicId);
  return history?.pageIndex;
}

Future<List<ReaderComicListItem>> _buildSeriesNavItems(
  Ref ref,
  Series series,
) async {
  final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  final List<ReaderComicListItem> items = <ReaderComicListItem>[];
  for (int index = 0; index < sortedItems.length; index++) {
    final SeriesItem item = sortedItems[index];
    final String title = await resolveComicTitleForDisplay(
      ref.read(comicRepoProvider),
      item.comicId,
    );
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

@riverpod
Future<ReadSessionContextData> readSessionContextForReader(
  Ref ref, {
  required String comicId,
  String? seriesId,
  bool incognito = false,
}) async {
  final String normalizedComicId = comicId.trim();
  final String? normalizedSeriesId = seriesId?.trim();
  Series? series;
  if (normalizedSeriesId != null && normalizedSeriesId.isNotEmpty) {
    series = await ref
        .read(librarySeriesRepoProvider)
        .findById(normalizedSeriesId);
  }

  if (series == null) {
    final comic = await ref.read(comicRepoProvider).findById(normalizedComicId);
    final String fallbackTitle = comicTitleFallbackForDisplay(
      normalizedComicId,
    );
    final String title = comic?.title ?? fallbackTitle;
    final int? preferredPageIndex = incognito
        ? null
        : await ref.watch(
            comicReadingPageIndexForReaderProvider(normalizedComicId).future,
          );
    return ReadSessionContextData(
      mode: ReadSessionMode.standalone,
      seriesId: null,
      navContext: buildReaderNavContextData(
        items: <ReaderComicListItem>[
          ReaderComicListItem(
            comicId: normalizedComicId,
            title: title,
            order: 0,
          ),
        ],
        currentComicId: normalizedComicId,
        preferredPageIndex: preferredPageIndex,
      ),
      preferredPageIndex: preferredPageIndex,
    );
  }

  final List<ReaderComicListItem> items = await _buildSeriesNavItems(
    ref,
    series,
  );
  final int? preferredPageIndex = incognito
      ? null
      : await ref.watch(
          comicReadingPageIndexForReaderProvider(normalizedComicId).future,
        );
  return ReadSessionContextData(
    mode: ReadSessionMode.series,
    seriesId: series.id,
    navContext: buildReaderNavContextData(
      items: items,
      currentComicId: normalizedComicId,
      preferredPageIndex: preferredPageIndex,
    ),
    preferredPageIndex: preferredPageIndex,
  );
}

/// 从系列详情发起 Series read 时，解析应打开的 Comic。
@riverpod
Future<String> resolveSeriesReadComicId(
  Ref ref, {
  required String seriesId,
}) async {
  final Series? series = await ref
      .read(librarySeriesRepoProvider)
      .findById(seriesId);
  if (series == null || series.items.isEmpty) {
    return '';
  }
  final SeriesReadingHistory? history = await ref
      .read(seriesReadingHistoryRepoProvider)
      .getBySeriesId(seriesId);
  if (history != null && series.containsComic(history.lastReadComicId)) {
    return history.lastReadComicId;
  }
  final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  return sortedItems.first.comicId;
}

/// 漫画详情页发起 Series read 时，解析 seriesId（仅当漫画唯一属于一个系列）。
@riverpod
Future<String?> resolveSeriesIdForComicRead(
  Ref ref, {
  required String comicId,
}) async {
  final ComicDetailSeriesNavResult result = await ref.watch(
    comicDetailSeriesNavProvider(comicId).future,
  );
  if (result is ComicDetailSeriesNavReady) {
    return result.data.seriesId;
  }
  return null;
}
