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
  Future<void> rename(String oldName, String newName) async {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('author detail uses AdaptiveFormSurface dialog chrome', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authorRepoProvider.overrideWithValue(_StubAuthorRepository()),
        ],
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

    expect(find.byKey(AdaptiveFormSurface.dialogChromeKey), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('在搜索中查看'), findsOneWidget);
  });
}
