import 'package:hentai_library/domain/entity/entities.dart' show AppSetting;
import 'package:hentai_library/presentation/providers/deps/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSetting> build() async {
    return ref.read(appSettingRepoProvider).load();
  }

  Future<void> updateSettings(AppSetting newSetting) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(appSettingRepoProvider).save(newSetting);
      return newSetting;
    });
  }

  Future<void> toggleDarkMode() async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(isDarkMode: !current.isDarkMode));
  }

  Future<void> toggleHealthyMode() async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(
      current.copyWith(isHealthyMode: !current.isHealthyMode),
    );
  }

  Future<void> setAutoScan(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(autoScan: value));
  }

  Future<void> resetToDefaults() async {
    await updateSettings(AppSetting());
  }
}
