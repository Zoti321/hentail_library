import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/domain/library_comic_grouping.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('只有按系列分组覆盖排序', () {
      expect(LibraryComicGrouping.none.overridesSort, isFalse);
      expect(LibraryComicGrouping.bySeries.overridesSort, isTrue);
    });
  });

  group('migrateLegacyLibraryComicGrouping', () {
    const String legacyKey =
        LibraryComicGrouping.legacyExpandBySeriesStorageKey;
    const String newKey = LibraryComicGrouping.storageKey;

    test('旧键为 false 迁移为不分组并删除旧键', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyKey: false,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await migrateLegacyLibraryComicGrouping(prefs);

      expect(prefs.getString(newKey), 'none');
      expect(prefs.containsKey(legacyKey), isFalse);
    });

    test('旧键为 true 迁移为按系列分组（默认值，不写新键）并删除旧键', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{legacyKey: true});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await migrateLegacyLibraryComicGrouping(prefs);

      expect(prefs.containsKey(newKey), isFalse);
      expect(prefs.containsKey(legacyKey), isFalse);
      expect(
        LibraryComicGrouping.fromStorage(prefs.getString(newKey)),
        LibraryComicGrouping.bySeries,
      );
    });

    test('新键已存在时不读取旧键，且重复执行结果一致', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        newKey: 'none',
        legacyKey: true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await migrateLegacyLibraryComicGrouping(prefs);
      await migrateLegacyLibraryComicGrouping(prefs);

      expect(prefs.getString(newKey), 'none');
    });

    test('无旧键时不做任何写入', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await migrateLegacyLibraryComicGrouping(prefs);

      expect(prefs.containsKey(newKey), isFalse);
    });
  });
}
