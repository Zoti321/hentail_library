import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/widgets/catalog_selection_header_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

class _TestCatalogSelectionNotifier extends CatalogSelectionNotifier {
  _TestCatalogSelectionNotifier(this._state);

  CatalogSelectionState _state;

  @override
  CatalogSelectionState build() => _state;

  void setState(CatalogSelectionState next) => _state = next;

  @override
  void exit() {
    _state = const CatalogSelectionState();
    state = _state;
  }

  @override
  void selectPage(Iterable<String> comicIds) {
    _state = _state.copyWith(
      selectedIds: <String>{..._state.selectedIds, ...comicIds},
    );
    state = _state;
  }

  @override
  void clearSelection() {
    _state = _state.copyWith(selectedIds: const <String>{});
    state = _state;
  }
}

Future<ProviderContainer> _pumpHeader(
  WidgetTester tester, {
  required CatalogSelectionState selectionState,
  List<String> pageComicIds = const <String>['c1', 'c2'],
  List<Override> extraOverrides = const <Override>[],
}) async {
  final _TestCatalogSelectionNotifier notifier =
      _TestCatalogSelectionNotifier(selectionState);
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      catalogSelectionProvider.overrideWith(() => notifier),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: CatalogSelectionHeaderSection(
            layoutTier: LibraryLayoutTier.medium,
            horizontalPadding: 28,
            pageComicIds: pageComicIds,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  testWidgets('exit button uses X icon without Tooltip wrapper', (
    WidgetTester tester,
  ) async {
    await _pumpHeader(
      tester,
      selectionState: const CatalogSelectionState(active: true),
    );

    expect(find.byIcon(LucideIcons.x), findsOneWidget);
    expect(find.byType(Tooltip), findsNothing);

    final GhostButton exitButton = tester.widget(
      find.ancestor(
        of: find.byIcon(LucideIcons.x),
        matching: find.byType(GhostButton),
      ),
    );
    expect(exitButton.tooltip, '');
    expect(exitButton.semanticLabel, l10n.catalogSelectionExit);
  });

  testWidgets('toggle shows select page then clear selection', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpHeader(
      tester,
      selectionState: const CatalogSelectionState(active: true),
      pageComicIds: const <String>['c1', 'c2'],
    );

    expect(find.text(l10n.catalogSelectionSelectPage), findsOneWidget);
    expect(find.text(l10n.catalogSelectionClear), findsNothing);

    await tester.tap(find.text(l10n.catalogSelectionSelectPage));
    await tester.pumpAndSettle();

    expect(
      container.read(catalogSelectionProvider).selectedIds,
      equals(<String>{'c1', 'c2'}),
    );
    expect(find.text(l10n.catalogSelectionClear), findsOneWidget);
    expect(find.text(l10n.catalogSelectionSelectPage), findsNothing);

    await tester.tap(find.text(l10n.catalogSelectionClear));
    await tester.pumpAndSettle();

    expect(container.read(catalogSelectionProvider).selectedIds, isEmpty);
    expect(find.text(l10n.catalogSelectionSelectPage), findsOneWidget);
  });

  testWidgets('selected count is trailing when comics are selected', (
    WidgetTester tester,
  ) async {
    await _pumpHeader(
      tester,
      selectionState: const CatalogSelectionState(
        active: true,
        selectedIds: <String>{'c1'},
      ),
    );

    expect(find.text(l10n.catalogSelectionSelectedCount(1)), findsOneWidget);
    expect(find.text(l10n.catalogSelectionEditMetadata), findsOneWidget);
  });

  testWidgets('shows zero selected count when selection is empty', (
    WidgetTester tester,
  ) async {
    await _pumpHeader(
      tester,
      selectionState: const CatalogSelectionState(active: true),
    );

    expect(find.text(l10n.catalogSelectionSelectedCount(0)), findsOneWidget);
    expect(find.text(l10n.catalogSelectionEditMetadata), findsOneWidget);
    expect(find.text(l10n.catalogSelectionSelectPage), findsOneWidget);
  });

  testWidgets('exit button leaves selection mode', (WidgetTester tester) async {
    final ProviderContainer container = await _pumpHeader(
      tester,
      selectionState: const CatalogSelectionState(
        active: true,
        selectedIds: <String>{'c1'},
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(container.read(catalogSelectionProvider).active, isFalse);
    expect(container.read(catalogSelectionProvider).selectedIds, isEmpty);
  });
}
