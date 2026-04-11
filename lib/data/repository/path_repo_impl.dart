import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';

class PathRepositoryImpl implements PathRepository {
  final SavedPathDao _savedPathDao;

  PathRepositoryImpl(this._savedPathDao);

  @override
  Future<List<String>> getAll() async {
    final queryset = await _savedPathDao.getAll();
    return queryset.map((e) => e.rawPath).toList();
  }

  @override
  Stream<List<String>> watch() {
    return _savedPathDao.watchAll().map(
      (e) => e.map((e) => e.rawPath).toList(),
    );
  }

  @override
  Future<void> add(String path) async {
    try {
      final row = SavedPathsCompanion.insert(rawPath: path);
      await _savedPathDao.insert(row);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 添加路径失败，path=$path');
      throw AppException('添加路径失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      await _savedPathDao.deleteRow(path);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 移除路径失败，path=$path');
      throw AppException('移除路径失败', cause: e, stackTrace: st);
    }
  }
}
