import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';

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
  Future<AppLocalizations> pumpL10n(
    WidgetTester tester, {
    Locale locale = const Locale('zh'),
  }) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            l10n = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return l10n;
  }

  testWidgets(
    'manual Library sync success toast reports added/removed/migrated without kept',
    (WidgetTester tester) async {
      final AppLocalizations l10n = await pumpL10n(tester);

      final String message = l10n.libraryScanSuccessToast(
        mode: ScanMode.incremental,
        progress: _doneWithRoots(added: 2, removed: 1, migrated: 3, kept: 7),
      );

      expect(message, '扫描完成：新增 2，移除 1，迁移 3');
      expect(message.toLowerCase(), isNot(contains('kept')));
      expect(message, isNot(contains('保留')));
    },
  );

  testWidgets(
    'deep Library sync success toast reports added/removed/migrated without kept',
    (WidgetTester tester) async {
      final AppLocalizations l10n = await pumpL10n(tester);

      final String message = l10n.libraryScanSuccessToast(
        mode: ScanMode.full,
        progress: _doneWithRoots(added: 0, removed: 0, migrated: 0, kept: 0),
      );

      expect(message, '深度扫描完成：新增 0，移除 0，迁移 0');
      expect(message, isNot(contains('保留')));
    },
  );

  testWidgets(
    'startup Library sync success toast marks startup source and keeps zeros',
    (WidgetTester tester) async {
      final AppLocalizations l10n = await pumpL10n(tester);

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

  testWidgets('English manual Library sync success toast omits kept', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = await pumpL10n(
      tester,
      locale: const Locale('en'),
    );

    final String message = l10n.libraryScanSuccessToast(
      mode: ScanMode.incremental,
      progress: _doneWithRoots(added: 2, removed: 1, migrated: 3, kept: 7),
    );

    expect(message, 'Scan complete: added 2, removed 1, migrated 3');
    expect(message.toLowerCase(), isNot(contains('kept')));
  });

  testWidgets(
    'English startup Library sync success toast marks startup source',
    (WidgetTester tester) async {
      final AppLocalizations l10n = await pumpL10n(
        tester,
        locale: const Locale('en'),
      );

      final String message = l10n.libraryScanSuccessToast(
        mode: ScanMode.incremental,
        fromStartup: true,
        progress: _doneWithRoots(added: 0, removed: 0, migrated: 0),
      );

      expect(message, 'Startup scan complete: added 0, removed 0, migrated 0');
      expect(message.toLowerCase(), isNot(contains('kept')));
    },
  );
}
