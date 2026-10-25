import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';

void main() {
  group('Md3eWindowSizeClass.fromWidth (M3 five tiers)', () {
    test('compact below 600', () {
      expect(
        Md3eWindowSizeClass.fromWidth(599),
        Md3eWindowSizeClass.compact,
      );
    });

    test('medium at 600 through 839', () {
      expect(
        Md3eWindowSizeClass.fromWidth(600),
        Md3eWindowSizeClass.medium,
      );
      expect(
        Md3eWindowSizeClass.fromWidth(839),
        Md3eWindowSizeClass.medium,
      );
    });

    test('expanded at 840 through 1199', () {
      expect(
        Md3eWindowSizeClass.fromWidth(840),
        Md3eWindowSizeClass.expanded,
      );
      expect(
        Md3eWindowSizeClass.fromWidth(1199),
        Md3eWindowSizeClass.expanded,
      );
    });

    test('large at 1200 through 1599', () {
      expect(
        Md3eWindowSizeClass.fromWidth(1200),
        Md3eWindowSizeClass.large,
      );
      expect(
        Md3eWindowSizeClass.fromWidth(1599),
        Md3eWindowSizeClass.large,
      );
    });

    test('extra large from 1600', () {
      expect(
        Md3eWindowSizeClass.fromWidth(1600),
        Md3eWindowSizeClass.extraLarge,
      );
    });
  });

  test('list-detail uses expanded lower bound', () {
    expect(Md3eBreakpoints.expanded, 840);
  });
}
