/// Library browse routes (Komga-like `/libraries/...`).
abstract final class LibrariesRoutes {
  static const String root = '/libraries';
  static const String all = '/libraries/all';
  static const String allSegment = 'all';

  static String library(String libraryId) => '$root/$libraryId';

  /// Single-library browse for [currentId], or All libraries browse when unset.
  static String browsePathForCurrent(String? currentId) {
    if (currentId == null || currentId.isEmpty) {
      return all;
    }
    return library(currentId);
  }

  /// Redirect target for legacy `/local` and bare `/libraries`.
  static String? redirectPath({
    required String locationPath,
    required String? currentLibraryId,
  }) {
    if (locationPath == '/local') {
      return browsePathForCurrent(currentLibraryId);
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

/// Sidebar selection derived from location + Current library.
typedef LibrariesSidebarSelection = ({
  bool sectionActive,
  String? activeLibraryId,
});

LibrariesSidebarSelection librariesSidebarSelection({
  required String path,
  required String? currentLibraryId,
}) {
  if (LibrariesRoutes.isAllLibrariesPath(path)) {
    return (sectionActive: true, activeLibraryId: null);
  }
  final String? pathLibraryId = LibrariesRoutes.libraryIdFromPath(path);
  if (pathLibraryId != null) {
    return (sectionActive: false, activeLibraryId: pathLibraryId);
  }
  if (path.startsWith('/comic/') || path.startsWith('/series/')) {
    return (sectionActive: false, activeLibraryId: currentLibraryId);
  }
  return (sectionActive: false, activeLibraryId: null);
}
