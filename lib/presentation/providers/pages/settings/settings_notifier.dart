import 'package:hentai_library/data/models/app_settings.dart';
import 'package:hentai_library/data/services/settings/settings.dart' as data_settings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

/// 不使用 codegen provider，避免需要重新运行 build_runner 才可编译。
final settingsStorageServiceDiProvider =
    Provider<data_settings.SettingsStorageService>((ref) {
      return data_settings.SettingsStorageService();
    });

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return await ref.read(settingsStorageServiceDiProvider).loadSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsStorageServiceDiProvider).saveSettings(newSettings);
      return newSettings;
    });
  }

  Future<void> toggleDarkMode() async {
    state.whenData((data) {
      updateSettings(data.copyWith(isDarkMode: !data.isDarkMode));
    });
  }

  Future<void> toggleHealthyMode() async {
    state.whenData((data) {
      updateSettings(data.copyWith(isHealthyMode: !data.isHealthyMode));
    });
  }

  Future<void> setAutoScan(bool value) async {
    state.whenData((data) {
      updateSettings(data.copyWith(autoScan: value));
    });
  }

  Future<void> resetToDefaults() async {
    updateSettings(ref.read(settingsStorageServiceDiProvider).defaultSettings());
  }
}
