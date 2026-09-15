import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/immersive_cover_header.dart';

import '../../../../../support/pump_localized_app.dart';

/// Minimal 2×2 PNG (RGB).
final Uint8List _kTinyPng = Uint8List.fromList(<int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  2,
  0,
  0,
  0,
  2,
  8,
  2,
  0,
  0,
  0,
  253,
  212,
  154,
  115,
  0,
  0,
  0,
  16,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  207,
  192,
  0,
  68,
  12,
  16,
  10,
  0,
  31,
  238,
  3,
  253,
  139,
  95,
  20,
  212,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

void main() {
  const double coverWidth = 220;
  const double coverAspectRatio = 2 / 3;
  const Key coverKey = Key('foreground_cover');
  const Key contentKey = Key('primary_content');

  Widget buildSubject({
    required ComicCoverImage? backdropCover,
    double width = 800,
  }) {
    return SizedBox(
      width: width,
      child: ImmersiveCoverHeader(
        backdropCover: backdropCover,
        coverWidth: coverWidth,
        coverAspectRatio: coverAspectRatio,
        cover: SizedBox(
          key: coverKey,
          width: coverWidth,
          child: AspectRatio(
            aspectRatio: coverAspectRatio,
            child: const ColoredBox(color: Colors.orange),
          ),
        ),
        content: const SizedBox(
          key: contentKey,
          height: 400,
          child: ColoredBox(color: Colors.blue),
        ),
      ),
    );
  }

  testWidgets(
    'Cover Ready → backdrop present, bottom aligns with cover, spans width',
    (WidgetTester tester) async {
      final ComicCoverImage cover = ComicCoverImage.bytes(_kTinyPng);

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: buildSubject(backdropCover: cover),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(ImmersiveCoverHeader.backdropKey), findsOneWidget);

      final Rect headerRect = tester.getRect(find.byType(ImmersiveCoverHeader));
      final Rect backdropRect = tester.getRect(
        find.byKey(ImmersiveCoverHeader.backdropKey),
      );
      final Rect coverRect = tester.getRect(find.byKey(coverKey));

      expect(backdropRect.left, headerRect.left);
      expect(backdropRect.right, headerRect.right);
      expect(
        backdropRect.bottom,
        moreOrLessEquals(coverRect.bottom, epsilon: 0.5),
      );

      final ImmersiveCoverHeaderBackdrop backdrop = tester.widget(
        find.byType(ImmersiveCoverHeaderBackdrop),
      );
      expect(identical(backdrop.coverImage, cover), isTrue);
      expect(backdrop.coverImage.memoryBytes, same(_kTinyPng));
    },
  );

  testWidgets('NoCover / not Ready → no backdrop', (WidgetTester tester) async {
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: buildSubject(backdropCover: null),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(ImmersiveCoverHeader.backdropKey), findsNothing);
    expect(find.byType(ImmersiveCoverHeaderBackdrop), findsNothing);
  });

  testWidgets('backdrop uses the injected cover image source', (
    WidgetTester tester,
  ) async {
    final ComicCoverImage cover = ComicCoverImage.bytes(_kTinyPng);

    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: buildSubject(backdropCover: cover),
        ),
      ),
    );
    await tester.pump();

    final ImmersiveCoverHeaderBackdrop backdrop = tester.widget(
      find.byType(ImmersiveCoverHeaderBackdrop),
    );
    expect(backdrop.coverImage.memoryBytes, same(cover.memoryBytes));
    expect(backdrop.coverImage.filePath, cover.filePath);
  });
}
