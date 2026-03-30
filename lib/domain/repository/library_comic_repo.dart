import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/enums/enums.dart';

/// [replaceByScan] 应用结果统计（供 UI 进度等）。
typedef LibraryComicReplaceByScanResult = ({
  int removedCount,
  int addedCount,
  int keptCount,
});

/// v2 Comic 仓储：仅定义领域契约，不暴露数据层细节。
abstract class LibraryComicRepository {
  Stream<List<Comic>> watchAll();

  Future<List<Comic>> getAll();

  Future<Comic?> findById(String comicId);

  /// 用于扫描导入（写入/更新）。
  Future<void> upsertMany(List<Comic> comics);

  Future<void> deleteByIds(List<String> comicIds);

  /// 用户编辑覆盖解析值：title/authors/contentRating/tags 等。
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<String>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  });

  /// 扫描 diff：删除库中本次未出现的条目并清理关联；新增与保留条目写入（保留合并用户元数据）。
  Future<LibraryComicReplaceByScanResult> replaceByScan(List<Comic> scanned);
}
