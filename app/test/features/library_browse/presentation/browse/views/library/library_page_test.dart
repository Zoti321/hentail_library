import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/browse_view_object_mappers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_view_object.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_browse_view_object.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_snapshot.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_page.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_selection_header.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/features/comic/di/comic_cover_providers.dart';
import 'package:hentai_library/features/series/di/series_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/features/library_admin/public.dart';

import '../../../../../../support/pump_localized_app.dart';

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

ComicBrowseViewObject _comicViewObject(String id, String title) {
  return comicBrowseViewObjectFromComic(_comic(id, title));
}

SeriesBrowseViewObject _seriesViewObject(String id, String name) {
  return seriesBrowseViewObjectFromSeries(
    Series(id: id, name: name, folderPath: '/$id'),
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

final AsyncValue<LibrariesState> _currentLibrary = AsyncData(
  LibrariesState(libraries: <LocalLibrary>[_libraryA]),
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

Future<void> _pumpLibraryPage(
  WidgetTester tester, {
  required LibraryDisplayTarget target,
  required List<ComicBrowseViewObject> comics,
  List<SeriesBrowseViewObject> series = const <SeriesBrowseViewObject>[],
  CatalogSelectionState? selection,
}) async {
  configureTestView(tester, const Size(900, 800));

  final List<Override> coverOverrides = <Override>[
    for (final ComicBrowseViewObject comic in comics)
      comicCoverProvider(comic.comicId).overrideWith(_NoCoverComicCover.new),
    for (final SeriesBrowseViewObject s in series)
      seriesCoverSourceProvider(s.id)
          .overrideWith((Ref ref) async => const SeriesCoverMissing()),
  ];

  await pumpLocalizedApp(
    tester,
    home: const Scaffold(body: LibraryPage()),
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
      librariesStateProvider.overrideWithValue(_currentLibrary),
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
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  testWidgets('comics tab renders MD3E comic cards from the real catalog', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryPage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: <ComicBrowseViewObject>[
        _comicViewObject('c1', 'Comic One'),
        _comicViewObject('c2', 'Comic Two'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ComicCard), findsNWidgets(2));
    expect(find.text('Comic One'), findsOneWidget);
  });

  testWidgets('series tab renders series names from the real catalog', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryPage(
      tester,
      target: LibraryDisplayTarget.series,
      comics: const <ComicBrowseViewObject>[],
      series: <SeriesBrowseViewObject>[_seriesViewObject('s1', 'Series Alpha')],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ComicCard), findsOneWidget);
    expect(find.text('Series Alpha'), findsOneWidget);
  });

  testWidgets('right-clicking a comic card opens the comic action menu', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _pumpLibraryPage(
        tester,
        target: LibraryDisplayTarget.comics,
        comics: <ComicBrowseViewObject>[_comicViewObject('c1', 'Comic One')],
      );

      await tester.tap(find.byType(ComicCard), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.comicDetailRead), findsOneWidget);
      expect(find.text(l10n.comicDetailEditMetadata), findsOneWidget);
      expect(find.text(l10n.comicDetailShowInExplorer), findsOneWidget);
      expect(find.text(l10n.comicDetailDelete), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('empty comics catalog shows the empty-library title', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryPage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: const <ComicBrowseViewObject>[],
    );

    expect(find.text(l10n.libraryEmptyTitle), findsOneWidget);
  });

  testWidgets('selection mode swaps the page header for the selection header', (
    WidgetTester tester,
  ) async {
    await _pumpLibraryPage(
      tester,
      target: LibraryDisplayTarget.comics,
      comics: <ComicBrowseViewObject>[
        _comicViewObject('c1', 'Comic One'),
        _comicViewObject('c2', 'Comic Two'),
      ],
      selection: const CatalogSelectionState(
        active: true,
        host: CatalogSelectionHost.libraryBrowse,
        selectedIds: <String>{'c1'},
      ),
    );

    expect(find.byType(LibrarySelectionHeader), findsOneWidget);
    expect(find.byType(LibraryPageHeader), findsNothing);
    expect(find.text(l10n.catalogSelectionSelectedCount(1)), findsOneWidget);
    expect(find.byType(ComicCard), findsNWidgets(2));
  });
}
