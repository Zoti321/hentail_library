import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/data/database/database.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';

class PathRepositoryImpl implements PathRepository {
  PathRepositoryImpl(this._savedPathDao);

  final SavedPathDao _savedPathDao;

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
