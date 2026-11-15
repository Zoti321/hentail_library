import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/features/comic/domain/value_objects/content_rating.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

part 'comic_metadata.freezed.dart';

const _unchanged = Object();

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ComicMetadata with _$ComicMetadata {
  const ComicMetadata._();

  ComicMetadata copyWith({
    String? title,
    List<AuthorRef>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
    Object? description = _unchanged,
    Object? publishedAt = _unchanged,
    ComicMetaLocks? locks,
  }) => ComicMetadata(
    title: title ?? this.title,
    authors: authors ?? this.authors,
    contentRating: contentRating ?? this.contentRating,
    tags: tags ?? this.tags,
    languages: languages ?? this.languages,
    parodies: parodies ?? this.parodies,
    characters: characters ?? this.characters,
    description: identical(description, _unchanged)
        ? this.description
        : description as String?,
    publishedAt: identical(publishedAt, _unchanged)
        ? this.publishedAt
        : publishedAt as DateTime?,
    locks: locks ?? this.locks,
  );

  factory ComicMetadata({
    required String title,
    List<AuthorRef> authors = const <AuthorRef>[],
    ContentRating contentRating = ContentRating.unknown,
    List<Tag> tags = const <Tag>[],
    List<String> languages = const <String>[],
    List<String> parodies = const <String>[],
    List<String> characters = const <String>[],
    String? description,
    DateTime? publishedAt,
    ComicMetaLocks locks = ComicMetaLocks.unlocked,
  }) => ComicMetadata._values(
    title: title,
    authors: List<AuthorRef>.unmodifiable(authors),
    contentRating: contentRating,
    tags: List<Tag>.unmodifiable(tags),
    languages: List<String>.unmodifiable(languages),
    parodies: List<String>.unmodifiable(parodies),
    characters: List<String>.unmodifiable(characters),
    description: description,
    publishedAt: publishedAt,
    locks: locks,
  );

  const factory ComicMetadata._values({
    required String title,
    required List<AuthorRef> authors,
    required ContentRating contentRating,
    required List<Tag> tags,
    required List<String> languages,
    required List<String> parodies,
    required List<String> characters,
    String? description,
    DateTime? publishedAt,
    required ComicMetaLocks locks,
  }) = _ComicMetadata;
}
