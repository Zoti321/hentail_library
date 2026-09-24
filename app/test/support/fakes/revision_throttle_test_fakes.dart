import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// Idle overrides for `libraryRevisionThrottleBusyProvider` 的两个上游。
///
/// 不加这两个 override 时，thumbnail coordinator 会订阅真 FRB 流，在无
/// `RustLib.init()` 的 unit test 里直接抛 `flutter_rust_bridge has not been
/// initialized`。
List<Override> idleRevisionThrottleOverrides() {
  return <Override>[
    scanLibraryControllerProvider.overrideWith(IdleScanLibraryController.new),
    thumbnailEventCoordinatorProvider.overrideWith(
      IdleThumbnailEventCoordinator.new,
    ),
  ];
}

class IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}

class IdleThumbnailEventCoordinator extends ThumbnailEventCoordinator {
  @override
  ThumbnailBackgroundProgress build() => const ThumbnailBackgroundProgress();
}
