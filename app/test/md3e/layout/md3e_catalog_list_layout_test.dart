import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_list_layout.dart';

void main() {
  test('md3eComicListColumnCount uses two columns from expanded up', () {
    expect(
      md3eComicListColumnCount(Md3eWindowSizeClass.compact),
      1,
    );
    expect(
      md3eComicListColumnCount(Md3eWindowSizeClass.medium),
      1,
    );
    expect(
      md3eComicListColumnCount(Md3eWindowSizeClass.expanded),
      2,
    );
    expect(
      md3eComicListColumnCount(Md3eWindowSizeClass.large),
      2,
    );
  });
}
