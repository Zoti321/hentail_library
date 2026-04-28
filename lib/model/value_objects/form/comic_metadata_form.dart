import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';

part 'comic_metadata_form.freezed.dart';

@freezed
abstract class ComicMetadataForm with _$ComicMetadataForm {
  factory ComicMetadataForm({
    required String title,
    @Default(false) bool isR18,
    @Default([]) List<Tag> tags,
    @Default([]) List<Author> authors,
  }) = _ComicMetadataForm;
}
