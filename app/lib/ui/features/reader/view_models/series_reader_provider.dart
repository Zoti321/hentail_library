import 'package:hentai_library/domain/reading/series_reading_context.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reader_provider.g.dart';

class ReadSessionContextData {
  const ReadSessionContextData({
    required this.seriesId,
    required this.navContext,
    required this.preferredPageIndex,
  });

  final String? seriesId;
  final ReaderNavContextData navContext;
  final int? preferredPageIndex;

  bool get hasSeriesContext => seriesId != null && seriesId!.isNotEmpty;
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

Future<List<ReaderComicListItem>> _buildNavItemsFromContext(
  Ref ref,
  SeriesReadingContext context,
) async {
  final List<ReaderComicListItem> items = <ReaderComicListItem>[];
  for (int index = 0; index < context.orderedComicIds.length; index++) {
    final String memberId = context.orderedComicIds[index];
    final String title = await resolveComicTitleForDisplay(
      ref.read(comicRepoProvider),
      memberId,
    );
    items.add(
      ReaderComicListItem(comicId: memberId, title: title, order: index),
    );
  }
  return items;
}

@riverpod
Future<ReadSessionContextData> readSessionContextForReader(
  Ref ref, {
  required String comicId,
  bool incognito = false,
  bool startFromFirstPage = false,
}) async {
  final String normalizedComicId = comicId.trim();
  final SeriesReadingContext? seriesContext = await ref
      .read(seriesRepoProvider)
      .getReadingContextByComicId(normalizedComicId);

  final int? preferredPageIndex = (incognito || startFromFirstPage)
      ? null
      : await ref.watch(
          comicReadingPageIndexForReaderProvider(normalizedComicId).future,
        );

  if (seriesContext == null) {
    final comic = await ref.read(comicRepoProvider).findById(normalizedComicId);
    final String fallbackTitle = comicTitleFallbackForDisplay(
      normalizedComicId,
    );
    final String title = comic?.title ?? fallbackTitle;
    return ReadSessionContextData(
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

  final List<ReaderComicListItem> items = await _buildNavItemsFromContext(
    ref,
    seriesContext,
  );
  return ReadSessionContextData(
    seriesId: seriesContext.seriesId,
    navContext: buildReaderNavContextData(
      items: items,
      currentComicId: normalizedComicId,
      preferredPageIndex: preferredPageIndex,
    ),
    preferredPageIndex: preferredPageIndex,
  );
}
