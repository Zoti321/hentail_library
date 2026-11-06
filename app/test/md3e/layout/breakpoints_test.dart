import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';

void main() {
  group('WindowSizeClass.fromWidth (M3 five tiers)', () {
    test('compact below 600', () {
      expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
    });

    test('medium at 600 through 839', () {
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839), WindowSizeClass.medium);
    });

    test('expanded at 840 through 1199', () {
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1199), WindowSizeClass.expanded);
    });

    test('large at 1200 through 1599', () {
      expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(1599), WindowSizeClass.large);
    });

    test('extra large from 1600', () {
      expect(
        WindowSizeClass.fromWidth(1600),
        WindowSizeClass.extraLarge,
      );
    });
  });

  test('list-detail uses expanded lower bound', () {
    expect(Breakpoints.expanded, 840);
  });
}
