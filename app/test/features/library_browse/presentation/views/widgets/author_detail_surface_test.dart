import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/shared/ui/widgets/author/author_detail_surface.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAuthorRepository implements AuthorRepository {
  final List<(String, String)> renames = <(String, String)>[];
  final List<(AuthorLinkPlatform, String)> addedLinks =
      <(AuthorLinkPlatform, String)>[];
  final List<(int, int)> deletedLinks = <(int, int)>[];
  List<AuthorLink> links = const <AuthorLink>[];

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
      links: links,
      tags: const <AuthorFacetCount>[],
      parodies: const <AuthorFacetCount>[],
      characters: const <AuthorFacetCount>[],
      topComics: const <AuthorTopComic>[],
      comicCount: 0,
      image: (
        avatarSource: AuthorImageSource.none,
        avatarComicId: null,
        avatarLinkId: null,
        avatarImageUrl: null,
        backgroundSource: AuthorImageSource.none,
        backgroundComicId: null,
        backgroundLinkId: null,
        backgroundImageUrl: null,
      ),
    );
  }

  @override
  Future<Uint8List?> loadImage({
    required int authorId,
    required AuthorImageSlot slot,
    required bool showR18,
  }) async => null;

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
  Future<void> deleteLink({required int authorId, required int linkId}) async {
    deletedLinks.add((authorId, linkId));
  }
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
    expect(find.text('漫画 · 0'), findsOneWidget);
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

  testWidgets('link chip remove button deletes without confirm', (
    WidgetTester tester,
  ) async {
    final _StubAuthorRepository repo = _StubAuthorRepository()
      ..links = <AuthorLink>[
        (
          id: 7,
          platform: AuthorLinkPlatform.pixiv,
          url: 'https://www.pixiv.net/users/42',
          platformDisplayName: null,
          sortKey: 0,
        ),
      ];
    await _openSurface(tester, repo);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.text('删除链接「Pixiv」？'), findsNothing);
    expect(repo.deletedLinks, <(int, int)>[(1, 7)]);
  });

  testWidgets('verified badge uses primary like metadata author chips', (
    WidgetTester tester,
  ) async {
    await _openSurface(tester, _StubAuthorRepository());

    final Icon badge = tester.widget<Icon>(find.byIcon(LucideIcons.badgeCheck));
    expect(badge.color, buildAppTheme(Brightness.light).colorScheme.primary);
  });

  testWidgets('desktop hover reveals reserved remove without resizing dialog', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final _StubAuthorRepository repo = _StubAuthorRepository()
      ..links = <AuthorLink>[
        (
          id: 7,
          platform: AuthorLinkPlatform.pixiv,
          url: 'https://www.pixiv.net/users/42',
          platformDisplayName: null,
          sortKey: 0,
        ),
      ];
    await _openSurface(tester, repo);

    final Finder remove = find.byIcon(LucideIcons.x);
    expect(remove, findsOneWidget);
    expect(
      tester
          .widget<Visibility>(
            find.ancestor(of: remove, matching: find.byType(Visibility)).first,
          )
          .visible,
      isFalse,
    );

    final double heightBefore = tester
        .getSize(find.byKey(AdaptiveFormSurface.dialogChromeKey))
        .height;
    final Size chipBefore = tester.getSize(find.byType(OutlinedMetaChip).first);

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Pixiv')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Visibility>(
            find.ancestor(of: remove, matching: find.byType(Visibility)).first,
          )
          .visible,
      isTrue,
    );
    expect(
      tester.getSize(find.byKey(AdaptiveFormSurface.dialogChromeKey)).height,
      heightBefore,
    );
    expect(tester.getSize(find.byType(OutlinedMetaChip).first), chipBefore);

    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(repo.deletedLinks, <(int, int)>[(1, 7)]);
    debugDefaultTargetPlatformOverride = null;
  });
}
