import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_tag.dart';
import 'package:hentai_library/domain/enums/enums.dart';

part 'library_comic.freezed.dart';

/// v2：以“资源”为最小阅读/管理单位的漫画实体（与当前旧 `Comic` 并存）。
///
/// 约定：
/// - `title/authors` 为单一字段：默认取解析器结果；用户编辑后覆盖解析值。
@freezed
abstract class LibraryComic with _$LibraryComic {
  factory LibraryComic({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required String title,
    @Default(<String>[]) List<String> authors,
    @Default(ContentRating.unknown) ContentRating contentRating,
    @Default(<LibraryTag>[]) List<LibraryTag> tags,
  }) = _LibraryComic;

  LibraryComic._();
}
