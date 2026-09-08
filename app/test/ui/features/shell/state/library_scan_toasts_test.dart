import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/shell/state/library_scan_toasts.dart';
import 'package:test/test.dart';

SyncLibraryProgress _withRoots({
  required int added,
  required int removed,
  required int migrated,
  String? errorMessage,
}) {
  return (
    phase: SyncLibraryPhase.done,
    route: SyncLibraryRoute.withRoots,
    currentPath: null,
    acceptedTotal: added + removed + migrated,
    counts: emptyLibrarySyncCounts(),
    removedCount: removed,
    addedCount: added,
    keptCount: null,
    migratedCount: migrated,
    thumbnailTotal: null,
    thumbnailDone: null,
    thumbnailFailedCount: null,
    errorMessage: errorMessage,
  );
}

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  group('shouldShowLibraryScanCompletionToast', () {
    test('shows only when silent scan transitions running to idle', () {
      expect(
        shouldShowLibraryScanCompletionToast(
          previousSilent: true,
          previousRunning: true,
          nextRunning: false,
        ),
        isTrue,
      );
      expect(
        shouldShowLibraryScanCompletionToast(
          previousSilent: false,
          previousRunning: true,
          nextRunning: false,
        ),
        isFalse,
      );
      expect(
        shouldShowLibraryScanCompletionToast(
          previousSilent: true,
          previousRunning: true,
          nextRunning: true,
        ),
        isFalse,
      );
      expect(
        shouldShowLibraryScanCompletionToast(
          previousSilent: null,
          previousRunning: null,
          nextRunning: false,
        ),
        isFalse,
      );
    });
  });

  group('libraryScanCompletionMessage', () {
    test('startup success keeps zeros and marks startup source', () {
      expect(
        libraryScanCompletionMessage(l10n, (
          cancelled: false,
          error: null,
          scanMode: ScanMode.incremental,
          progress: _withRoots(added: 0, removed: 0, migrated: 0),
          fromStartup: true,
        )),
        '应用启动时扫描完成：新增 0，移除 0，迁移 0',
      );
    });

    test('manual success omits kept and reports migrated', () {
      expect(
        libraryScanCompletionMessage(l10n, (
          cancelled: false,
          error: null,
          scanMode: ScanMode.incremental,
          progress: _withRoots(added: 2, removed: 1, migrated: 3),
          fromStartup: false,
        )),
        '扫描完成：新增 2，移除 1，迁移 3',
      );
    });

    test('cancelled and error keep dedicated copy', () {
      expect(
        libraryScanCompletionMessage(l10n, (
          cancelled: true,
          error: null,
          scanMode: ScanMode.incremental,
          progress: null,
          fromStartup: true,
        )),
        l10n.libraryScanCancelledToast,
      );
      expect(
        libraryScanCompletionMessage(l10n, (
          cancelled: false,
          error: 'boom',
          scanMode: ScanMode.incremental,
          progress: null,
          fromStartup: false,
        )),
        'boom',
      );
    });

    test('remote skip warning stays informational', () {
      final LibraryScanCompletion completion = (
        cancelled: false,
        error: null,
        scanMode: ScanMode.incremental,
        progress: _withRoots(
          added: 0,
          removed: 0,
          migrated: 0,
          errorMessage: '已跳过远程库',
        ),
        fromStartup: true,
      );
      expect(libraryScanCompletionMessage(l10n, completion), '已跳过远程库');
      expect(libraryScanCompletionToastType(completion), AppToastType.info);
    });
  });
}
