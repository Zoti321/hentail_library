export 'package:hentai_library/features/home/domain/home_library_stat.dart';

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
