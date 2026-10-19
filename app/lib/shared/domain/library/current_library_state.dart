import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';

/// 当前库列表与选中项的共享只读状态（#261a 自 library_admin 迁入 shared/domain）。
class CurrentLibraryState {
  const CurrentLibraryState({required this.libraries, required this.currentId});

  final List<LocalLibrary> libraries;
  final String? currentId;

  LocalLibrary? get current {
    final String? id = currentId;
    if (id == null) {
      return null;
    }
    for (final LocalLibrary library in libraries) {
      if (library.libraryId == id) {
        return library;
      }
    }
    return null;
  }

  LocalLibrary? findByRootPath(String rootPath) {
    for (final LocalLibrary library in libraries) {
      if (library.rootPath == rootPath) {
        return library;
      }
    }
    return null;
  }

  CurrentLibraryState copyWith({
    List<LocalLibrary>? libraries,
    String? currentId,
    bool clearCurrentId = false,
  }) {
    return CurrentLibraryState(
      libraries: libraries ?? this.libraries,
      currentId: clearCurrentId ? null : (currentId ?? this.currentId),
    );
  }
}
