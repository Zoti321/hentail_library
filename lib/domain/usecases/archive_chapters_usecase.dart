import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';

/// 用例：将指定章节归档到目标漫画（合并后删除空壳漫画）。
class ArchiveChaptersUseCase {
  final ComicRepository _comicRepository;

  ArchiveChaptersUseCase(this._comicRepository);

  Future<void> call(ComicArchiveForm form) async {
    await _comicRepository.archiveChaptersToComic(form);
  }
}
