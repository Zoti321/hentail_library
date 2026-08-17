import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';

/// Library 轻量快照（FRB LibraryDto → domain）。含 Local 与 Remote。
typedef LocalLibrary = ({
  String libraryId,

  /// `local` | `remote`
  String kind,
  String rootPath,
  String name,
  List<FormatGroup> enabledFormatGroups,

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
