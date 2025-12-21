import 'package:hentai_library/data/models/app_settings.dart';
import 'package:hentai_library/data/services/settings/settings.dart' as data_settings;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  final _storage = data_settings.SettingsStorageService();

  @override
  Future<AppSettings> build() async {
    return await _storage.loadSettings();
  }

  // 更新整个设置对象
  Future<void> updateSettings(AppSettings newSettings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _storage.saveSettings(newSettings);
      return newSettings;
    });
  }

  // 切换深色模式
  Future<void> toggleDarkMode() async {
    state.whenData((data) {
      updateSettings(data.copyWith(isDarkMode: !data.isDarkMode));
    });
  }

  Future<void> toggleR18Mode() async {
    state.whenData((data) {
      updateSettings(data.copyWith(isR18Mode: !data.isR18Mode));
    });
  }

  Future<void> setAutoScan(bool value) async {
    state.whenData((data) {
      updateSettings(data.copyWith(autoScan: value));
    });
  }

  // 重置为默认设置
  Future<void> resetToDefaults() async {
    updateSettings(_storage.defaultSettings());
  }
}
