import 'package:hentai_library/domain/entity/v2/content_rating.dart';
import 'package:hentai_library/domain/entity/v2/library_comic.dart';
import 'package:hentai_library/domain/entity/v2/library_tag.dart';

/// v2 Comic 仓储：仅定义领域契约，不暴露数据层细节。
abstract class LibraryComicRepository {
  Stream<List<LibraryComic>> watchAll();

  Future<List<LibraryComic>> getAll();

  Future<LibraryComic?> findById(String comicId);

  /// 用于扫描导入（写入/更新）。
  Future<void> upsertMany(List<LibraryComic> comics);

  Future<void> deleteByIds(List<String> comicIds);

  /// 用户编辑覆盖解析值：title/authors/contentRating/tags 等。
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<String>? authors,
    ContentRating? contentRating,
    List<LibraryTag>? tags,
  });

  /// 可选：封装 diff+写入（后续数据层实现）。
  Future<void> replaceByScan(List<LibraryComic> scanned);
}

