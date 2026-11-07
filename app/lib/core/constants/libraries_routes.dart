/// Library browse routes (Komga-like `/libraries/:id`).
abstract final class LibrariesRoutes {
  static const String root = '/libraries';

  /// Legacy aggregate-browse path; always redirect away (not a real Library).
  static const String legacyAll = '/libraries/all';
  static const String legacyAllSegment = 'all';

  static String library(String libraryId) => '$root/$libraryId';

  /// Redirect target for legacy `/local`, bare `/libraries`, and `/libraries/all`.
  static String? redirectPath({required String locationPath}) {
    if (locationPath == '/local' ||
        locationPath == root ||
        locationPath == legacyAll) {
      return '/home';
    }
    return null;
  }

  static bool isLibraryBrowsePath(String path) {
    return libraryIdFromPath(path) != null;
  }

  static String? libraryIdFromPath(String path) {
    if (!path.startsWith('$root/')) {
      return null;
    }
    final String id = path.substring(root.length + 1);
    if (id.isEmpty || id.contains('/') || id == legacyAllSegment) {
      return null;
    }
    return id;
  }
}

/// Sidebar selection derived from location only.
typedef LibrariesSidebarSelection = ({String? activeLibraryId});

/// Collapsed rail icon is active when a specific library browse is open.
bool librariesRailIconActive(LibrariesSidebarSelection selection) {
  return selection.activeLibraryId != null;
}

LibrariesSidebarSelection librariesSidebarSelection({required String path}) {
  return (activeLibraryId: LibrariesRoutes.libraryIdFromPath(path));
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
    return (goPath: '/home');
  }
  return (goPath: LibrariesRoutes.library(remainingLibraryIds.first));
}
