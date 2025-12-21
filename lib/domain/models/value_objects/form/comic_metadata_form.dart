import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';

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

extension ComicMetadataFormPersistence on ComicMetadataForm {
  Future<void> applyTo(ComicRepository repository, String comicId) {
    return repository.updateUserMeta(
      comicId,
      title: title,
      authors: authors,
      contentRating: isR18 ? ContentRating.r18 : ContentRating.safe,
      tags: tags,
    );
  }
}
