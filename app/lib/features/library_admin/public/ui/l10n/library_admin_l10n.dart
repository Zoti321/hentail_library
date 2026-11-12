import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/resource_format_category.dart';

/// library_admin 领域枚举 → 展示文案（owner extension；ARB 源仍在 `core/l10n`）。
extension LibraryAdminL10nX on AppLocalizations {
  String resourceFormatCategoryLabel(ResourceFormatCategory group) {
    return switch (group) {
      ResourceFormatCategory.folder => settingsFormatGroupFolder,
      ResourceFormatCategory.pdf => settingsFormatGroupPdf,
      ResourceFormatCategory.epub => settingsFormatGroupEpub,
      ResourceFormatCategory.archive => settingsFormatGroupArchive,
    };
  }

  String scanIntervalLabel(ScanInterval interval) {
    return switch (interval) {
      ScanInterval.disabled => scanIntervalDisabled,
      ScanInterval.hourly => scanIntervalHourly,
      ScanInterval.every6Hours => scanIntervalEvery6Hours,
      ScanInterval.every12Hours => scanIntervalEvery12Hours,
      ScanInterval.daily => scanIntervalDaily,
      ScanInterval.weekly => scanIntervalWeekly,
    };
  }

  String libraryScanSuccessToast({
    required ScanMode mode,
    required SyncLibraryProgress? progress,
    bool fromStartup = false,
  }) {
    final bool isDeepScan = mode == ScanMode.full;

    if (progress == null) {
      return isDeepScan ? libraryDeepScanComplete : libraryScanComplete;
    }

    return switch (progress.route) {
      SyncLibraryRoute.noRootsNoop =>
        isDeepScan
            ? libraryDeepScanCompleteNoRoots
            : libraryScanCompleteNoRoots,

      SyncLibraryRoute.noRootsCleared =>
        isDeepScan
            ? libraryDeepScanCompleteCleared(progress.removedCount ?? 0)
            : libraryScanCompleteCleared(progress.removedCount ?? 0),

      SyncLibraryRoute.withRoots =>
        fromStartup
            ? libraryStartupScanCompleteStats(
                progress.addedCount ?? 0,
                progress.removedCount ?? 0,
                progress.migratedCount ?? 0,
              )
            : isDeepScan
            ? libraryDeepScanCompleteStats(
                progress.addedCount ?? 0,
                progress.removedCount ?? 0,
                progress.migratedCount ?? 0,
              )
            : libraryScanCompleteStats(
                progress.addedCount ?? 0,
                progress.removedCount ?? 0,
                progress.migratedCount ?? 0,
              ),
    };
  }

  String scanDialogRunningPhaseLabel(SyncLibraryProgress progress) {
    switch (progress.route) {
      case SyncLibraryRoute.noRootsNoop:
        return scanSyncing;

      case SyncLibraryRoute.noRootsCleared:
        return progress.phase == SyncLibraryPhase.writingDb
            ? scanWritingDb
            : scanClearingLibrary;

      case SyncLibraryRoute.withRoots:
        return switch (progress.phase) {
          SyncLibraryPhase.clearingLibrary => scanClearingLibrary,

          SyncLibraryPhase.scanning => scanScanningFiles,

          SyncLibraryPhase.writingDb => scanWritingDb,

          SyncLibraryPhase.generatingThumbnails => scanGeneratingThumbnails,

          SyncLibraryPhase.done => scanComplete,

          SyncLibraryPhase.failed => scanFailed,
        };
    }
  }

  String scanDialogProgressCount({
    required int done,
    required int total,
    required int failed,
  }) {
    if (failed > 0) {
      return scanProgressWithFailed(done, total, failed);
    }

    return scanProgressSimple(done, total);
  }

  String scanDialogThumbnailFailedSuffix(int count) {
    if (count <= 0) {
      return '';
    }

    return scanThumbnailFailedSuffix(count);
  }

  String scanDialogDoneSummaryLabel(SyncLibraryProgress? progress) {
    if (progress == null) {
      return scanComplete;
    }

    switch (progress.route) {
      case SyncLibraryRoute.noRootsNoop:
        return scanDoneNoRoots;

      case SyncLibraryRoute.noRootsCleared:
        return scanDoneCleared;

      case SyncLibraryRoute.withRoots:
        final int? removed = progress.removedCount;

        final int? added = progress.addedCount;

        final int? kept = progress.keptCount;

        final int? thumbFailed = progress.thumbnailFailedCount;

        if (removed != null && added != null && kept != null) {
          return scanDoneStats(
            removed,

            added,

            kept,

            scanDialogThumbnailFailedSuffix(thumbFailed ?? 0),
          );
        }

        return scanComplete;
    }
  }
}
