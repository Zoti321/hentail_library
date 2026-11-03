export 'package:hentai_library/shared/domain/library/home_library_stat.dart';

/// 首页仪表盘聚合统计（行数/记录数，非业务字段）。
class HomePageCounts {
  const HomePageCounts({
    required this.comicCount,
    required this.tagCount,
    required this.seriesCount,
    required this.authorCount,
    required this.libraryCount,
  });
  final int comicCount;
  final int tagCount;
  final int seriesCount;
  final int authorCount;
  final int libraryCount;
}

enum HomeLibraryAlertKind {
  remoteUnreachable,
  syncFailed,
  staleSync,
  pendingResourcesDetected,
}

/// Home library alert（sync 态 + probe 合并后）。
class HomeLibraryAlert {
  const HomeLibraryAlert({
    required this.libraryId,
    required this.displayName,
    required this.kind,
    this.lastSuccessAt,
    this.lastErrorMessage,
    this.staleDays,
    this.pendingResourceCount,
  });

  final String libraryId;
  final String displayName;
  final HomeLibraryAlertKind kind;
  final DateTime? lastSuccessAt;
  final String? lastErrorMessage;
  final int? staleDays;
  final int? pendingResourceCount;

  String dismissKey() => '$libraryId:${kind.name}';

  /// Fingerprint of alert payload; dismiss is ignored when this changes.
  String dismissFingerprint() {
    return switch (kind) {
      HomeLibraryAlertKind.pendingResourcesDetected =>
        'probe:${pendingResourceCount ?? 0}',
      _ =>
        'sync:${lastSuccessAt?.millisecondsSinceEpoch ?? 0}:${lastErrorMessage ?? ''}',
    };
  }
}

class LibraryProbeResult {
  const LibraryProbeResult({
    required this.libraryId,
    required this.addedCount,
    required this.changedCount,
    required this.removedCount,
    required this.unreachable,
    this.errorMessage,
    required this.probedAt,
    required this.baselineMissing,
  });

  final String libraryId;
  final int addedCount;
  final int changedCount;
  final int removedCount;
  final bool unreachable;
  final String? errorMessage;
  final DateTime probedAt;
  final bool baselineMissing;

  int get pendingCount => addedCount + changedCount;
}
