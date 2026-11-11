import 'package:hentai_library/core/constants/app_routes.dart';

/// Library browse routes (Komga-like `/libraries/:id`).
///
/// 路径真源在 [AppRoutes]；本类保留 library 语义的便捷入口。
abstract final class LibrariesRoutes {
  static const String root = AppRoutes.libraries;

  /// Legacy aggregate-browse path; always redirect away (not a real Library).
  static const String legacyAll = AppRoutes.legacyAll;
  static const String legacyAllSegment = AppRoutes.legacyAllSegment;

  static String library(String libraryId) => AppRoutes.library(libraryId);

  /// Redirect target for legacy `/local`, bare `/libraries`, and `/libraries/all`.
  static String? redirectPath({required String locationPath}) =>
      AppRoutes.legacyRedirectPath(locationPath);

  static bool isLibraryBrowsePath(String path) =>
      AppRoutes.libraryIdFromPath(path) != null;

  static String? libraryIdFromPath(String path) =>
      AppRoutes.libraryIdFromPath(path);
}

/// Sidebar selection derived from location only.
typedef LibrariesSidebarSelection = ({String? activeLibraryId});

/// Collapsed rail icon is active when a specific library browse is open.
bool librariesRailIconActive(LibrariesSidebarSelection selection) {
  return selection.activeLibraryId != null;
}

LibrariesSidebarSelection librariesSidebarSelection({required String path}) {
  return (activeLibraryId: AppRoutes.libraryIdFromPath(path));
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
    return (goPath: AppRoutes.home);
  }
  return (goPath: AppRoutes.library(remainingLibraryIds.first));
}
