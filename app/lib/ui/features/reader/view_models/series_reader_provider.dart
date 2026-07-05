import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
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

@riverpod
Future<ReaderSeriesContextData> readerSeriesContextForReader(
  Ref ref, {
  required String comicId,
  bool incognito = false,
}) async {
  final comic = await ref.read(comicRepoProvider).findById(comicId);
  final String fallbackTitle = comicId.length > 12
      ? '${comicId.substring(0, 12)}…'
      : comicId;
  final String title = comic?.title ?? fallbackTitle;
  final int? preferredPageIndex = incognito
      ? null
      : await ref.watch(
          comicReadingPageIndexForReaderProvider(comicId).future,
        );
  return ReaderSeriesContextData(
    navContext: buildReaderNavContextData(
      items: <ReaderComicListItem>[
        ReaderComicListItem(comicId: comicId, title: title, order: 0),
      ],
      currentComicId: comicId,
      preferredPageIndex: preferredPageIndex,
    ),
    preferredPageIndex: preferredPageIndex,
  );
}
