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
  ///
  /// 即使当前未配置任何「扫描目录」，也会调用同步逻辑，
  /// 由仓储/同步服务自行决定如何处理空目录列表（保持与旧行为一致）。
  Future<void> call({bool Function()? isCancelled}) async {
    final dirs = await _directoryRepository.getAllDirs();
    await _comicRepository.ingestComicResources(dirs, isCancelled: isCancelled);
  }
}
