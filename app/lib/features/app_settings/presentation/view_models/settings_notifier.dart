import 'dart:async';

import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSetting> build() async {
    return ref.read(appSettingRepositoryProvider).load();
  }

  Future<void> updateSettings(AppSetting newSetting) async {
    final AppSetting? rollback = state.asData?.value;
    state = AsyncData<AppSetting>(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = rollback != null
          ? AsyncData<AppSetting>(rollback)
          : AsyncError<AppSetting>(error, stackTrace);
    }
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(themePreference: value));
  }

  Future<void> setColorSchemePreference(AppColorSchemePreference value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(colorSchemePreference: value));
  }

  Future<void> setUseDynamicColor(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(useDynamicColor: value));
  }

  Future<void> setLocalePreference(AppLocalePreference value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(localePreference: value));
  }

  Future<void> setFontPreference(AppFontPreference value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(fontPreference: value));
  }

  Future<void> setAutoUpdate(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(autoUpdate: value));
  }

  Future<void> setHealthyMode(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(healthyMode: value));
  }

  Future<void> setPreferLibraryRootSeries(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(preferLibraryRootSeries: value));
  }

  Future<void> setDefaultLibraryDisplayTarget(
    LibraryDisplayTarget value,
  ) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(defaultLibraryDisplayTarget: value));
  }

  Future<void> setDismissedUpdateVersion(String value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.withDismissedUpdateVersion(value));
  }

  Future<void> setSmartFacetMatchEnabled(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(smartFacetMatchEnabled: value));
  }

  Future<void> setReadingModeId(String id) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(readingModeId: id);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setWebtoonMarginPercent(int value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.withWebtoonMarginPercent(value);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setWebtoonZoomModeId(String id) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(webtoonZoomModeId: id);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setReaderAutoPlayIntervalSeconds(int value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.withReaderAutoPlayIntervalSeconds(
      value,
    );
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setAutoPlayModeId(String id) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(autoPlayModeId: id);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setDesktopSidebarExpanded(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(
      desktopSidebarExpanded: value,
    );
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepositoryProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> resetToDefaults() async {
    await updateSettings(AppSetting());
  }
}
