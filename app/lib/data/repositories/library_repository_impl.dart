import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/repositories/flutter_secure_remote_library_credential_store.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/domain/repositories/remote_library_credential_store.dart';
import 'package:hentai_library/src/rust/api/library.dart' as rust;
import 'package:hentai_library/src/rust/api/sync.dart' as rust_sync;

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl({
    RemoteLibraryCredentialStore? credentials,
  }) : _credentials =
           credentials ?? const FlutterSecureRemoteLibraryCredentialStore();

  final RemoteLibraryCredentialStore _credentials;

  @override
  Future<List<LocalLibrary>> list() async {
    return guardFrbSync(
      () => rust.listLibrariesFrb().map(_mapLibrary).toList(growable: false),
      fallbackMessage: '读取库列表失败',
    );
  }

  @override
  Future<LocalLibrary> createLocal(String rootPath) async {
    return guardFrbSync(
      () => _mapLibrary(rust.createLocalLibraryFrb(rootPath: rootPath)),
      fallbackMessage: '创建本地库失败',
    );
  }

  @override
  Future<LocalLibrary> createRemote({
    required String rootUrl,
    required String username,
    required String password,
    required bool allowHttp,
  }) async {
    final LocalLibrary library = guardFrbSync(
      () => _mapLibrary(
        rust.createRemoteLibraryFrb(
          rootUrl: rootUrl,
          username: username,
          allowHttp: allowHttp,
        ),
      ),
      fallbackMessage: '创建远程库失败',
    );
    try {
      await _credentials.savePassword(
        libraryId: library.libraryId,
        password: password,
      );
    } catch (e, st) {
      try {
        guardFrbSync(
          () => rust.deleteLibraryFrb(libraryId: library.libraryId),
          fallbackMessage: '回滚远程库失败',
        );
      } catch (_) {
        // Best-effort rollback; surface the credential failure.
      }
      Error.throwWithStackTrace(e, st);
    }
    return library;
  }

  @override
  Future<LocalLibrary> updateRemote({
    required String libraryId,
    required String rootUrl,
    required String username,
    required bool allowHttp,
    String? password,
  }) async {
    final LocalLibrary library = guardFrbSync(
      () => _mapLibrary(
        rust.updateRemoteLibraryFrb(
          libraryId: libraryId,
          rootUrl: rootUrl,
          username: username,
          allowHttp: allowHttp,
        ),
      ),
      fallbackMessage: '更新远程库失败',
    );
    if (password != null) {
      await _credentials.savePassword(
        libraryId: library.libraryId,
        password: password,
      );
    }
    return library;
  }

  @override
  Future<void> delete(String libraryId) async {
    try {
      guardFrbSync(
        () => rust.deleteLibraryFrb(libraryId: libraryId),
        fallbackMessage: '删除库失败',
      );
    } finally {
      await _credentials.deletePassword(libraryId);
    }
  }

  @override
  Future<String?> getCurrentId() async {
    return guardFrbSync(
      rust.getCurrentLibraryIdFrb,
      fallbackMessage: '读取当前库失败',
    );
  }

  @override
  Future<void> setCurrentId(String? libraryId) async {
    guardFrbSync(
      () => rust.setCurrentLibraryIdFrb(libraryId: libraryId),
      fallbackMessage: '设置当前库失败',
    );
  }

  @override
  Future<LocalLibrary> updateFormatGroups({
    required String libraryId,
    required List<FormatGroup> groups,
  }) async {
    return guardFrbSync(
      () => _mapLibrary(
        rust.updateLibraryFormatGroupsFrb(
          libraryId: libraryId,
          groups: groups.map(_mapFormatGroup).toList(growable: false),
        ),
      ),
      fallbackMessage: '更新库格式失败',
    );
  }

  @override
  Future<String?> readRemotePassword(String libraryId) {
    return _credentials.readPassword(libraryId);
  }
}

LocalLibrary _mapLibrary(rust.LibraryDto dto) {
  return (
    libraryId: dto.libraryId,
    kind: dto.kind,
    rootPath: dto.rootPath,
    name: dto.name,
    enabledFormatGroups: dto.enabledFormatGroups
        .map(_mapFormatGroupFromRust)
        .toList(growable: false),
    username: dto.username,
    allowHttp: dto.allowHttp,
  );
}

rust_sync.FormatGroupDto _mapFormatGroup(FormatGroup group) {
  return switch (group) {
    FormatGroup.folder => rust_sync.FormatGroupDto.folder,
    FormatGroup.pdf => rust_sync.FormatGroupDto.pdf,
    FormatGroup.epub => rust_sync.FormatGroupDto.epub,
    FormatGroup.archive => rust_sync.FormatGroupDto.archive,
  };
}

FormatGroup _mapFormatGroupFromRust(rust_sync.FormatGroupDto group) {
  return switch (group) {
    rust_sync.FormatGroupDto.folder => FormatGroup.folder,
    rust_sync.FormatGroupDto.pdf => FormatGroup.pdf,
    rust_sync.FormatGroupDto.epub => FormatGroup.epub,
    rust_sync.FormatGroupDto.archive => FormatGroup.archive,
  };
}
