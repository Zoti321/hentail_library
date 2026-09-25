import 'dart:convert';
import 'dart:io';

import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/data/repositories/app_setting_storage.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting_migration.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
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
  AppSettingRepositoryImpl({
    SharedPreferences? sharedPreferences,
    LegacySettingsJsonFile? legacySettingsFile,
  }) : _sharedPreferences = sharedPreferences,
       _legacySettingsFile = legacySettingsFile;

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
      if (raw == null || raw.isEmpty) {
        return defaultSettings();
      }
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return AppSetting.fromJson(json);
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
  Future<List<FormatGroup>?> peekLegacyEnabledFormatGroups() async {
    try {
      final Map<String, dynamic>? raw = await _readLegacyJsonMap();
      if (raw != null) {
        return legacyEnabledFormatGroupsFromJson(raw);
      }
      final SharedPreferences prefs = await _prefs();
      final String? staged = prefs.getString(
        AppSettingStorageKeys.legacyImportFormatGroups,
      );
      if (staged == null || staged.isEmpty) {
        return null;
      }
      final Object? decoded = jsonDecode(staged);
      return formatGroupsFromStorage(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearLegacyImportPayload() async {
    final SharedPreferences prefs = await _prefs();
    await prefs.remove(AppSettingStorageKeys.legacyImportAutoScan);
    await prefs.remove(AppSettingStorageKeys.legacyImportFormatGroups);
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
    final List<FormatGroup> legacyGroups = legacyEnabledFormatGroupsFromJson(
      raw,
    );
    await prefs.setString(
      AppSettingStorageKeys.legacyImportFormatGroups,
      jsonEncode(formatGroupsToStorage(legacyGroups)),
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
}
