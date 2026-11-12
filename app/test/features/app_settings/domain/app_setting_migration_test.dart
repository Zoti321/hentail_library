import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_migration.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

void main() {
  group('migrateAppSettingJson', () {
    test('maps legacy vertical reader flags to webtoon reading mode', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'readerIsVertical': true,
      });

      expect(
        setting.readingModeId,
        ReadingPreferenceSchema.readingModeWebtoonId,
      );
      expect(setting.toJson().containsKey('readerIsVertical'), isFalse);
    });

    test('maps legacy dualPageNoCover onto dualPage', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'readingMode': 'dualPageNoCover',
      });

      expect(
        setting.readingModeId,
        ReadingPreferenceSchema.readingModeDualPageId,
      );
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

    test('fills default fontPreference and bumps version to 6', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'version': 4,
        'themePreference': 'light',
      });

      expect(setting.version, 6);
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

    test(
      'fills defaultLibraryDisplayTarget as comics and bumps version to 6',
      () {
        final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
          'version': 5,
          'themePreference': 'light',
        });

        expect(setting.version, 6);
        expect(
          setting.defaultLibraryDisplayTarget,
          LibraryDisplayTarget.comics,
        );
        expect(setting.toJson()['defaultLibraryDisplayTarget'], 'comics');
      },
    );

    test('round-trips explicit defaultLibraryDisplayTarget', () {
      final AppSetting setting = AppSetting(
        defaultLibraryDisplayTarget: LibraryDisplayTarget.series,
      );
      expect(
        AppSetting.fromJson(setting.toJson()).defaultLibraryDisplayTarget,
        LibraryDisplayTarget.series,
      );
    });
  });

  group('legacy import helpers', () {
    test(
      'legacyResourceFormatPayloadFromJson preserves explicit empty list',
      () {
        expect(
          legacyResourceFormatPayloadFromJson(<String, dynamic>{
            'enabledFormatGroups': <String>[],
          }).enabledFormatGroups,
          isEmpty,
        );
      },
    );

    test(
      'legacyResourceFormatPayloadFromJson defaults to all groups when absent',
      () {
        expect(
          legacyResourceFormatPayloadFromJson(<String, dynamic>{})
              .enabledFormatGroups,
          isNull,
        );
      },
    );

    test('legacyAutoScanFromJson returns null when absent', () {
      expect(legacyAutoScanFromJson(<String, dynamic>{}), isNull);
      expect(
        legacyAutoScanFromJson(<String, dynamic>{'autoScan': true}),
        isTrue,
      );
    });
  });
}
