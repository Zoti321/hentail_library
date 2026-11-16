import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/application/sync_image_set_library_use_case.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_sync_outcome.dart';
import 'package:hentai_library/features/library_admin/public.dart';

void main() {
  test(
    'starts a silent library scan for the target and maps success counts',
    () async {
      String? startedLibrary;
      bool? startedSilent;
      final SyncImageSetLibraryUseCase useCase = SyncImageSetLibraryUseCase(
        startScan:
            ({
              ScanMode mode = ScanMode.incremental,
              bool syncAll = false,
              String? targetLibraryId,
              bool silent = false,
            }) async {
              startedLibrary = targetLibraryId;
              startedSilent = silent;
            },
        readSyncState: () => (
          running: false,
          cancelled: false,
          error: null,
          progress: (
            phase: SyncLibraryPhase.done,
            route: SyncLibraryRoute.withRoots,
            currentPath: null,
            acceptedTotal: 0,
            counts: emptyLibrarySyncCounts(),
            removedCount: 1,
            addedCount: 3,
            keptCount: 5,
            migratedCount: null,
            thumbnailTotal: null,
            thumbnailDone: null,
            thumbnailFailedCount: null,
            errorMessage: null,
          ),
        ),
      );

      final ImageSetSyncOutcome outcome = await useCase('img-1');

      expect(startedLibrary, 'img-1');
      expect(startedSilent, isFalse);
      expect(outcome, isA<ImageSetSyncSucceeded>());
      final ImageSetSyncSucceeded succeeded = outcome as ImageSetSyncSucceeded;
      expect(succeeded.addedCount, 3);
      expect(succeeded.removedCount, 1);
    },
  );

  test(
    'maps cancelled, failed and warned sync states without losing messages',
    () {
      expect(
        imageSetSyncOutcomeFrom((
          running: false,
          cancelled: true,
          error: null,
          progress: null,
        )),
        isA<ImageSetSyncCancelled>(),
      );
      final ImageSetSyncOutcome failed = imageSetSyncOutcomeFrom((
        running: false,
        cancelled: false,
        error: '读取失败',
        progress: null,
      ));
      expect((failed as ImageSetSyncFailed).message, '读取失败');
    },
  );
}
