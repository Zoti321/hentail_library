import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/card_letterboxed_cover_image.dart';

void main() {
  testWidgets('ready cover uses contain fit on white letterbox', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: CardLetterboxedCoverImage(
              cover: ComicCoverSource.bytes(Uint8List.fromList(<int>[1, 2, 3])),
            ),
          ),
        ),
      ),
    );

    final AppComicImage image = tester.widget(find.byType(AppComicImage));
    expect(image.fit, BoxFit.contain);
    // One-dimension decode keeps intrinsic aspect (exact + both dims stretches).
    expect(image.cacheWidth, isNotNull);
    expect(image.cacheHeight, isNull);

    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is ColoredBox && widget.color == Colors.white,
      ),
      findsOneWidget,
    );
  });
}
