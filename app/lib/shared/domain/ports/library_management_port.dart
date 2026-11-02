import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';

/// 库管理 UI 命令契约（#292）。
///
/// 跨 feature 请 import `features/library_admin/public.dart`（ADR-0034）。
/// 实现位于 library_admin；[libraryManagementPortProvider] 在 shared/di 声明。
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
