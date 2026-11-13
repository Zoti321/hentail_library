import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/public/library_comic_browse_rules.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/infrastructure/library_browse_preferences_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('migrateLegacyLibraryAgeRestriction', () {
    Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    test('旧键存在、双键皆无：写入双键并删除旧键', () async {
      final SharedPreferences prefs = await prefsWith(<String, Object>{
        kLegacyLibraryAgeRestrictionStorageKey:
            LibraryAgeRestrictionFilter.r18Only.name,
      });

      await migrateLegacyLibraryAgeRestriction(prefs);

      expect(
        prefs.getString(kLibraryComicsAgeRestrictionStorageKey),
        LibraryAgeRestrictionFilter.r18Only.name,
      );
      expect(
        prefs.getString(kLibrarySeriesAgeRestrictionStorageKey),
        LibraryAgeRestrictionFilter.r18Only.name,
      );
      expect(
        prefs.containsKey(kLegacyLibraryAgeRestrictionStorageKey),
        isFalse,
      );
    });

    test('双键已存在：不迁移、不覆盖、旧键保留', () async {
      final SharedPreferences prefs = await prefsWith(<String, Object>{
        kLegacyLibraryAgeRestrictionStorageKey:
            LibraryAgeRestrictionFilter.r18Only.name,
        kLibraryComicsAgeRestrictionStorageKey:
            LibraryAgeRestrictionFilter.allAges.name,
      });

      await migrateLegacyLibraryAgeRestriction(prefs);

      expect(
        prefs.getString(kLibraryComicsAgeRestrictionStorageKey),
        LibraryAgeRestrictionFilter.allAges.name,
      );
      expect(prefs.getString(kLibrarySeriesAgeRestrictionStorageKey), isNull);
      expect(
        prefs.getString(kLegacyLibraryAgeRestrictionStorageKey),
        LibraryAgeRestrictionFilter.r18Only.name,
      );
    });

    test('旧值为 unrestricted：不写双键，仅删除旧键', () async {
      final SharedPreferences prefs = await prefsWith(<String, Object>{
        kLegacyLibraryAgeRestrictionStorageKey:
            LibraryAgeRestrictionFilter.unrestricted.name,
      });

      await migrateLegacyLibraryAgeRestriction(prefs);

      expect(prefs.getString(kLibraryComicsAgeRestrictionStorageKey), isNull);
      expect(prefs.getString(kLibrarySeriesAgeRestrictionStorageKey), isNull);
      expect(
        prefs.containsKey(kLegacyLibraryAgeRestrictionStorageKey),
        isFalse,
      );
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
