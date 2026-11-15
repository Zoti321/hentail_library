import 'package:hentai_library/features/comic/domain/value_objects/library_comic_grouping.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryComicGrouping.fromStorage', () {
    test('缺失时使用默认值（按系列分组）', () {
      expect(
        LibraryComicGrouping.fromStorage(null),
        LibraryComicGrouping.bySeries,
      );
      expect(LibraryComicGrouping.defaultValue, LibraryComicGrouping.bySeries);
    });

    test('已知名称正确解析', () {
      expect(
        LibraryComicGrouping.fromStorage('none'),
        LibraryComicGrouping.none,
      );
      expect(
        LibraryComicGrouping.fromStorage('bySeries'),
        LibraryComicGrouping.bySeries,
      );
    });

    test('未知名称回退为不分组', () {
      expect(
        LibraryComicGrouping.fromStorage('byAuthor'),
        LibraryComicGrouping.none,
      );
    });
  });
}
