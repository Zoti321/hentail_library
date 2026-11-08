import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_migration.dart';
import 'package:hentai_library/features/read_session/domain/reading_mode.dart';
import 'package:hentai_library/features/library_admin/public.dart';

void main() {
  group('migrateAppSettingJson', () {
    test('maps legacy vertical reader flags to webtoon reading mode', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'readerIsVertical': true,
      });

      expect(setting.readingMode, ReadingMode.webtoon);
      expect(setting.toJson().containsKey('readerIsVertical'), isFalse);
    });

    test('maps legacy dualPageNoCover onto dualPage', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'readingMode': 'dualPageNoCover',
      });

      expect(setting.readingMode, ReadingMode.dualPage);
      expect(setting.toJson()['readingMode'], 'dualPage');
    });

    test(
      'drops legacy autoScan and enabledFormatGroups from AppSetting JSON',
      () {
        final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
          'autoScan': true,
          'enabledFormatGroups': <String>['pdf'],
          'readerAutoPlayEnabled': true,
          'readerAutoPlayIntervalSeconds': 8,
        });

        expect(setting.readerAutoPlayIntervalSeconds, 8);
        expect(setting.toJson().containsKey('autoScan'), isFalse);
        expect(setting.toJson().containsKey('enabledFormatGroups'), isFalse);
        expect(setting.toJson().containsKey('readerAutoPlayEnabled'), isFalse);
      },
    );

    test('fills default fontPreference and bumps version to 5', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'version': 4,
        'themePreference': 'light',
      });

      expect(setting.version, 5);
      expect(setting.fontPreference, AppFontPreference.miSans);
      expect(setting.toJson()['fontPreference'], 'miSans');
    });

    test('round-trips explicit fontPreference', () {
      final AppSetting setting = AppSetting(
        fontPreference: AppFontPreference.notoSans,
      );
      expect(
        AppSetting.fromJson(setting.toJson()).fontPreference,
        AppFontPreference.notoSans,
      );
    });

    test('maps legacy SC/JP fontPreference onto notoSans', () {
      final AppSetting fromSc = AppSetting.fromJson(<String, dynamic>{
        'version': 5,
        'fontPreference': 'notoSansSc',
      });
      final AppSetting fromJp = AppSetting.fromJson(<String, dynamic>{
        'version': 5,
        'fontPreference': 'notoSansJp',
      });
      expect(fromSc.fontPreference, AppFontPreference.notoSans);
      expect(fromJp.fontPreference, AppFontPreference.notoSans);
    });
  });

  group('legacy import helpers', () {
    test('legacyEnabledResourceFormatCategoriesFromJson preserves explicit empty list', () {
      expect(
        legacyEnabledResourceFormatCategoriesFromJson(<String, dynamic>{
          'enabledFormatGroups': <String>[],
        }),
        isEmpty,
      );
    });

    test('legacyEnabledResourceFormatCategoriesFromJson defaults to all groups when absent', () {
      expect(
        legacyEnabledResourceFormatCategoriesFromJson(<String, dynamic>{}),
        ResourceFormatCategory.all,
      );
    });

    test('legacyAutoScanFromJson returns null when absent', () {
      expect(legacyAutoScanFromJson(<String, dynamic>{}), isNull);
      expect(
        legacyAutoScanFromJson(<String, dynamic>{'autoScan': true}),
        isTrue,
      );
    });
  });
}
