import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';

/// Library sync 进行中，或后台缩略图队列仍活跃（`total > 0 && done < total`）。
///
/// Catalog / Home revision 节流共用此谓词；Remote（无本地缩略图）时退化为仅 sync.running。
bool isLibraryRevisionThrottleBusy({
  required bool librarySyncRunning,
  required bool thumbnailBackgroundActive,
}) => librarySyncRunning || thumbnailBackgroundActive;

/// Catalog / Home 应对 revision 降频的 busy 信号。
final libraryRevisionThrottleBusyProvider = Provider<bool>((Ref ref) {
  final bool librarySyncRunning = ref.watch(
    scanLibraryControllerProvider.select((ScanLibraryState s) => s.running),
  );
  final bool thumbnailBackgroundActive = ref.watch(
    thumbnailEventCoordinatorProvider.select(
      (ThumbnailBackgroundProgress p) => p.isActive,
    ),
  );
  return isLibraryRevisionThrottleBusy(
    librarySyncRunning: librarySyncRunning,
    thumbnailBackgroundActive: thumbnailBackgroundActive,
  );
});
