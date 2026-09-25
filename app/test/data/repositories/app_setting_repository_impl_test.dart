import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/data/repositories/app_setting_storage.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryLegacySettingsJsonFile implements LegacySettingsJsonFile {
  _MemoryLegacySettingsJsonFile([this._content]);

  String? _content;

  @override
  Future<bool> exists() async => _content != null;

  @override
  Future<String> readAsString() async => _content!;

  @override
  Future<void> delete() async {
    _content = null;
  }
}

void main() {
  group('AppSettingRepositoryImpl', () {
    test(
      'load imports legacy settings.json into SharedPreferences and deletes file',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final _MemoryLegacySettingsJsonFile legacyFile =
            _MemoryLegacySettingsJsonFile(
              jsonEncode(<String, dynamic>{
                'themePreference': 'dark',
                'autoScan': true,
                'enabledFormatGroups': <String>['pdf'],
              }),
            );
        final AppSettingRepositoryImpl repo = AppSettingRepositoryImpl(
          sharedPreferences: prefs,
          legacySettingsFile: legacyFile,
        );

        final AppSetting loaded = await repo.load();

        expect(loaded.themePreference, AppThemePreference.dark);
        expect(await legacyFile.exists(), isFalse);
        expect(prefs.containsKey(AppSettingStorageKeys.aggregateJson), isTrue);
        expect(
          prefs.getBool(AppSettingStorageKeys.legacyImportAutoScan),
          isTrue,
        );
        expect(
          prefs.getString(AppSettingStorageKeys.legacyImportFormatGroups),
          jsonEncode(<String>['pdf']),
        );
      },
    );

    test('second load is idempotent and does not re-import', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _MemoryLegacySettingsJsonFile legacyFile =
          _MemoryLegacySettingsJsonFile(
            jsonEncode(<String, dynamic>{'themePreference': 'light'}),
          );
      final AppSettingRepositoryImpl repo = AppSettingRepositoryImpl(
        sharedPreferences: prefs,
        legacySettingsFile: legacyFile,
      );

      await repo.load();
      legacyFile._content = jsonEncode(<String, dynamic>{
        'themePreference': 'dark',
      });
      final AppSetting second = await repo.load();

      expect(second.themePreference, AppThemePreference.light);
    });

    test('save round-trips through SharedPreferences aggregate key', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingRepositoryImpl repo = AppSettingRepositoryImpl(
        sharedPreferences: prefs,
        legacySettingsFile: _MemoryLegacySettingsJsonFile(),
      );
      final AppSetting setting = AppSetting(
        themePreference: AppThemePreference.dark,
        localePreference: AppLocalePreference.en,
        readerAutoPlayIntervalSeconds: 9,
      );

      await repo.save(setting);
      final AppSetting loaded = await repo.load();

      expect(loaded.themePreference, AppThemePreference.dark);
      expect(loaded.localePreference, AppLocalePreference.en);
      expect(loaded.readerAutoPlayIntervalSeconds, 9);
      expect(loaded.toJson().containsKey('enabledFormatGroups'), isFalse);
    });

    test('peekLegacy reads staged payload after import', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _MemoryLegacySettingsJsonFile legacyFile =
          _MemoryLegacySettingsJsonFile(
            jsonEncode(<String, dynamic>{
              'autoScan': true,
              'enabledFormatGroups': <String>['epub', 'archive'],
            }),
          );
      final AppSettingRepositoryImpl repo = AppSettingRepositoryImpl(
        sharedPreferences: prefs,
        legacySettingsFile: legacyFile,
      );
      await repo.load();

      expect(await repo.peekLegacyAutoScan(), isTrue);
      expect(await repo.peekLegacyEnabledFormatGroups(), <FormatGroup>[
        FormatGroup.epub,
        FormatGroup.archive,
      ]);
    });
  });
}
