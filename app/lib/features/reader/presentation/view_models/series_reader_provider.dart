import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/shared/di/data_providers.dart';

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
  return ref
      .read(readingHistoryCommandPortProvider)
      .readResumePageIndex(comicId);
}

Future<List<ReaderComicListItem>> _buildNavItemsFromContext(
  Ref ref,
  SeriesReadingContext context,
) async {
  final List<String> orderedIds = context.orderedComicIds;
  final Map<String, String> titlesById = await ref
      .read(comicReadLookupPortProvider)
      .displayTitlesByIds(orderedIds);
  return <ReaderComicListItem>[
    for (int index = 0; index < orderedIds.length; index++)
      ReaderComicListItem(
        comicId: orderedIds[index],
        title: titlesById[orderedIds[index]]!,
        order: index,
      ),
  ];
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
      .read(seriesReadingContextPortProvider)
      .getReadingContextByComicId(normalizedComicId);

  final int? preferredPageIndex = (incognito || startFromFirstPage)
      ? null
      : await ref.watch(
          comicReadingPageIndexForReaderProvider(normalizedComicId).future,
        );

  if (seriesContext == null) {
    final String title = await ref
        .read(comicReadLookupPortProvider)
        .displayTitleById(normalizedComicId);
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
