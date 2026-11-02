import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library_md3e/library_md3e_selection_header.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _FakeCatalogSelection extends CatalogSelectionNotifier {
  _FakeCatalogSelection(this.initial, this.calls);

  final CatalogSelectionState initial;
  final List<String> calls;

  @override
  CatalogSelectionState build() => initial;

  @override
  void exit() => calls.add('exit');

  @override
  void clearSelection() => calls.add('clear');

  @override
  void selectPage(Iterable<String> comicIds) =>
      calls.add('selectPage:${comicIds.join(',')}');
}

Future<void> _pump(
  WidgetTester tester, {
  required CatalogSelectionState selection,
  required List<String> calls,
  required List<String> pageComicIds,
}) async {
  tester.view.physicalSize = const Size(900, 400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        catalogSelectionProvider.overrideWith(
          () => _FakeCatalogSelection(selection, calls),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Md3eLibrarySelectionHeader(pageComicIds: pageComicIds),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final AppLocalizations l10n = AppLocalizationsZh();

  testWidgets('shows the selected count and selects the whole page', (
    WidgetTester tester,
  ) async {
    final List<String> calls = <String>[];
    await _pump(
      tester,
      selection: const CatalogSelectionState(active: true),
      calls: calls,
      pageComicIds: <String>['a', 'b'],
    );

    expect(find.text(l10n.catalogSelectionSelectedCount(0)), findsOneWidget);

    await tester.tap(find.text(l10n.catalogSelectionSelectPage));
    await tester.pumpAndSettle();

    expect(calls, <String>['selectPage:a,b']);
  });

  testWidgets('shows clear when comics are selected and clears on tap', (
    WidgetTester tester,
  ) async {
    final List<String> calls = <String>[];
    await _pump(
      tester,
      selection: const CatalogSelectionState(
        active: true,
        selectedIds: <String>{'a'},
      ),
      calls: calls,
      pageComicIds: <String>['a', 'b'],
    );

    expect(find.text(l10n.catalogSelectionSelectedCount(1)), findsOneWidget);
    expect(find.text(l10n.catalogSelectionSelectPage), findsNothing);

    await tester.tap(find.text(l10n.catalogSelectionClear));
    await tester.pumpAndSettle();

    expect(calls, <String>['clear']);
  });

  testWidgets('close icon exits selection mode', (WidgetTester tester) async {
    final List<String> calls = <String>[];
    await _pump(
      tester,
      selection: const CatalogSelectionState(active: true),
      calls: calls,
      pageComicIds: const <String>[],
    );

    await tester.tap(find.byTooltip(l10n.catalogSelectionExit));
    await tester.pumpAndSettle();

    expect(calls, <String>['exit']);
  });
}
