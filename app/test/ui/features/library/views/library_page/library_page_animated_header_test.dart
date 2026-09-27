import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_animated_header.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_pinned_header.dart';
import 'package:hentai_library/ui/features/library/views/widgets/catalog_selection_header_section.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> _libraryHeaderTestOverrides() {
  return <Override>[
    libraryDisplayedComicCountProvider.overrideWith((Ref ref) => 12),
    libraryDisplayedSeriesCountProvider.overrideWith((Ref ref) => 3),
    libraryDisplayTargetProvider.overrideWith(
      (Ref ref) => LibraryDisplayTarget.comics,
    ),
    libraryActiveFilterSortIsCustomizedProvider.overrideWith(
      (Ref ref) => false,
    ),
    libraryActivePageSizeProvider.overrideWith((Ref ref) => 20),
    catalogSelectionProvider.overrideWith(_TestCatalogSelectionNotifier.new),
  ];
}

class _TestCatalogSelectionNotifier extends CatalogSelectionNotifier {
  @override
  CatalogSelectionState build() => const CatalogSelectionState(active: true);
}

Future<void> _pumpAnimatedHeader(
  WidgetTester tester, {
  required bool selectionActive,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _libraryHeaderTestOverrides(),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: LibraryPageAnimatedHeader(
            selectionActive: selectionActive,
            layoutTier: LibraryLayoutTier.medium,
            horizontalPadding: 28,
            pageComicIds: const <String>['c1'],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(kLibraryHeaderModeTransitionDuration);
}

void main() {
  testWidgets('regular mode shows library pinned header section', (
    WidgetTester tester,
  ) async {
    await _pumpAnimatedHeader(tester, selectionActive: false);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('library-header')), findsOneWidget);
    expect(find.byType(LibraryPageHeaderSection), findsOneWidget);
    expect(find.byType(CatalogSelectionHeaderSection), findsNothing);
  });

  testWidgets('selection mode replaces pinned header with catalog selection chrome', (
    WidgetTester tester,
  ) async {
    await _pumpAnimatedHeader(tester, selectionActive: true);

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('catalog-selection-header')),
      findsOneWidget,
    );
    expect(find.byType(CatalogSelectionHeaderSection), findsOneWidget);
    expect(find.byType(LibraryPageHeaderSection), findsNothing);
  });
}
