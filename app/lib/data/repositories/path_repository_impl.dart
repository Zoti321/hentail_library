import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/repositories/flutter_secure_remote_library_credential_store.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/domain/repositories/remote_library_credential_store.dart';
import 'package:hentai_library/src/rust/api/library.dart' as rust_library;
import 'package:hentai_library/src/rust/api/path.dart' as rust;

class PathRepositoryImpl implements PathRepository {
  const PathRepositoryImpl({RemoteLibraryCredentialStore? credentials})
    : _credentials =
          credentials ?? const FlutterSecureRemoteLibraryCredentialStore();

  final RemoteLibraryCredentialStore _credentials;

  @override
  Future<List<String>> getAll() async =>
      guardFrbSync(rust.listAllPathsFrb, fallbackMessage: '读取路径列表失败');

  @override
  Stream<List<String>> watch() =>
      guardFrbStream(rust.watchPathsFrb, fallbackMessage: '监听路径列表失败');

  @override
  Future<void> add(String path) async {
    try {
      guardFrbSync(
        () => rust.addPathFrb(rawPath: path),
        fallbackMessage: '添加路径失败',
      );
    } catch (e, st) {
      logError(AppLog.dataRepo('path'), '添加路径失败，path=$path', e, st);
      if (e is AppException) {
        rethrow;
      }
      throw AppException('添加路径失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      final String? libraryId = guardFrbSync(() {
        for (final rust_library.LibraryDto lib
            in rust_library.listLibrariesFrb()) {
          if (lib.rootPath == path) {
            return lib.libraryId;
          }
        }
        return null;
      }, fallbackMessage: '查找库失败');
      guardFrbSync(
        () => rust.removePathFrb(rawPath: path),
        fallbackMessage: '移除路径失败',
      );
      if (libraryId != null) {
        await _credentials.deletePassword(libraryId);
      }
    } catch (e, st) {
      logError(AppLog.dataRepo('path'), '移除路径失败，path=$path', e, st);
      if (e is AppException) {
        rethrow;
      }
      throw AppException('移除路径失败', cause: e, stackTrace: st);
    }
  }
}
