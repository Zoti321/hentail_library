import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/core/widgets/element/card/series_card.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/meta_chip.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_page_providers.dart';
import 'package:hentai_library/ui/features/library/views/searched_page.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
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

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();
}

class _FixedComicsController extends LibrarySearchPageComicsController {
  _FixedComicsController(this.page);

  final LibrarySearchComicsPage page;
  int loadMoreCalls = 0;

  @override
  Future<LibrarySearchComicsPage> build(String keyword) async => page;

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
  }
}

Future<void> _pumpSearchedPage(
  WidgetTester tester, {
  required String query,
  required LibrarySearchComicsPage comicsPage,
  required _FixedComicsController controller,
  Size viewport = const Size(900, 800),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final List<Override> coverOverrides = comicsPage.items
      .map(
        (Comic comic) => comicCoverProvider(
          comic.comicId,
        ).overrideWith(_NoCoverComicCover.new),
      )
      .toList();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        librarySearchPageComicsControllerProvider(
          query,
        ).overrideWith(() => controller),
        ...coverOverrides,
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: SearchedPage(query: query)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  testWidgets('search results show comic grid without series section', (
    WidgetTester tester,
  ) async {
    const String query = 'foo';
    final LibrarySearchComicsPage page = (
      items: <Comic>[_comic('c1', 'Comic One'), _comic('c2', 'Comic Two')],
      totalCount: 2,
      hasMore: false,
      loadingMore: false,
    );
    final _FixedComicsController controller = _FixedComicsController(page);

    await _pumpSearchedPage(
      tester,
      query: query,
      comicsPage: page,
      controller: controller,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SeriesCard), findsNothing);
    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(ComicCard), findsNWidgets(2));
    expect(find.byKey(const Key('search-comic-c1')), findsOneWidget);
    expect(find.byKey(const Key('search-comic-c2')), findsOneWidget);
  });

  testWidgets('result count chip uses comic total only', (
    WidgetTester tester,
  ) async {
    const String query = 'tag:x';
    final LibrarySearchComicsPage page = (
      items: <Comic>[_comic('c1', 'Only Comic')],
      totalCount: 7,
      hasMore: false,
      loadingMore: false,
    );
    final _FixedComicsController controller = _FixedComicsController(page);

    await _pumpSearchedPage(
      tester,
      query: query,
      comicsPage: page,
      controller: controller,
    );

    final MetaChip chip = tester.widget(find.byType(MetaChip));
    expect(chip.label, '7');
  });

  testWidgets(
    'series-name-only hit shows empty state with back-to-library action',
    (WidgetTester tester) async {
      const String query = 'series-only';
      const LibrarySearchComicsPage page = (
        items: <Comic>[],
        totalCount: 0,
        hasMore: false,
        loadingMore: false,
      );
      final _FixedComicsController controller = _FixedComicsController(page);

      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GoRouter router = GoRouter(
        initialLocation: '/searched',
        routes: <RouteBase>[
          GoRoute(
            path: '/searched',
            builder: (BuildContext context, GoRouterState state) {
              return Scaffold(body: SearchedPage(query: query));
            },
          ),
          GoRoute(
            path: LibrariesRoutes.all,
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(body: Text('library-browse'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            librarySearchPageComicsControllerProvider(
              query,
            ).overrideWith(() => controller),
          ],
          child: MaterialApp.router(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SeriesCard), findsNothing);
      expect(find.byType(ComicCard), findsNothing);
      expect(find.byType(SliverGrid), findsNothing);
      expect(find.text(l10n.libraryNoMatchTitle), findsOneWidget);
      expect(find.text(l10n.searchBackToLibrary), findsOneWidget);

      await tester.tap(find.text(l10n.searchBackToLibrary));
      await tester.pumpAndSettle();

      expect(find.text('library-browse'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        LibrariesRoutes.all,
      );
    },
  );

  testWidgets('scrolling near bottom requests comic loadMore when hasMore', (
    WidgetTester tester,
  ) async {
    const String query = 'more';
    final List<Comic> items = List<Comic>.generate(
      24,
      (int i) => _comic('c$i', 'Comic $i'),
    );
    final LibrarySearchComicsPage page = (
      items: items,
      totalCount: 80,
      hasMore: true,
      loadingMore: false,
    );
    final _FixedComicsController controller = _FixedComicsController(page);

    await _pumpSearchedPage(
      tester,
      query: query,
      comicsPage: page,
      controller: controller,
      viewport: const Size(400, 500),
    );

    expect(controller.loadMoreCalls, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.loadMoreCalls, greaterThan(0));
  });
}
