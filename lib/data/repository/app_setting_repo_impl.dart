import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/repository/app_setting_repo.dart';

import '../../domain/entity/entities.dart' show AppSetting;

class AppSettingRepoImpl implements AppSettingRepository {
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
      LogManager.instance.handle(e, st, '[APP_SETTING_REPO] 加载设置失败，已回退默认值');
      return defaultSettings();
    }
  }

  @override
  Future<void> save(AppSetting setting) async {
    try {
      final file = await _getSettingsFile();

      await file.writeAsString(jsonEncode(setting.toJson()), flush: true);
    } catch (e, st) {
      LogManager.instance.handle(e, st, '[APP_SETTING_REPO] 保存设置失败');
      rethrow;
    }
  }

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static AppSetting defaultSettings() => AppSetting();
}
