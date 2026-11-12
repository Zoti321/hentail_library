import 'package:hentai_library/shared/domain/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/domain/contracts/find_series_reading_context_query.dart';

typedef PreparedReaderItem = ({String comicId, String title, int order});
typedef PreparedReaderContext = ({
  String? seriesId,
  List<PreparedReaderItem> items,
  int? preferredPageIndex,
});

/// 准备一次阅读入口的系列顺序、展示标题与恢复页快照。
class PrepareReaderContextUseCase {
  const PrepareReaderContextUseCase({
    required this.seriesContext,
    required this.comics,
    required this.resumePage,
  });
  final FindSeriesReadingContextQuery seriesContext;
  final ComicReadQuery comics;
  final Future<int?> Function(String comicId) resumePage;

  Future<PreparedReaderContext> call({
    required String comicId,
    bool incognito = false,
    bool startFromFirstPage = false,
  }) async {
    final id = comicId.trim();
    final context = await seriesContext(id);
    final preferred = incognito || startFromFirstPage
        ? null
        : await resumePage(id);
    if (context == null) {
      return (
        seriesId: null,
        items: [
          (comicId: id, title: await comics.displayTitleById(id), order: 0),
        ],
        preferredPageIndex: preferred,
      );
    }
    final ids = context.orderedComicIds;
    final titles = await comics.displayTitlesByIds(ids);
    return (
      seriesId: context.seriesId,
      items: [
        for (var i = 0; i < ids.length; i++)
          (comicId: ids[i], title: titles[ids[i]]!, order: i),
      ],
      preferredPageIndex: preferred,
    );
  }
}
