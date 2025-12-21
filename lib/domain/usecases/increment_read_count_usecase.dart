import 'package:hentai_library/domain/repository/comic_repo.dart';

/// 用例：增加漫画的阅读次数。
class IncrementReadCountUseCase {
  final ComicRepository _comicRepository;

  IncrementReadCountUseCase(this._comicRepository);

  Future<void> call(String comicId) async {
    await _comicRepository.incrementReadCount(comicId);
  }
}
