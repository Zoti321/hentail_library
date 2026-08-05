import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/series_cover_content.dart';
import 'package:hentai_library/ui/providers/series_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets('custom series thumbnail uses contain fit on white letterbox', (
    WidgetTester tester,
  ) async {
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          seriesCoverSourceProvider('series-1').overrideWith(
            (Ref ref) async => SeriesCoverCustomThumbnail(bytes),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: SeriesCoverContent(seriesId: 'series-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CardLetterboxedCoverImage), findsOneWidget);

    final AppComicImage image = tester.widget(find.byType(AppComicImage));
    expect(image.fit, BoxFit.contain);
    expect(image.memoryBytes, bytes);

    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is ColoredBox && widget.color == Colors.white,
      ),
      findsOneWidget,
    );
  });
}
