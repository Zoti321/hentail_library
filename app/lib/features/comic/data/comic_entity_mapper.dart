import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

/// FRB `ComicDto` → shared [Comic]（Catalog kernel，ADR-0035）。
Comic mapRustComic(rust.ComicDto dto) {
  return Comic(
    comicId: dto.comicId,
    path: dto.path,
    resourceType: ResourceType.values.byName(dto.resourceType),
    resourceSize: dto.resourceSize.toInt(),
    createdAt: comicTimestampFromMs(dto.createdAt.toInt()),
    lastUpdatedAt: comicTimestampFromMs(dto.lastUpdatedAt.toInt()),
    title: dto.title,
    authors: dto.authors
        .map(
          (rust.ComicAuthorDto a) => AuthorRef(id: a.id?.toInt(), name: a.name),
        )
        .toList(),
    contentRating: ContentRating.values.byName(dto.contentRating),
    tags: dto.tags.map((String n) => Tag(name: n)).toList(),
    languages: List<String>.from(dto.languages),
    parodies: List<String>.from(dto.parodies),
    characters: List<String>.from(dto.characters),
    pageCount: dto.pageCount,
    description: dto.description,
    publishedAt: dto.publishedAt == null
        ? null
        : comicTimestampFromMs(dto.publishedAt!.toInt()),
    lastReadTime: dto.lastReadTimeMs == null
        ? null
        : comicTimestampFromMs(dto.lastReadTimeMs!.toInt()),
    locks: ComicMetaLocks(
      title: dto.locks.title,
      description: dto.locks.description,
      publishedAt: dto.locks.publishedAt,
      contentRating: dto.locks.contentRating,
      authors: dto.locks.authors,
      tags: dto.locks.tags,
      languages: dto.locks.languages,
      parodies: dto.locks.parodies,
      characters: dto.locks.characters,
    ),
  );
}
