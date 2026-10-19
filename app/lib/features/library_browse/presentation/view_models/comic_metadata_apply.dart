import 'package:hentai_library/shared/domain/library/library_change.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/repositories/comic_repository.dart';

///
Future<ComicMetadataApplyResult> applyComicMetadataForm(
  ComicRepository repository,
  ComicMetadataForm form,
  Comic original, {
  required void Function() notifyExternalChange,
  required void Function(LibraryChange change) publish,
}) async {
  final ComicMetadataApplyResult result = await form.applyTo(
    repository,
    original,
  );
  if (result is ComicMetadataApplySucceeded) {
    publish(
      LibraryChange(
        tagsWritten: result.tagsWritten,
        parodiesWritten: result.parodiesWritten,
        charactersWritten: result.charactersWritten,
        metadataSaved: result.persisted,
      ),
    );
    if (result.persisted) {
      notifyExternalChange();
    }
  }
  return result;
}
