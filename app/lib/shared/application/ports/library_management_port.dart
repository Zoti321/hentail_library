import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';

/// 库管理命令（新建 / 编辑 / 删除 / 扫描 / 切换与导航）的跨模块端口（#292）。
///
/// **迁移**：新代码请 import `features/library_admin/public.dart`（ADR-0034 / #434）。
/// 实现位于 library_admin，由 bootstrap 注入；library_browse、home 等只依赖本接口。
abstract interface class LibraryManagementPort {
  Future<void> addLocalLibrary(BuildContext context);

  Future<void> addRemoteLibrary(BuildContext context);

  Future<void> editRemoteLibrary(BuildContext context, LocalLibrary library);

  Future<void> editLibrarySettings(BuildContext context, LocalLibrary library);

  Future<void> deleteLibrary(
    BuildContext context,
    LocalLibrary library, {
    bool navigateAfter = true,
  });

  Future<void> openLibrary(BuildContext context, String libraryId);

  void goAllLibraries(BuildContext context);

  void goCurrentLibraryBrowse(BuildContext context);

  Future<void> scanLibrary(
    BuildContext context,
    String libraryId, {
    ScanMode mode = ScanMode.incremental,
    bool navigate = false,
  });

  Future<void> scanAllLibraries({ScanMode mode = ScanMode.incremental});
}
