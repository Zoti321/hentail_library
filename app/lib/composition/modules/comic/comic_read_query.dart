import 'package:hentai_library/features/comic/domain/comic_display_title.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';

/// [ComicReadQuery] 的 comic 侧实现（bootstrap 注入，reader 只读 shared 面）。
ComicReadQuery createComicReadQuery(ComicLookupRepository repo) =>
    _RepositoryComicReadQuery(repo);

class _RepositoryComicReadQuery implements ComicReadQuery {
  _RepositoryComicReadQuery(this._repo);

  final ComicLookupRepository _repo;

  @override
  Future<ComicReadSnapshot?> findById(String comicId) async {
    final comic = await _repo.findById(comicId);
    if (comic == null) {
      return null;
    }
    return ComicReadSnapshot(
      comicId: comic.comicId,
      path: comic.path,
      resourceType: comic.resourceType,
      pageCount: comic.pageCount,
      title: comic.title,
    );
  }

  @override
  Future<String> displayTitleById(String comicId) async {
    final comic = await _repo.findById(comicId);
    return comic?.title ?? comicTitleFallbackForDisplay(comicId);
  }

  @override
  Future<Map<String, String>> displayTitlesByIds(List<String> comicIds) =>
      resolveComicTitlesForDisplay(_repo, comicIds);
}
