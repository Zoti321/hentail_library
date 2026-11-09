export 'package:hentai_library/shared/domain/library/home_library_stat.dart';

/// 首页仪表盘聚合统计（行数/记录数，非业务字段）。
///
/// Home page counts：Comic / Series / Author / Parody / Character / Tag；
/// [libraryCount] 为库数量附属字段（非库存卡六计数之一）。
class HomePageCounts {
  const HomePageCounts({
    required this.comicCount,
    required this.tagCount,
    required this.seriesCount,
    required this.authorCount,
    required this.parodyCount,
    required this.characterCount,
    required this.libraryCount,
  });
  final int comicCount;
  final int tagCount;
  final int seriesCount;
  final int authorCount;
  final int parodyCount;
  final int characterCount;
  final int libraryCount;

  HomePageCounts copyWith({
    int? comicCount,
    int? tagCount,
    int? seriesCount,
    int? authorCount,
    int? parodyCount,
    int? characterCount,
    int? libraryCount,
  }) {
    return HomePageCounts(
      comicCount: comicCount ?? this.comicCount,
      tagCount: tagCount ?? this.tagCount,
      seriesCount: seriesCount ?? this.seriesCount,
      authorCount: authorCount ?? this.authorCount,
      parodyCount: parodyCount ?? this.parodyCount,
      characterCount: characterCount ?? this.characterCount,
      libraryCount: libraryCount ?? this.libraryCount,
    );
  }
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
