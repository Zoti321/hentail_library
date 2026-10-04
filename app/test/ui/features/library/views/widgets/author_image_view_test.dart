import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/ui/features/library/view_models/author_detail_notifier.dart';
import 'package:hentai_library/ui/features/library/views/widgets/author_image_view.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show Ref;
import 'package:riverpod/misc.dart' show Override;

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
  Future<Uint8List?> Function() hd,
) async {
  await pumpLocalizedApp(
    tester,
    overrides: <Override>[
      comicCoverProvider('comic-1').overrideWith(
        () => FixedComicCover(ComicCoverReady(ComicCoverImage.bytes(_png))),
      ),
      authorImageProvider(_request).overrideWith((Ref ref) => hd()),
    ],
    home: const Scaffold(
      body: SizedBox(
        width: 400,
        height: 140,
        child: AuthorImageView(
          authorId: 1,
          slot: AuthorImageSlot.background,
          comicId: 'comic-1',
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows library thumbnail while hd image is pending', (
    WidgetTester tester,
  ) async {
    await _pump(tester, () => Completer<Uint8List?>().future);

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
    expect(find.byKey(AuthorImageView.hdImageKey), findsNothing);
  });

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

  testWidgets('stays on thumbnail when no hd image exists', (
    WidgetTester tester,
  ) async {
    await _pump(tester, () async => null);

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);
    expect(find.byKey(AuthorImageView.hdImageKey), findsNothing);
  });
}
