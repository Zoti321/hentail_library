import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/src/rust/api/path.dart' as rust;

class PathRepositoryImpl implements PathRepository {
  const PathRepositoryImpl();

  @override
  Future<List<String>> getAll() async => rust.listAllPathsFrb();

  @override
  Stream<List<String>> watch() => rust.watchPathsFrb();

  @override
  Future<void> add(String path) async {
    try {
      rust.addPathFrb(rawPath: path);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 添加路径失败，path=$path');
      throw AppException('添加路径失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      rust.removePathFrb(rawPath: path);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 移除路径失败，path=$path');
      throw AppException('移除路径失败', cause: e, stackTrace: st);
    }
  }
}
