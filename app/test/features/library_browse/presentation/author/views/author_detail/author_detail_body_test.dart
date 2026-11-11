import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_detail_body.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../../widgetbook/lab/theme/md3e_theme.dart';
import '../../../../../../support/fakes/author_repository_test_fakes.dart';
import '../../../../../../support/pump_localized_app.dart';

class _StubAuthorRepository extends EmptyAuthorRepository {
  final List<(String, String)> renames = <(String, String)>[];
  final List<(AuthorLinkPlatform, String)> addedLinks =
      <(AuthorLinkPlatform, String)>[];
  final List<(int, int)> deletedLinks = <(int, int)>[];
  List<AuthorLink> links = const <AuthorLink>[];

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
  Future<void> deleteLink({required int authorId, required int linkId}) async {
    deletedLinks.add((authorId, linkId));
  }
}

Future<void> _pumpBody(WidgetTester tester, _StubAuthorRepository repo) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final List<Override> overrides = <Override>[
    authorRepoProvider.overrideWithValue(repo),
  ];
  final M3EThemeData m3e = buildThemeData(brightness: Brightness.light);
  await pumpLocalizedApp(
    tester,
    overrides: overrides,
    theme: buildAppTheme(Brightness.light),
    home: ThemeScope(
      m3e: m3e,
      child: const Scaffold(
        body: SingleChildScrollView(child: AuthorDetailBody(authorId: 1)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows author name and comic count', (WidgetTester tester) async {
    await _pumpBody(tester, _StubAuthorRepository());

    expect(find.text('Alice'), findsWidgets);
    expect(find.text('漫画 · 0'), findsOneWidget);
  });

  testWidgets('pencil button switches name to inline editor and renames', (
    WidgetTester tester,
  ) async {
    final _StubAuthorRepository repo = _StubAuthorRepository();
    await _pumpBody(tester, repo);

    await tester.tap(find.byIcon(Symbols.edit));
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
    await _pumpBody(tester, repo);

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
    await _pumpBody(tester, repo);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(repo.deletedLinks, <(int, int)>[(1, 7)]);
  });

  testWidgets('verified badge uses primary color', (WidgetTester tester) async {
    await _pumpBody(tester, _StubAuthorRepository());

    final Icon badge = tester.widget<Icon>(find.byIcon(Symbols.verified));
    final M3EThemeData theme = M3ETheme.of(tester.element(find.text('Alice')));
    expect(badge.color, theme.colorScheme.primary);
  });

  testWidgets('desktop hover reveals remove button on link chip', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

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
    await _pumpBody(tester, repo);

    final Finder remove = find.byIcon(LucideIcons.x);
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Pixiv')));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedMetaChip), findsWidgets);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(repo.deletedLinks, <(int, int)>[(1, 7)]);
    debugDefaultTargetPlatformOverride = null;
  });
}
