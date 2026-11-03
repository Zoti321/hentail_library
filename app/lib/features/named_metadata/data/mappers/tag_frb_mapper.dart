import 'package:hentai_library/features/named_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/src/rust/api/tag.dart' as rust_tag;

TagDictionaryImportResult mapTagDictionaryImportResult(
  rust_tag.TagDictionaryImportResultDto dto,
) {
  return TagDictionaryImportResult(
    added: dto.added,
    skippedExisting: dto.skippedExisting,
    skippedFilteredOrEmptyOrDedupe: dto.skippedFilteredOrEmptyOrDedupe,
  );
}
