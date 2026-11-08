/// 首页「我的漫画库」列表行模型（生产 Panel / Lab 预览共用）。
enum HomeLibraryKind { local, remote }

/// 与行 overflow 菜单顺序一致的操作项。
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
    this.staleDays,
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

  /// `hint == syncWarning` 时的「已超过 N 天」；无上次成功同步时可为 null。
  final int? staleDays;
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
    int? staleDays,
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
      staleDays: staleDays ?? this.staleDays,
      scanInProgress: scanInProgress ?? this.scanInProgress,
      metadataRefreshInProgress:
          metadataRefreshInProgress ?? this.metadataRefreshInProgress,
    );
  }
}
