import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/entities.dart';

part 'comic_metadata_form.freezed.dart';

@freezed
abstract class ComicMetadataForm with _$ComicMetadataForm {
  factory ComicMetadataForm({
    required String title,
    DateTime? firstPublishedAt,
    @Default(false) bool isR18,
    String? description,
    @Default([]) List<CategoryTag> tags,
  }) = _ComicMetadataForm;
}
