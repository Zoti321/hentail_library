import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';

/// 按 comicId 读取 Comic。目录查询与用户元数据写入不在此接口。
abstract class ComicLookupRepository {
  Future<Comic?> findById(String comicId);

  /// Batch load by comic ids. Returns only found comics, preserving request order.
  Future<List<Comic>> findByIds(List<String> comicIds);
}
