/// Lab 首页「管库」列表行（预览 / 将来接生产 read model）。
enum Md3eHomeLibraryKind {
  local,
  remote,
}

/// 与侧栏 overflow 顺序一致的操作项。
enum Md3eHomeLibraryManagementAction {
  scan,
  deepScan,
  refreshMetadata,
  edit,
  delete,
}

enum Md3eHomeLibraryRowHint {
  none,
  syncWarning,
  unreachable,
}

class Md3eHomeLibraryDashboardRow {
  const Md3eHomeLibraryDashboardRow({
    required this.libraryId,
    required this.displayName,
    required this.kind,
    required this.comicCount,
    required this.seriesCount,
    this.lastSyncedAt,
    this.hint = Md3eHomeLibraryRowHint.none,
    this.scanInProgress = false,
    this.metadataRefreshInProgress = false,
  });

  final String libraryId;
  final String displayName;
  final Md3eHomeLibraryKind kind;
  final int comicCount;
  final int seriesCount;
  final DateTime? lastSyncedAt;
  final Md3eHomeLibraryRowHint hint;
  final bool scanInProgress;
  final bool metadataRefreshInProgress;

  bool get busy => scanInProgress || metadataRefreshInProgress;
}
