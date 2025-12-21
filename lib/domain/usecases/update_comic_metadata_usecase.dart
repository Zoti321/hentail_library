import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';

/// 用例：更新单本漫画的元数据与标签。
class UpdateComicMetadataUseCase {
  final ComicRepository _comicRepository;

  UpdateComicMetadataUseCase(this._comicRepository);

  Future<void> call(String comicId, ComicMetadataForm form) async {
    await _comicRepository.updateComicMetaData(comicId, form);
  }
}
