import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/library.dart' as rust;
import 'package:hentai_library/src/rust/api/sync.dart' as rust_sync;

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl();

  @override
  Future<List<LocalLibrary>> list() async {
    return guardFrbSync(
      () => rust.listLibrariesFrb().map(_mapLibrary).toList(growable: false),
      fallbackMessage: '读取本地库列表失败',
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
  Future<void> delete(String libraryId) async {
    guardFrbSync(
      () => rust.deleteLibraryFrb(libraryId: libraryId),
      fallbackMessage: '删除本地库失败',
    );
  }

  @override
  Future<String?> getCurrentId() async {
    return guardFrbSync(
      rust.getCurrentLibraryIdFrb,
      fallbackMessage: '读取当前本地库失败',
    );
  }

  @override
  Future<void> setCurrentId(String? libraryId) async {
    guardFrbSync(
      () => rust.setCurrentLibraryIdFrb(libraryId: libraryId),
      fallbackMessage: '设置当前本地库失败',
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
      fallbackMessage: '更新本地库格式失败',
    );
  }
}

LocalLibrary _mapLibrary(rust.LibraryDto dto) {
  return (
    libraryId: dto.libraryId,
    rootPath: dto.rootPath,
    name: dto.name,
    enabledFormatGroups: dto.enabledFormatGroups
        .map(_mapFormatGroupFromRust)
        .toList(growable: false),
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
