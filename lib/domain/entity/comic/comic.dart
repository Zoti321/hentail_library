import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/util/enums.dart';

part 'comic.freezed.dart';

@freezed
abstract class Comic with _$Comic {
  factory Comic({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required String title,
    @Default(<String>[]) List<String> authors,
    @Default(ContentRating.unknown) ContentRating contentRating,
    @Default(<Tag>[]) List<Tag> tags,
    int? pageCount,
  }) = _Comic;

  Comic._();
}
