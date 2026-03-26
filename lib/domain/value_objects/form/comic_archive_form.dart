import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_archive_form.freezed.dart';

@freezed
abstract class ComicArchiveForm with _$ComicArchiveForm {
  factory ComicArchiveForm({
    required String comicId,
    required List<String> chapterIds,
  }) = _ComicArchiveForm;
}
