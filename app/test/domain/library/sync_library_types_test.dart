import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:test/test.dart';

void main() {
  test('scanSuccessToastMessage formats withRoots stats', () {
    final String message = scanSuccessToastMessage(
      mode: ScanMode.incremental,
      progress: (
        phase: SyncLibraryPhase.done,
        route: SyncLibraryRoute.withRoots,
        currentPath: null,
        acceptedTotal: 10,
        counts: emptyLibrarySyncCounts(),
        removedCount: 1,
        addedCount: 2,
        keptCount: 7,
        thumbnailTotal: null,
        thumbnailDone: null,
        thumbnailFailedCount: null,
        errorMessage: null,
      ),
    );

    expect(message, '扫描完成：新增 2，移除 1，保留 7');
  });

  test('scanSuccessToastMessage uses deep scan prefix', () {
    final String message = scanSuccessToastMessage(
      mode: ScanMode.full,
      progress: (
        phase: SyncLibraryPhase.done,
        route: SyncLibraryRoute.withRoots,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
        removedCount: 0,
        addedCount: 0,
        keptCount: 0,
        thumbnailTotal: null,
        thumbnailDone: null,
        thumbnailFailedCount: null,
        errorMessage: null,
      ),
    );

    expect(message, '深度扫描完成：新增 0，移除 0，保留 0');
  });
}
