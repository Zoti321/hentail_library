import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_snapshot.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_page.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_selection_header.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/di/comic_cover_providers.dart';
import 'package:hentai_library/shared/di/series_cover_providers.dart';
import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

Comic _comic(String id, String title) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: id,
    path: '/$id',
    resourceType: ResourceType.zip,
    resourceSize: 1,
    createdAt: now,
    lastUpdatedAt: now,
    title: title,
    pageCount: 1,
  );
}

const LibraryPagination _onePage = LibraryPagination(
  page: 1,
  totalPages: 1,
  totalCount: 2,
  isLoading: false,
);

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();
}

class _FakeFacade extends LibraryPageFacadeNotifier {
  _FakeFacade(this._state);

  final LibraryPageFacadeState _state;

  @override
  LibraryPageFacadeState build() => _state;
}

class _FixedComicsCatalog extends LibraryComicsCatalogController {
  _FixedComicsCatalog(this._state);

  final LibraryComicsCatalogState _state;

  @override
  Future<LibraryComicsCatalogState> build() async => _state;
}

class _FixedSeriesCatalog extends LibrarySeriesCatalogController {
  _FixedSeriesCatalog(this._state);

  final LibrarySeriesCatalogState _state;

  @override
  Future<LibrarySeriesCatalogState> build() async => _state;
}

const LocalLibrary _libraryA = (
  libraryId: 'lib-a',
  kind: 'local',
  rootPath: '/a',
  name: 'Library A',
  enabledResourceFormatCategories: <ResourceFormatCategory>[],
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: true,
  sidebarOrder: 0,
);

final AsyncValue<CurrentLibraryState> _currentLibrary = AsyncData(
  CurrentLibraryState(libraries: <LocalLibrary>[_libraryA], currentId: 'lib-a'),
);

LibraryPageFacadeState _facade(LibraryDisplayTarget target) {
  return (
    displayTarget: target,
    keyword: '',
    isFilterSortCustomized: false,
    comicsPage: 1,
    seriesPage: 1,
    comicsPageSize: 40,
    seriesPageSize: 40,
  );
}

class _FixedCatalogSelection extends CatalogSelectionNotifier {
  _FixedCatalogSelection(this._state);

  final CatalogSelectionState _state;

  @override
  CatalogSelectionState build() => _state;
}

Future<void> _pumpLibraryMd3ePage(
  WidgetTester tester, {
  required LibraryDisplayTarget target,
  required List<Comic> comics,
  List<Series> series = const <Series>[],
  CatalogSelectionState? selection,
}) async {
  tester.view.physicalSize = const Size(900, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final List<Override> coverOverrides = <Override>[
    for (final Comic comic in comics)
      comicCoverProvider(comic.comicId).overrideWith(_NoCoverComicCover.new),
    for (final Series s in series)
      seriesCoverSourceProvider(s.id)
          .overrideWith((Ref ref) async => const SeriesCoverMissing()),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        libraryPageFacadeProvider.overrideWith(
          () => _FakeFacade(_facade(target)),
        ),
        libraryComicsCatalogControllerProvider.overrideWith(
          () => _FixedComicsCatalog(
            LibraryComicsCatalogState(
              items: comics,
              pagination: _onePage,
              filterQuery: '',
              hasReceivedFirstEmit: true,
              isComicTableEmpty: comics.isEmpty,
            ),
          ),
        ),
        librarySeriesCatalogControllerProvider.overrideWith(
          () => _FixedSeriesCatalog(
            LibrarySeriesCatalogState(
              items: series,
              pagination: _onePage,
              filterQuery: '',
              isSeriesTableEmpty: series.isEmpty,
            ),
          ),
        ),
        currentLibraryStateProvider.overrideWithValue(_currentLibrary),
        libraryScanActivityStateProvider.overrideWithValue((
          running: false,
          scanMode: ScanMode.incremental,
        )),
        if (selection != null)
          catalogSelectionProvider.overrideWith(
            () => _FixedCatalogSelection(selection),
          ),
        ...coverOverrides,
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: LibraryMd3ePage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  testWidgets('comics tab renders MD3E comic cards from the real catalog', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryMd3ePage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: <Comic>[_comic('c1', 'Comic One'), _comic('c2', 'Comic Two')],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Md3eComicCard), findsNWidgets(2));
    expect(find.text('Comic One'), findsOneWidget);
  });

  testWidgets('series tab renders series names from the real catalog', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryMd3ePage(
      tester,
      target: LibraryDisplayTarget.series,
      comics: const <Comic>[],
      series: <Series>[
        Series(id: 's1', name: 'Series Alpha', folderPath: '/alpha'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Md3eComicCard), findsOneWidget);
    expect(find.text('Series Alpha'), findsOneWidget);
  });

  testWidgets('long-pressing a comic card opens the comic action menu', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryMd3ePage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: <Comic>[_comic('c1', 'Comic One')],
    );

    await tester.longPress(find.byType(Md3eComicCard));
    await tester.pumpAndSettle();

    expect(find.text(l10n.comicDetailRead), findsOneWidget);
    expect(find.text(l10n.comicDetailEditMetadata), findsOneWidget);
    expect(find.text(l10n.comicDetailShowInExplorer), findsOneWidget);
    expect(find.text(l10n.comicDetailDelete), findsOneWidget);
  });

  testWidgets('empty comics catalog shows the empty-library title', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryMd3ePage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: const <Comic>[],
    );

    expect(find.text(l10n.libraryEmptyTitle), findsOneWidget);
  });

  testWidgets('selection mode swaps the page header for the selection header', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryMd3ePage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: <Comic>[_comic('c1', 'Comic One'), _comic('c2', 'Comic Two')],
      selection: const CatalogSelectionState(
        active: true,
        selectedIds: <String>{'c1'},
      ),
    );

    expect(find.byType(Md3eLibrarySelectionHeader), findsOneWidget);
    expect(find.byType(Md3eLibraryPageHeader), findsNothing);
    expect(find.text(l10n.catalogSelectionSelectedCount(1)), findsOneWidget);
    expect(find.byType(Md3eComicCard), findsNWidgets(2));
  });
}
