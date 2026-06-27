import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';

/// 用户编辑覆盖解析值（含 [ComicMetadataForm] → 持久化字段转换）。
class UpdateComicMetaUseCase {
  UpdateComicMetaUseCase(this._repo);

  final ComicRepository _repo;

  Future<void> call(String comicId, ComicMetadataForm form) {
    return _repo.updateUserMeta(
      comicId,
      title: form.title,
      authors: form.authors,
      contentRating: form.isR18 ? ContentRating.r18 : ContentRating.safe,
      tags: form.tags,
    );
  }
}
