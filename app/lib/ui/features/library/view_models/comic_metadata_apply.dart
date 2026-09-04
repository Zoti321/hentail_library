import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/ui/core/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
import 'package:riverpod/misc.dart' show ProviderOrFamily;

/// 按 [ComicMetadataApplySucceeded] 中实际写入的字典字段，使对应列表缓存失效。
void refreshComicMetadataDictionaries(
  void Function(ProviderOrFamily provider) invalidate,
  ComicMetadataApplySucceeded result,
) {
  if (result.tagsWritten) {
    invalidate(allTagsProvider);
    invalidate(tagsForComicMetadataFormProvider);
  }
  if (result.parodiesWritten) {
    invalidate(allParodiesProvider);
    invalidate(parodiesForComicMetadataFormProvider);
    invalidate(libraryDistinctParodiesProvider);
  }
  if (result.charactersWritten) {
    invalidate(allCharactersProvider);
    invalidate(charactersForComicMetadataFormProvider);
    invalidate(libraryDistinctCharactersProvider);
  }
}

/// 落库 Comic 用户元数据，并在字典字段有写入时刷新相关列表缓存。
Future<ComicMetadataApplyResult> applyComicMetadataForm(
  ComicRepository repository,
  ComicMetadataForm form,
  Comic original, {
  required void Function(ProviderOrFamily provider) invalidate,
}) async {
  final ComicMetadataApplyResult result = await form.applyTo(
    repository,
    original,
  );
  if (result is ComicMetadataApplySucceeded) {
    refreshComicMetadataDictionaries(invalidate, result);
  }
  return result;
}
