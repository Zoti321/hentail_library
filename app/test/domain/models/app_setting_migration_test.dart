import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/models/app_setting_migration.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';

void main() {
  group('migrateAppSettingJson', () {
    test('maps legacy vertical reader flags to webtoon reading mode', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'readerIsVertical': true,
      });

      expect(setting.readingMode, ReadingMode.webtoon);
      expect(setting.toJson().containsKey('readerIsVertical'), isFalse);
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
  });

  group('legacy import helpers', () {
    test('legacyEnabledFormatGroupsFromJson preserves explicit empty list', () {
      expect(
        legacyEnabledFormatGroupsFromJson(<String, dynamic>{
          'enabledFormatGroups': <String>[],
        }),
        isEmpty,
      );
    });

    test(
      'legacyEnabledFormatGroupsFromJson defaults to all groups when absent',
      () {
        expect(
          legacyEnabledFormatGroupsFromJson(<String, dynamic>{}),
          FormatGroup.all,
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
