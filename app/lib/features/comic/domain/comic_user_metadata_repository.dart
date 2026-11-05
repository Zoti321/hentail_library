import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// Comic 用户元数据写入与 Metadata field lock。
abstract class ComicUserMetadataRepository {
  /// 用户编辑覆盖解析值：仅传入的字段会写入并加锁；`null` 表示省略。
  /// 清空发布日时传 [clearPublishedAt]（勿与 [publishedAt] 同传）。
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
  });

  /// 按字段设置元数据锁（不改值）；`null` 表示该字段不变。
  Future<void> setMetaLocks(
    String comicId, {
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  });
}
