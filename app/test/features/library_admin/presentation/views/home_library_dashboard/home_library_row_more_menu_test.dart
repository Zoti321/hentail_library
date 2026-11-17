import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_row_more_menu.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

import '../../../../../support/pump_localized_app.dart';

const HomeLibraryDashboardRow _imageSetRow = HomeLibraryDashboardRow(
  libraryId: 'img-1',
  displayName: '画师图集',
  kind: HomeLibraryKind.local,
  catalogKind: HomeLibraryCatalogKind.imageSet,
  comicCount: 0,
  seriesCount: 0,
);

const HomeLibraryDashboardRow _comicRow = HomeLibraryDashboardRow(
  libraryId: 'comic-1',
  displayName: '漫画库',
  kind: HomeLibraryKind.local,
  catalogKind: HomeLibraryCatalogKind.comic,
  comicCount: 3,
  seriesCount: 1,
);

Future<void> _pumpMenu(
  WidgetTester tester, {
  required HomeLibraryDashboardRow row,
  ValueChanged<HomeLibraryManagementAction>? onAction,
}) {
  return pumpLocalizedApp(
    tester,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          final AppLocalizations l10n = AppLocalizations.of(context);
          return HomeLibraryRowMoreMenu(
            l10n: l10n,
            row: row,
            onAction: onAction,
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('image set more menu exposes scan but not deepScan or metadata', (
    WidgetTester tester,
  ) async {
    final List<HomeLibraryManagementAction> actions =
        <HomeLibraryManagementAction>[];
    await _pumpMenu(tester, row: _imageSetRow, onAction: actions.add);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('扫描库'), findsOneWidget);
    expect(find.text('深度扫描库'), findsNothing);
    expect(find.text('刷新元数据'), findsNothing);

    await tester.tap(find.text('扫描库'));
    await tester.pumpAndSettle();

    expect(actions, <HomeLibraryManagementAction>[
      HomeLibraryManagementAction.scan,
    ]);
  });

  testWidgets('comic more menu keeps scan, deepScan, and metadata refresh', (
    WidgetTester tester,
  ) async {
    await _pumpMenu(tester, row: _comicRow, onAction: (_) {});
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('扫描库'), findsOneWidget);
    expect(find.text('深度扫描库'), findsOneWidget);
    expect(find.text('刷新元数据'), findsOneWidget);
  });
}
