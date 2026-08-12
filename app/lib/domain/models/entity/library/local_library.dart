import 'package:hentai_library/domain/library/format_group.dart';

/// 本地库轻量快照（FRB LibraryDto → domain）。
typedef LocalLibrary = ({
  String libraryId,
  String rootPath,
  String name,
  List<FormatGroup> enabledFormatGroups,
});

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
