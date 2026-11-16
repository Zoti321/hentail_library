import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';

/// Library 轻量快照（FRB LibraryDto → domain）。含 Local 与 Remote。
typedef LocalLibrary = ({
  String libraryId,

  /// `local` | `remote`
  String kind,

  /// `comic` | `image_set`；创建后不可变，与 [kind] 正交。
  String catalogKind,
  String rootPath,
  String name,
  List<ResourceFormatCategory> enabledResourceFormatCategories,

  /// Remote Basic 用户名；Local 为空。
  String username,

  /// Remote 显式允许 HTTP；Local 恒为 false。
  bool allowHttp,
  bool scanOnStartup,
  ScanInterval scanInterval,
  bool pinned,
  int sidebarOrder,
});

bool isRemoteLibrary(LocalLibrary library) => library.kind == 'remote';

bool isLocalLibrary(LocalLibrary library) => library.kind != 'remote';

bool isImageSetLibrary(LocalLibrary library) =>
    library.catalogKind == 'image_set';

bool isComicLibrary(LocalLibrary library) => !isImageSetLibrary(library);

String localLibraryDisplayName(LocalLibrary library) {
  final String trimmed = library.name.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  final String root = library.rootPath.replaceAll('\\', '/');
  final int slash = root.lastIndexOf('/');
  if (slash >= 0 && slash < root.length - 1) {
    return root.substring(slash + 1);
  }
  return root.isEmpty ? library.libraryId : root;
}
