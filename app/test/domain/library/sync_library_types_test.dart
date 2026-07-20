import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';

void main() {
  testWidgets('libraryScanSuccessToast formats withRoots stats', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
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

    final String message = l10n.libraryScanSuccessToast(
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

  testWidgets('libraryScanSuccessToast uses deep scan prefix', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
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

    final String message = l10n.libraryScanSuccessToast(
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
