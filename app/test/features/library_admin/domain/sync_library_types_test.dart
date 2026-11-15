import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/l10n/app_localizations_zh.dart';
import 'package:hentai_library/l10n/app_localizations_en.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:test/test.dart';
import 'package:hentai_library/features/library_admin/public/ui/l10n/library_admin_l10n.dart';

SyncLibraryProgress _doneWithRoots({
  required int added,
  required int removed,
  required int migrated,
  int? kept,
}) {
  return (
    phase: SyncLibraryPhase.done,
    route: SyncLibraryRoute.withRoots,
    currentPath: null,
    acceptedTotal: added + removed + (kept ?? 0) + migrated,
    counts: emptyLibrarySyncCounts(),
    removedCount: removed,
    addedCount: added,
    keptCount: kept,
    migratedCount: migrated,
    thumbnailTotal: null,
    thumbnailDone: null,
    thumbnailFailedCount: null,
    errorMessage: null,
  );
}

void main() {
  test('manual Library sync success toast reports added/removed/migrated without kept', () {
    final AppLocalizations l10n = AppLocalizationsZh();

    final String message = l10n.libraryScanSuccessToast(
      mode: ScanMode.incremental,
      progress: _doneWithRoots(added: 2, removed: 1, migrated: 3, kept: 7),
    );

    expect(message, '扫描完成：新增 2，移除 1，迁移 3');
    expect(message.toLowerCase(), isNot(contains('kept')));
    expect(message, isNot(contains('保留')));
  });

  test('deep Library sync success toast reports added/removed/migrated without kept', () {
    final AppLocalizations l10n = AppLocalizationsZh();

    final String message = l10n.libraryScanSuccessToast(
      mode: ScanMode.full,
      progress: _doneWithRoots(added: 0, removed: 0, migrated: 0, kept: 0),
    );

    expect(message, '深度扫描完成：新增 0，移除 0，迁移 0');
    expect(message, isNot(contains('保留')));
  });

  test(
    'startup Library sync success toast marks startup source and keeps zeros',
    () {
      final AppLocalizations l10n = AppLocalizationsZh();

      final String message = l10n.libraryScanSuccessToast(
        mode: ScanMode.incremental,
        fromStartup: true,
        progress: _doneWithRoots(added: 0, removed: 0, migrated: 0),
      );

      expect(message, '应用启动时扫描完成：新增 0，移除 0，迁移 0');
      expect(message, contains('应用启动时扫描'));
      expect(message, isNot(contains('保留')));
    },
  );

  test('English manual Library sync success toast omits kept', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    final String message = l10n.libraryScanSuccessToast(
      mode: ScanMode.incremental,
      progress: _doneWithRoots(added: 2, removed: 1, migrated: 3, kept: 7),
    );

    expect(message, 'Scan complete: added 2, removed 1, migrated 3');
    expect(message.toLowerCase(), isNot(contains('kept')));
  });

  test('English startup Library sync success toast marks startup source', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    final String message = l10n.libraryScanSuccessToast(
      mode: ScanMode.incremental,
      fromStartup: true,
      progress: _doneWithRoots(added: 0, removed: 0, migrated: 0),
    );

    expect(message, 'Startup scan complete: added 0, removed 0, migrated 0');
    expect(message.toLowerCase(), isNot(contains('kept')));
  });
}
