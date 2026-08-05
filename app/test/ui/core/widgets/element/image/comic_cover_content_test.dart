import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets('no cover shows card placeholder without letterbox', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          comicCoverProvider('comic-1').overrideWith(_NoCoverComicCover.new),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: ComicCoverContent(comicId: 'comic-1'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CardLetterboxedCoverImage), findsNothing);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is ComicCoverPlaceholder &&
            widget.variant == ComicCoverPlaceholderVariant.card &&
            widget.kind == ComicCoverPlaceholderKind.noCover,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is ColoredBox && widget.color == Colors.white,
      ),
      findsNothing,
    );
  });
}

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();

  @override
  void ensureLoaded({ThumbnailPriority priority = ThumbnailPriority.high}) {}
}
