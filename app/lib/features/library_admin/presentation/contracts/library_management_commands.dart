import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_mode.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';

/// 库管理 UI 命令契约（#292，真源 @ library_admin，ADR-0045）。
///
/// 跨 feature 请 import `features/library_admin/public.dart`（ADR-0034）。
/// `shared/**` 不得消费本接口——那里只需要
/// `shared/ui/contracts/library_browse_fallback_command.dart` 的窄口。
/// 实现与 [libraryManagementCommandsProvider] 见 owner `presentation` / `public/di`。
abstract interface class LibraryManagementCommands {
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

  /// Fallback when there is no specific library browse to return to (→ `/home`).
  void goDefaultLibraryBrowse(BuildContext context);

  Future<void> scanLibrary(
    BuildContext context,
    String libraryId, {
    ScanMode mode = ScanMode.incremental,
    bool navigate = false,
  });

  Future<void> scanAllLibraries({ScanMode mode = ScanMode.incremental});
}
