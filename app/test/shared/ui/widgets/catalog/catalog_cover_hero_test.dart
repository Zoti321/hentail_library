import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';

void main() {
  group('CatalogCoverHero', () {
    test('comic and series tags are distinct and stable', () {
      expect(CatalogCoverHero.comicTag('c1'), 'comic-cover:c1');
      expect(CatalogCoverHero.seriesTag('s1'), 'series-cover:s1');
      expect(
        CatalogCoverHero.comicTag('x'),
        isNot(CatalogCoverHero.seriesTag('x')),
      );
    });

    testWidgets('wrap inserts Hero when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatalogCoverHero.wrap(
              tag: CatalogCoverHero.comicTag('c1'),
              child: const SizedBox(width: 40, height: 60),
            ),
          ),
        ),
      );

      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, CatalogCoverHero.comicTag('c1'));
      expect(hero.transitionOnUserGestures, isTrue);
    });

    testWidgets('wrap skips Hero when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatalogCoverHero.wrap(
              tag: CatalogCoverHero.comicTag('c1'),
              enabled: false,
              child: const SizedBox(width: 40, height: 60),
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsNothing);
    });
  });
}
