import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:hentai_library/features/reader/application/prepare_reader_context_use_case.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/presentation/providers/series_reading_context_providers.dart';
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
  return ref.read(readResumePageQueryProvider)(comicId);
}

@riverpod
Future<ReadSessionContextData> readSessionContextForReader(
  Ref ref, {
  required String comicId,
  bool incognito = false,
  bool startFromFirstPage = false,
}) async {
  final prepared =
      await PrepareReaderContextUseCase(
        seriesContext: ref.read(findSeriesReadingContextQueryProvider),
        comics: ref.read(comicReadQueryProvider),
        resumePage: (id) =>
            ref.watch(comicReadingPageIndexForReaderProvider(id).future),
      )(
        comicId: comicId,
        incognito: incognito,
        startFromFirstPage: startFromFirstPage,
      );
  return ReadSessionContextData(
    seriesId: prepared.seriesId,
    navContext: buildReaderNavContextData(
      items: [
        for (final item in prepared.items)
          ReaderComicListItem(
            comicId: item.comicId,
            title: item.title,
            order: item.order,
          ),
      ],
      currentComicId: comicId.trim(),
      preferredPageIndex: prepared.preferredPageIndex,
    ),
    preferredPageIndex: prepared.preferredPageIndex,
  );
}
