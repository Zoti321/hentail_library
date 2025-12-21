import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';

class DirectoryRepositoryImpl implements DirectoryRepository {
  final SelectedDirectoryDao _selectedDirectoryDao;

  DirectoryRepositoryImpl(this._selectedDirectoryDao);

  @override
  Future<List<String>> getAllDirs() async {
    final queryset = await _selectedDirectoryDao.getAllSelectedDirectories();
    return queryset.map((e) => e.rawPath).toList();
  }

  @override
  Stream<List<String>> getDirsStream() {
    return _selectedDirectoryDao.watchAllSelectedDirectories().map(
      (e) => e.map((e) => e.rawPath).toList(),
    );
  }

  @override
  Future<void> addDir(String path) async {
    try {
      final dir = SelectedDirectoriesCompanion.insert(rawPath: path);
      await _selectedDirectoryDao.insertSelectedDirectory(dir);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[DIR_REPO] 添加目录失败，path=$path',
      );
      throw AppException('添加目录失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> removeDir(String path) async {
    try {
      await _selectedDirectoryDao.deleteSelectedDirectory(path);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[DIR_REPO] 移除目录失败，path=$path',
      );
      throw AppException('移除目录失败', cause: e, stackTrace: st);
    }
  }
}
