import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/author/author_image_view.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope, Ref;
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../support/fakes/author_repository_test_fakes.dart';
import '../../../../../support/fakes/comic_cover_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';

const AuthorImageRequest _request = (
  authorId: 1,
  slot: AuthorImageSlot.background,
);

final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x02, 0x00,
  0x00, 0x05, 0x00, 0x01, 0xE9, 0xFA, 0xDC, 0xD8, 0x00, 0x00, 0x00, 0x00,
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<void> _pump(
  WidgetTester tester,
  Future<Uint8List?> Function() hd, {
  String? platformImageUrl,
}) async {
  await pumpLocalizedApp(
    tester,
    overrides: <Override>[
      comicCoverProvider('comic-1').overrideWith(
        () => FixedComicCover(ComicCoverReady(ComicCoverSource.bytes(_png))),
      ),
      authorImageProvider(_request).overrideWith((Ref ref) => hd()),
    ],
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 140,
        child: AuthorImageView(
          authorId: 1,
          slot: AuthorImageSlot.background,
          comicId: 'comic-1',
          platformImageUrl: platformImageUrl,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _PlatformAuthorRepository extends EmptyAuthorRepository {
  String avatarUrl = 'https://img.example/avatar-a.png';
  int loads = 0;

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
      comicCount: 0,
      image: (
        avatarSource: AuthorImageSource.platformCached,
        avatarComicId: null,
        avatarLinkId: 7,
        avatarImageUrl: avatarUrl,
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
  }) async {
    loads += 1;
    return _png;
  }
}

void main() {
  testWidgets('shows library thumbnail while hd image is pending', (
    WidgetTester tester,
  ) async {
    await _pump(tester, () => Completer<Uint8List?>().future);

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
    expect(find.byKey(AuthorImageView.hdImageKey), findsNothing);
    expect(find.byKey(AuthorImageView.slotLoadingKey), findsNothing);
  });

  testWidgets(
    'shows corner slot loading only after platform image url is confirmed',
    (WidgetTester tester) async {
      await _pump(
        tester,
        () => Completer<Uint8List?>().future,
        platformImageUrl: 'https://img.example/platform.png',
      );

      expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
      expect(find.byKey(AuthorImageView.slotLoadingKey), findsOneWidget);
    },
  );

  testWidgets('overlays hd image once ready', (WidgetTester tester) async {
    await _pump(tester, () async => _png);

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
    expect(find.byKey(AuthorImageView.hdImageKey), findsOneWidget);
  });

  testWidgets('stays on thumbnail when hd image fails', (
    WidgetTester tester,
  ) async {
    await _pump(tester, () async => throw StateError('boom'));

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
    expect(find.byKey(AuthorImageView.hdImageKey), findsNothing);
  });

  testWidgets('keeps the previous platform image when refresh fails', (
    WidgetTester tester,
  ) async {
    int loads = 0;
    await _pump(tester, () async {
      loads += 1;
      if (loads == 1) return _png;
      throw StateError('refresh failed');
    });
    expect(find.byKey(AuthorImageView.hdImageKey), findsOneWidget);

    final BuildContext context = tester.element(find.byType(AuthorImageView));
    ProviderScope.containerOf(
      context,
    ).invalidate(authorImageProvider(_request));
    await tester.pump();
    await tester.pump();

    expect(loads, 2);
    expect(find.byKey(AuthorImageView.hdImageKey), findsOneWidget);
  });

  testWidgets('stays on thumbnail when no hd image exists', (
    WidgetTester tester,
  ) async {
    await _pump(tester, () async => null);

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
    expect(find.byKey(AuthorImageView.hdImageKey), findsNothing);
  });

  testWidgets('reloads the platform image when the image url changes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _PlatformAuthorRepository repo = _PlatformAuthorRepository();
    await pumpLocalizedApp(
      tester,
      overrides: <Override>[authorRepoProvider.overrideWithValue(repo)],
      home: const Scaffold(
        body: SizedBox(
          width: 400,
          height: 140,
          child: AuthorImageView(authorId: 1, slot: AuthorImageSlot.avatar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repo.loads, 1);

    // 平台换了新图：URL 变化应触发重取（linkId 不变）。
    repo.avatarUrl = 'https://img.example/avatar-b.png';
    ProviderScope.containerOf(
      tester.element(find.byType(AuthorImageView)),
    ).invalidate(authorDetailProvider(1));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(repo.loads, 2);
    expect(find.byKey(AuthorImageView.hdImageKey), findsOneWidget);
  });
}
