/// Library browse routes (Komga-like `/libraries/...`).
abstract final class LibrariesRoutes {
  static const String root = '/libraries';
  static const String all = '/libraries/all';
  static const String allSegment = 'all';

  static String library(String libraryId) => '$root/$libraryId';

  static String get defaultBrowse => all;

  /// Redirect target for legacy `/local` and bare `/libraries`.
  static String? redirectPath({required String locationPath}) {
    if (locationPath == '/local') {
      return all;
    }
    if (locationPath == root) {
      return all;
    }
    return null;
  }

  static bool isAllLibrariesPath(String path) => path == all;

  static bool isLibraryBrowsePath(String path) {
    return libraryIdFromPath(path) != null;
  }

  static String? libraryIdFromPath(String path) {
    if (!path.startsWith('$root/')) {
      return null;
    }
    final String id = path.substring(root.length + 1);
    if (id.isEmpty || id.contains('/') || id == allSegment) {
      return null;
    }
    return id;
  }
}

/// Sidebar selection derived from location only.
typedef LibrariesSidebarSelection = ({
  bool sectionActive,
  String? activeLibraryId,
});

/// Collapsed rail icon is active for All libraries or a specific library context.
bool librariesRailIconActive(LibrariesSidebarSelection selection) {
  return selection.sectionActive || selection.activeLibraryId != null;
}

LibrariesSidebarSelection librariesSidebarSelection({required String path}) {
  if (LibrariesRoutes.isAllLibrariesPath(path)) {
    return (sectionActive: true, activeLibraryId: null);
  }
  final String? pathLibraryId = LibrariesRoutes.libraryIdFromPath(path);
  if (pathLibraryId != null) {
    return (sectionActive: false, activeLibraryId: pathLibraryId);
  }
  return (sectionActive: false, activeLibraryId: null);
}

/// 二级库列表高亮：仅当路由为 `/libraries/:id` 时返回该 id，否则为空。
String librariesSidebarSelectedLibraryId({required String path}) {
  final String? activeId = librariesSidebarSelection(path: path)
      .activeLibraryId;
  if (activeId != null && activeId.isNotEmpty) {
    return activeId;
  }
  return '';
}

typedef AfterLibraryDeleteNavigation = ({String goPath});

AfterLibraryDeleteNavigation afterLibraryDeleteNavigation({
  required List<String> remainingLibraryIds,
}) {
  if (remainingLibraryIds.isEmpty) {
    return (goPath: LibrariesRoutes.all);
  }
  return (goPath: LibrariesRoutes.library(remainingLibraryIds.first));
}
