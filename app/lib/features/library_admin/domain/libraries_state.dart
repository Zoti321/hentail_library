import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';

/// 已注册 Library 列表的共享只读状态。
class LibrariesState {
  const LibrariesState({required this.libraries});

  final List<LocalLibrary> libraries;

  LocalLibrary? findByRootPath(String rootPath) {
    for (final LocalLibrary library in libraries) {
      if (library.rootPath == rootPath) {
        return library;
      }
    }
    return null;
  }

  LocalLibrary? findById(String libraryId) {
    for (final LocalLibrary library in libraries) {
      if (library.libraryId == libraryId) {
        return library;
      }
    }
    return null;
  }

  LibrariesState copyWith({List<LocalLibrary>? libraries}) {
    return LibrariesState(libraries: libraries ?? this.libraries);
  }
}
