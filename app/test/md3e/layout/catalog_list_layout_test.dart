import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';

void main() {
  test('comicListColumnCount on desktop', () {
    int columns(WindowSizeClass window) =>
        comicListColumnCount(window, desktop: true);

    expect(columns(WindowSizeClass.compact), 1);
    expect(columns(WindowSizeClass.medium), 2);
    expect(columns(WindowSizeClass.expanded), 3);
    expect(columns(WindowSizeClass.large), 4);
    expect(columns(WindowSizeClass.extraLarge), 4);
  });

  test('comicListColumnCount on mobile', () {
    int columns(WindowSizeClass window) =>
        comicListColumnCount(window, desktop: false);

    expect(columns(WindowSizeClass.compact), 1);
    expect(columns(WindowSizeClass.medium), 2);
    expect(columns(WindowSizeClass.expanded), 2);
    expect(columns(WindowSizeClass.large), 3);
    expect(columns(WindowSizeClass.extraLarge), 3);
  });
}
