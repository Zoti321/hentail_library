import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/comic_meta_locks.dart';

part 'comic.freezed.dart';

@freezed
abstract class Comic with _$Comic {
  factory Comic({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int resourceSize,
    required DateTime createdAt,
    required DateTime lastUpdatedAt,
    required String title,

    @Default(<Author>[]) List<Author> authors,
    @Default(ContentRating.unknown) ContentRating contentRating,
    @Default(<Tag>[]) List<Tag> tags,
    /// Ordered canonical English Language names; empty = unset.
    @Default(<String>[]) List<String> languages,
    /// Parody (IP / franchise) names; empty = none.
    @Default(<String>[]) List<String> parodies,
    /// Character names; empty = none.
    @Default(<String>[]) List<String> characters,
    required int pageCount,
    String? description,
    DateTime? publishedAt,
    DateTime? lastReadTime,
    @Default(ComicMetaLocks.unlocked) ComicMetaLocks locks,
  }) = _Comic;

  Comic._();
}

DateTime comicTimestampFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int comicTimestampToMs(DateTime dateTime) =>
    dateTime.toUtc().millisecondsSinceEpoch;
