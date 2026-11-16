/// Comic 元数据实体公共面（ADR-0048）。
///
/// `Author` / `AuthorDetail` / `Tag` 真源在 `comic_metadata/domain/`；
/// 跨模块只经此 thin re-export 读取，不复制 DTO。
library;

export 'package:hentai_library/features/comic_metadata/domain/author.dart';
export 'package:hentai_library/features/comic_metadata/domain/author_detail.dart';
export 'package:hentai_library/features/comic_metadata/domain/tag.dart';
