import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';

class PathRepositoryImpl implements PathRepository {
  final SavedPathDao _savedPathDao;

  PathRepositoryImpl(this._savedPathDao);

  @override
  Future<List<String>> getAllPaths() async {
    final queryset = await _savedPathDao.getAllSavedPaths();
    return queryset.map((e) => e.rawPath).toList();
  }

  @override
  Stream<List<String>> getPathsStream() {
    return _savedPathDao.watchAllSavedPaths().map(
      (e) => e.map((e) => e.rawPath).toList(),
    );
  }

  @override
  Future<void> addPath(String path) async {
    try {
      final row = SavedPathsCompanion.insert(rawPath: path);
      await _savedPathDao.insertSavedPath(row);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 添加路径失败，path=$path');
      throw AppException('添加路径失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> removePath(String path) async {
    try {
      await _savedPathDao.deleteSavedPath(path);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 移除路径失败，path=$path');
      throw AppException('移除路径失败', cause: e, stackTrace: st);
    }
  }
}
