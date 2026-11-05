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

enum HomeLibraryAlertKind { remoteUnreachable, syncFailed, staleSync }

/// Home library alert（sync 健康摘要）。
class HomeLibraryAlert {
  const HomeLibraryAlert({
    required this.libraryId,
    required this.displayName,
    required this.kind,
    this.lastSuccessAt,
    this.lastErrorMessage,
    this.staleDays,
  });

  final String libraryId;
  final String displayName;
  final HomeLibraryAlertKind kind;
  final DateTime? lastSuccessAt;
  final String? lastErrorMessage;
  final int? staleDays;

  String dismissKey() => '$libraryId:${kind.name}';

  /// Fingerprint of alert payload; dismiss is ignored when this changes.
  String dismissFingerprint() {
    return 'sync:${lastSuccessAt?.millisecondsSinceEpoch ?? 0}:${lastErrorMessage ?? ''}';
  }
}
