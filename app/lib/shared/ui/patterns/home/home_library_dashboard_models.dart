/// Lab 首页「管库」列表行（预览 / 将来接生产 read model）。
enum HomeLibraryKind { local, remote }

/// 与侧栏 overflow 顺序一致的操作项。
enum HomeLibraryManagementAction {
  scan,
  deepScan,
  refreshMetadata,
  edit,
  delete,
}

enum HomeLibraryRowHint { none, syncWarning, unreachable }

class HomeLibraryDashboardRow {
  const HomeLibraryDashboardRow({
    required this.libraryId,
    required this.displayName,
    required this.kind,
    required this.comicCount,
    required this.seriesCount,
    this.lastSyncedAt,
    this.hint = HomeLibraryRowHint.none,
    this.scanInProgress = false,
    this.metadataRefreshInProgress = false,
  });

  final String libraryId;
  final String displayName;
  final HomeLibraryKind kind;
  final int comicCount;
  final int seriesCount;
  final DateTime? lastSyncedAt;
  final HomeLibraryRowHint hint;
  final bool scanInProgress;
  final bool metadataRefreshInProgress;

  bool get busy => scanInProgress || metadataRefreshInProgress;

  HomeLibraryDashboardRow copyWith({
    String? libraryId,
    String? displayName,
    HomeLibraryKind? kind,
    int? comicCount,
    int? seriesCount,
    DateTime? lastSyncedAt,
    HomeLibraryRowHint? hint,
    bool? scanInProgress,
    bool? metadataRefreshInProgress,
  }) {
    return HomeLibraryDashboardRow(
      libraryId: libraryId ?? this.libraryId,
      displayName: displayName ?? this.displayName,
      kind: kind ?? this.kind,
      comicCount: comicCount ?? this.comicCount,
      seriesCount: seriesCount ?? this.seriesCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      hint: hint ?? this.hint,
      scanInProgress: scanInProgress ?? this.scanInProgress,
      metadataRefreshInProgress:
          metadataRefreshInProgress ?? this.metadataRefreshInProgress,
    );
  }
}
