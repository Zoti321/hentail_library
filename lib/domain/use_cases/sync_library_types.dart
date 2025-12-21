// 同步漫画库任务专用进度快照（typedef record，不单独建 class）。

/// 扫描 / 清空 / 写库 / 生成缩略图 / 结束
enum SyncLibraryPhase {
  clearingLibrary,
  scanning,
  writingDb,
  generatingThumbnails,
  done,
}

/// 无根无数据 / 无根已清空 / 有根扫描
enum SyncLibraryRoute { noRootsNoop, noRootsCleared, withRoots }

typedef LibrarySyncCounts = ({int dir, int zip, int cbz, int epub});

typedef SyncLibraryProgress = ({
  SyncLibraryPhase phase,
  SyncLibraryRoute route,
  String? currentPath,
  int acceptedTotal,
  LibrarySyncCounts counts,

  /// diff 应用统计；扫描中或未产生时为 null。
  int? removedCount,
  int? addedCount,
  int? keptCount,

  /// 缩略图预生成进度；非 [SyncLibraryPhase.generatingThumbnails] 时为 null。
  int? thumbnailTotal,
  int? thumbnailDone,
  int? thumbnailFailedCount,
});

LibrarySyncCounts emptyLibrarySyncCounts() => (dir: 0, zip: 0, cbz: 0, epub: 0);
