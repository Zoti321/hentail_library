import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_search_page_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/searched_md3e/searched_md3e_page.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/di/comic_cover_providers.dart';
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

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();
}

class _FixedComicsController extends LibrarySearchPageComicsController {
  _FixedComicsController(this.page);

  final LibrarySearchComicsPage page;

  @override
  Future<LibrarySearchComicsPage> build(String keyword) async => page;

  @override
  Future<void> loadMore() async {}
}

Future<void> _pumpSearchedMd3ePage(
  WidgetTester tester, {
  required String query,
  required LibrarySearchComicsPage comicsPage,
}) async {
  tester.view.physicalSize = const Size(900, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final List<Override> coverOverrides = comicsPage.items
      .map(
        (Comic comic) =>
            comicCoverProvider(comic.comicId)
                .overrideWith(_NoCoverComicCover.new),
      )
      .toList();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        librarySearchPageComicsControllerProvider(query)
            .overrideWith(() => _FixedComicsController(comicsPage)),
        ...coverOverrides,
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: SearchedMd3ePage(query: query)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  testWidgets('renders MD3E comic cards and result count', (
    WidgetTester tester,
  ) async {
    const String query = 'foo';
    final LibrarySearchComicsPage page = (
      items: <Comic>[_comic('c1', 'Comic One'), _comic('c2', 'Comic Two')],
      totalCount: 2,
      hasMore: false,
      loadingMore: false,
    );

    await _pumpSearchedMd3ePage(tester, query: query, comicsPage: page);

    expect(tester.takeException(), isNull);
    expect(find.byType(Md3eComicCard), findsNWidgets(2));
    expect(find.text('Comic One'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('searched-result-count'))).data,
      '2',
    );
  });

  testWidgets('empty keyword shows the enter-keyword prompt', (
    WidgetTester tester,
  ) async {
    final LibrarySearchComicsPage page = (
      items: const <Comic>[],
      totalCount: 0,
      hasMore: false,
      loadingMore: false,
    );

    await _pumpSearchedMd3ePage(tester, query: '', comicsPage: page);

    expect(find.text(l10n.searchEnterKeyword), findsOneWidget);
    expect(find.byType(Md3eComicCard), findsNothing);
  });
}
