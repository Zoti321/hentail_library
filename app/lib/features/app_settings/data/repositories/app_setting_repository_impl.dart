import 'dart:convert';
import 'dart:io';

import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/app_settings/data/repositories/app_setting_storage.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_migration.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';
import 'package:hentai_library/features/app_settings/domain/legacy_browse_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Legacy settings.json access for tests and production.
abstract class LegacySettingsJsonFile {
  Future<bool> exists();

  Future<String> readAsString();

  Future<void> delete();
}

class _ApplicationSupportLegacySettingsJsonFile
    implements LegacySettingsJsonFile {
  static const String fileName = 'settings.json';

  @override
  Future<bool> exists() async => (await _file()).exists();

  @override
  Future<String> readAsString() async => (await _file()).readAsString();

  @override
  Future<void> delete() async {
    final File file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }
}

class AppSettingRepositoryImpl implements AppSettingRepository {
  AppSettingRepositoryImpl({this._sharedPreferences, this._legacySettingsFile});

  final SharedPreferences? _sharedPreferences;
  final LegacySettingsJsonFile? _legacySettingsFile;

  Future<SharedPreferences> _prefs() async =>
      _sharedPreferences ?? await SharedPreferences.getInstance();

  Future<LegacySettingsJsonFile> _legacyFile() async =>
      _legacySettingsFile ?? _ApplicationSupportLegacySettingsJsonFile();

  @override
  Future<AppSetting> load() async {
    try {
      final SharedPreferences prefs = await _prefs();
      if (!prefs.containsKey(AppSettingStorageKeys.aggregateJson)) {
        await _importLegacySettingsJsonIfPresent(prefs);
      }
      final String? raw = prefs.getString(AppSettingStorageKeys.aggregateJson);
      AppSetting setting;
      if (raw == null || raw.isEmpty) {
        setting = defaultSettings();
      } else {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        setting = AppSetting.fromJson(json);
      }
      setting = await _migratePreferLibraryRootSeriesFromBrowsePrefs(
        prefs,
        setting,
      );
      setting = await _migrateSmartFacetMatchFromLegacyKey(prefs, setting);
      return setting;
    } catch (e, st) {
      logError(AppLog.dataRepo('app_setting'), '加载设置失败，已回退默认值', e, st);
      return defaultSettings();
    }
  }

  @override
  Future<void> save(AppSetting setting) async {
    try {
      final SharedPreferences prefs = await _prefs();
      await prefs.setString(
        AppSettingStorageKeys.aggregateJson,
        jsonEncode(setting.toJson()),
      );
    } catch (e, st) {
      logError(AppLog.dataRepo('app_setting'), '保存设置失败', e, st);
      rethrow;
    }
  }

  @override
  Future<bool?> peekLegacyAutoScan() async {
    try {
      final Map<String, dynamic>? raw = await _readLegacyJsonMap();
      if (raw != null) {
        return legacyAutoScanFromJson(raw);
      }
      final SharedPreferences prefs = await _prefs();
      if (!prefs.containsKey(AppSettingStorageKeys.legacyImportAutoScan)) {
        return null;
      }
      return prefs.getBool(AppSettingStorageKeys.legacyImportAutoScan);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<({Object? enabledFormatGroups})?>
  peekLegacyResourceFormatPayload() async {
    try {
      final Map<String, dynamic>? raw = await _readLegacyJsonMap();
      if (raw != null) {
        return legacyResourceFormatPayloadFromJson(raw);
      }
      final SharedPreferences prefs = await _prefs();
      final String? staged = prefs.getString(
        AppSettingStorageKeys.legacyImportResourceFormatCategories,
      );
      if (staged == null || staged.isEmpty) {
        return null;
      }
      final Object? decoded = jsonDecode(staged);
      return (enabledFormatGroups: decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearLegacyImportPayload() async {
    final SharedPreferences prefs = await _prefs();
    await prefs.remove(AppSettingStorageKeys.legacyImportAutoScan);
    await prefs.remove(
      AppSettingStorageKeys.legacyImportResourceFormatCategories,
    );
  }

  Future<void> _importLegacySettingsJsonIfPresent(
    SharedPreferences prefs,
  ) async {
    final LegacySettingsJsonFile legacyFile = await _legacyFile();
    if (!await legacyFile.exists()) {
      return;
    }
    final String jsonStr = await legacyFile.readAsString();
    final Map<String, dynamic> raw =
        jsonDecode(jsonStr) as Map<String, dynamic>;

    final bool? legacyAutoScan = legacyAutoScanFromJson(raw);
    if (legacyAutoScan != null) {
      await prefs.setBool(
        AppSettingStorageKeys.legacyImportAutoScan,
        legacyAutoScan,
      );
    }
    final ({Object? enabledFormatGroups}) legacyGroups =
        legacyResourceFormatPayloadFromJson(raw);
    await prefs.setString(
      AppSettingStorageKeys.legacyImportResourceFormatCategories,
      jsonEncode(legacyGroups.enabledFormatGroups),
    );

    final AppSetting setting = AppSetting.fromJson(raw);
    await prefs.setString(
      AppSettingStorageKeys.aggregateJson,
      jsonEncode(setting.toJson()),
    );
    await legacyFile.delete();
  }

  Future<Map<String, dynamic>?> _readLegacyJsonMap() async {
    final LegacySettingsJsonFile legacyFile = await _legacyFile();
    if (!await legacyFile.exists()) {
      return null;
    }
    final String jsonStr = await legacyFile.readAsString();
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  static AppSetting defaultSettings() => AppSetting();

  Future<AppSetting> _migratePreferLibraryRootSeriesFromBrowsePrefs(
    SharedPreferences prefs,
    AppSetting setting,
  ) async {
    if (!prefs.containsKey(LegacyLibraryPreferLibraryRootSeries.storageKey)) {
      return setting;
    }
    final bool legacy = LegacyLibraryPreferLibraryRootSeries.fromStorage(
      prefs.getBool(LegacyLibraryPreferLibraryRootSeries.storageKey),
    );
    final AppSetting migrated = setting.copyWith(
      preferLibraryRootSeries: legacy,
    );
    await save(migrated);
    await prefs.remove(LegacyLibraryPreferLibraryRootSeries.storageKey);
    return migrated;
  }

  /// 智能匹配旧键只在**存在**时迁入并删除；旧键缺失时不写盘（避免把默认值落地）。
  Future<AppSetting> _migrateSmartFacetMatchFromLegacyKey(
    SharedPreferences prefs,
    AppSetting setting,
  ) async {
    if (!prefs.containsKey(LegacySmartFacetMatchPreference.storageKey)) {
      return setting;
    }
    final bool legacy = LegacySmartFacetMatchPreference.fromStorage(
      prefs.getBool(LegacySmartFacetMatchPreference.storageKey),
    );
    final AppSetting migrated = setting.copyWith(
      smartFacetMatchEnabled: legacy,
    );
    await save(migrated);
    await prefs.remove(LegacySmartFacetMatchPreference.storageKey);
    return migrated;
  }
}
