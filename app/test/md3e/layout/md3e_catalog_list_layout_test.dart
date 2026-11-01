import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';

void main() {
  test('md3eComicListColumnCount on desktop', () {
    int columns(Md3eWindowSizeClass window) =>
        md3eComicListColumnCount(window, desktop: true);

    expect(columns(Md3eWindowSizeClass.compact), 1);
    expect(columns(Md3eWindowSizeClass.medium), 2);
    expect(columns(Md3eWindowSizeClass.expanded), 3);
    expect(columns(Md3eWindowSizeClass.large), 4);
    expect(columns(Md3eWindowSizeClass.extraLarge), 4);
  });

  test('md3eComicListColumnCount on mobile', () {
    int columns(Md3eWindowSizeClass window) =>
        md3eComicListColumnCount(window, desktop: false);

    expect(columns(Md3eWindowSizeClass.compact), 1);
    expect(columns(Md3eWindowSizeClass.medium), 2);
    expect(columns(Md3eWindowSizeClass.expanded), 2);
    expect(columns(Md3eWindowSizeClass.large), 3);
    expect(columns(Md3eWindowSizeClass.extraLarge), 3);
  });
}
