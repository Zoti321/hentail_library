import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/src/rust/api/path.dart' as rust;

class PathRepositoryImpl implements PathRepository {
  const PathRepositoryImpl();

  @override
  Future<List<String>> getAll() async => guardFrbSync(
    rust.listAllPathsFrb,
    fallbackMessage: '读取路径列表失败',
  );

  @override
  Stream<List<String>> watch() => guardFrbStream(
    rust.watchPathsFrb,
    fallbackMessage: '监听路径列表失败',
  );

  @override
  Future<void> add(String path) async {
    try {
      guardFrbSync(
        () => rust.addPathFrb(rawPath: path),
        fallbackMessage: '添加路径失败',
      );
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 添加路径失败，path=$path');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('添加路径失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      guardFrbSync(
        () => rust.removePathFrb(rawPath: path),
        fallbackMessage: '移除路径失败',
      );
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[PATH_REPO] 移除路径失败，path=$path');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('移除路径失败', cause: e, stackTrace: st);
    }
  }
}
