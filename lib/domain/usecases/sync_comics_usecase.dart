import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';

/// 用例：从已选目录同步漫画资源到本地数据库。
/// 依赖领域仓储抽象，不依赖 data 层实现。
class SyncComicsUseCase {
  final ComicRepository _comicRepository;
  final DirectoryRepository _directoryRepository;

  SyncComicsUseCase(
    this._comicRepository,
    this._directoryRepository,
  );

  /// 获取已选目录列表并触发漫画资源同步。
  /// 返回 [SyncReport]；取消时报告带 cancelled: true，异常时抛出。
  Future<SyncReport?> call({
    bool Function()? isCancelled,
    void Function(SyncProgress)? onProgress,
  }) async {
    final dirs = await _directoryRepository.getAllDirs();
    return _comicRepository.ingestComicResources(
      dirs,
      isCancelled: isCancelled,
      onProgress: onProgress,
    );
  }
}
