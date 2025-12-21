import 'dart:convert';
import 'dart:io';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/models/app_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// app 设置项读取储存服务
class SettingsStorageService {
  static const String _fileName = 'settings.json';

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  // 加载设置
  Future<AppSettings> loadSettings() async {
    try {
      final file = await _getSettingsFile();

      if (!await file.exists()) {
        return defaultSettings();
      }

      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final settings = AppSettings.fromJson(json);

      return settings;
    } catch (e, stack) {
      LogManager.instance.handle(e, stack, '加载设置失败，恢复默认值');
      return defaultSettings();
    }
  }

  // 保存设置
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final file = await _getSettingsFile();

      await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
    } catch (e, stack) {
      LogManager.instance.handle(e, stack, '保存设置失败');
      // 向上抛出，让调用方（如 SettingsNotifier.updateSettings）通过 AsyncValue.error 感知失败
      rethrow;
    }
  }

  // 默认设置
  AppSettings defaultSettings() =>
      AppSettings(isDarkMode: false, isR18Mode: false, autoScan: false);
}
