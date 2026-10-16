import 'package:hentai_library/domain/library/sync_library_types.dart';

/// Domain port for library sync (FRB implementation lives in `data/`).
abstract class SyncLibraryPort {
  Future<void> call({
    ScanMode scanMode,
    bool syncAll,
    String? targetLibraryId,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  });

  void cancelActive();
}
