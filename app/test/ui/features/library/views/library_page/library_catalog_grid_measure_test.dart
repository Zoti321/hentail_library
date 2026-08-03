import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/library_blocks_layout.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_cover_viewport_notifier.dart';

void main() {
  testWidgets(
    'measureScrollableKeyedContentOffset works for LibraryBlocksSliverGroup',
    (WidgetTester tester) async {
      final GlobalKey catalogBlocksKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                LibraryBlocksSliverGroup(
                  key: catalogBlocksKey,
                  seriesBlock: const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                  comicsBlock: const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final RenderObject? renderObject = catalogBlocksKey.currentContext
          ?.findRenderObject();
      expect(renderObject, isA<RenderSliverMainAxisGroup>());
      expect(renderObject, isNot(isA<RenderBox>()));

      final double? offset = measureScrollableKeyedContentOffset(
        catalogBlocksKey,
      );
      expect(tester.takeException(), isNull);
      expect(offset, closeTo(80, 0.5));
    },
  );
}
