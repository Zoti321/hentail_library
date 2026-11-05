import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';

/// 库扫描命令端口（#261d）。
///
/// 实现位于 `features/library_admin/di/shared_state_ports.dart`，
/// 由 library_admin 的 `ScanLibraryController` 承接。
abstract class LibraryScanCommandPort {
  Future<void> start({
    ScanMode mode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    bool silent = false,
  });

  void cancel();
}
