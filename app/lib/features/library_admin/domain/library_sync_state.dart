import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';

/// 库同步（scan controller）只读投影，供其他 owner 观察本次同步结果。
typedef LibrarySyncState = ({
  bool running,
  bool cancelled,
  /// null when idle or scanning all libraries.
  String? targetLibraryId,
  String? error,
  SyncLibraryProgress? progress,
});
