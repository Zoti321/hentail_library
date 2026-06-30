import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';

/// 阅读会话页面加载（领域编排：区分无页与加载失败）。
class ReadSessionLoader {
  const ReadSessionLoader({required ComicPageSourcePort pageSource})
    : _pageSource = pageSource;

  final ComicPageSourcePort _pageSource;

  Future<List<ReadSessionPage>> loadPages(Comic comic) async {
    try {
      final List<ReadSessionPage> pages = await _pageSource.loadPages(comic);
      if (pages.isEmpty) {
        throw ReadSessionPageLoadException.emptyPages(
          comicId: comic.comicId,
          path: comic.path,
        );
      }
      return List<ReadSessionPage>.unmodifiable(pages);
    } on ReadSessionPageLoadException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw ReadSessionPageLoadException.loadFailed(
        comicId: comic.comicId,
        path: comic.path,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
