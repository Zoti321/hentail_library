import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';

part 'comic_metadata_form.freezed.dart';

@freezed
abstract class ComicMetadataForm with _$ComicMetadataForm {
  factory ComicMetadataForm({
    required String title,
    @Default(false) bool isR18,
    @Default([]) List<Tag> tags,
    @Default([]) List<String> authors,
  }) = _ComicMetadataForm;
}
