import 'package:hentai_library/shared/domain/library/library_change.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/repositories/comic_repository.dart';

/// 落库 Comic 用户元数据。
///
/// 成功后向 [publish] 发布一次 [LibraryChange]：字典字段写入与元数据保存事件
/// 由各订阅方（named_metadata 字典、metadata_backup 调度等）自行响应（#268）。
/// [notifyExternalChange] 仍用于刷新库页 catalog 与搜索 vocabulary 等依赖 libraryRevision 的监听方。
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
