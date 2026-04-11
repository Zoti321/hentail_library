import 'package:hentai_library/data/repository/app_setting_repo_impl.dart';
import 'package:hentai_library/presentation/providers/deps/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../domain/entity/entities.dart' show AppSetting;

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSetting> build() async {
    return await ref.read(appSettingRepoProvider).load();
  }

  Future<void> updateSettings(AppSetting newSetting) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(appSettingRepoProvider).save(newSetting);
      return newSetting;
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
    updateSettings(AppSettingRepoImpl.defaultSettings());
  }
}
