import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/features/library/views/widgets/author_detail_surface.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

class _StubAuthorRepository implements AuthorRepository {
  final List<(String, String)> renames = <(String, String)>[];
  final List<(AuthorLinkPlatform, String)> addedLinks =
      <(AuthorLinkPlatform, String)>[];

  @override
  Future<List<Author>> listAll() async => <Author>[
    Author(id: 1, name: 'Alice', verified: true),
  ];

  @override
  Stream<List<Author>> watchAll() => Stream<List<Author>>.value(<Author>[
    Author(id: 1, name: 'Alice', verified: true),
  ]);

  @override
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    return PagedResult<Author>(
      items: <Author>[Author(id: 1, name: 'Alice', verified: true)],
      totalCount: 1,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<Author> add(Author author) async => author;

  @override
  Future<void> deleteByNames(List<String> names) async {}

  @override
  Future<void> rename(String oldName, String newName) async {
    renames.add((oldName, newName));
  }

  @override
  Future<AuthorDetail?> getDetail({
    required int authorId,
    required bool showR18,
  }) async {
    return AuthorDetail(
      id: authorId,
      name: 'Alice',
      verified: true,
      links: const <AuthorLink>[],
      tags: const <AuthorFacetCount>[],
      parodies: const <AuthorFacetCount>[],
      characters: const <AuthorFacetCount>[],
      topComics: const <AuthorTopComic>[],
      image: (
        avatarSource: AuthorImageSource.none,
        avatarComicId: null,
        backgroundSource: AuthorImageSource.none,
        backgroundComicId: null,
      ),
    );
  }

  @override
  Future<AuthorLink> addLink({
    required int authorId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    addedLinks.add((platform, url));
    return (
      id: 1,
      platform: platform,
      url: url,
      platformDisplayName: platformDisplayName,
      sortKey: 0,
    );
  }

  @override
  Future<void> updateLink({
    required int linkId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {}

  @override
  Future<void> deleteLink(int linkId) async {}
}

Future<void> _openSurface(
  WidgetTester tester,
  _StubAuthorRepository repo,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[authorRepoProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showAdaptiveFormSurfaceWidget<void>(
                    context: context,
                    surface: const AuthorDetailSurface(authorId: 1),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('author detail uses AdaptiveFormSurface dialog chrome', (
    WidgetTester tester,
  ) async {
    await _openSurface(tester, _StubAuthorRepository());

    expect(find.byKey(AdaptiveFormSurface.dialogChromeKey), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('漫画'), findsOneWidget);
    expect(find.text('在搜索中查看'), findsOneWidget);
    expect(find.text('重命名'), findsNothing);
  });

  testWidgets('pencil button switches name to inline editor and renames', (
    WidgetTester tester,
  ) async {
    final _StubAuthorRepository repo = _StubAuthorRepository();
    await _openSurface(tester, repo);

    await tester.tap(find.byTooltip('重命名'));
    await tester.pumpAndSettle();
    final Finder field = find.byType(TextField);
    expect(field, findsOneWidget);

    await tester.enterText(field, 'Bob');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.renames, <(String, String)>[('Alice', 'Bob')]);
  });

  testWidgets('add link field detects platform from pasted url', (
    WidgetTester tester,
  ) async {
    final _StubAuthorRepository repo = _StubAuthorRepository();
    await _openSurface(tester, repo);

    await tester.tap(find.text('添加链接'));
    await tester.pumpAndSettle();
    expect(find.text('粘贴主页链接'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'https://www.pixiv.net/users/42',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.addedLinks, <(AuthorLinkPlatform, String)>[
      (AuthorLinkPlatform.pixiv, 'https://www.pixiv.net/users/42'),
    ]);
  });
}
