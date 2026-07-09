import 'dart:convert';
import 'dart:io';

import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppSettingRepositoryImpl implements AppSettingRepository {
  static const String _fileName = 'settings.json';

  @override
  Future<AppSetting> load() async {
    try {
      final file = await _getSettingsFile();

      if (!await file.exists()) {
        return defaultSettings();
      }

      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final AppSetting settings = AppSetting.fromJson(json);

      return settings;
    } catch (e, st) {
      logError(
        AppLog.dataRepo('app_setting'),
        '加载设置失败，已回退默认值',
        e,
        st,
      );
      return defaultSettings();
    }
  }

  @override
  Future<void> save(AppSetting setting) async {
    try {
      final file = await _getSettingsFile();

      await file.writeAsString(jsonEncode(setting.toJson()), flush: true);
    } catch (e, st) {
      logError(AppLog.dataRepo('app_setting'), '保存设置失败', e, st);
      rethrow;
    }
  }

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static AppSetting defaultSettings() => AppSetting();
}
