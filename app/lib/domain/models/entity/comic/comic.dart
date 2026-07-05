import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';

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
    required int pageCount,
    String? description,
    DateTime? publishedAt,
  }) = _Comic;

  Comic._();
}

DateTime comicTimestampFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int comicTimestampToMs(DateTime dateTime) => dateTime.toUtc().millisecondsSinceEpoch;
