import 'dart:async';

import 'package:hentai_library/shared/domain/models/models.dart'
    show
        AppColorSchemePreference,
        AppLocalePreference,
        AppSetting,
        AppThemePreference;
import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSetting> build() async {
    return ref.read(appSettingRepoProvider).load();
  }

  Future<void> updateSettings(AppSetting newSetting) async {
    final AppSetting? rollback = state.asData?.value;
    state = AsyncData<AppSetting>(newSetting);
    try {
      await ref.read(appSettingRepoProvider).save(newSetting);
    } catch (error, stackTrace) {
      if (rollback != null) {
        state = AsyncData<AppSetting>(rollback);
      } else {
        state = AsyncError<AppSetting>(error, stackTrace);
      }
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

  Future<void> setDismissedUpdateVersion(String value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.withDismissedUpdateVersion(value));
  }

  Future<void> setReadingMode(ReadingMode value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(readingMode: value);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepoProvider).save(newSetting);
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
      await ref.read(appSettingRepoProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setWebtoonZoomMode(WebtoonZoomMode value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(webtoonZoomMode: value);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepoProvider).save(newSetting);
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
      await ref.read(appSettingRepoProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setAutoPlayMode(AutoPlayMode value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(autoPlayMode: value);
    state = AsyncData(newSetting);
    try {
      await ref.read(appSettingRepoProvider).save(newSetting);
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
      await ref.read(appSettingRepoProvider).save(newSetting);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> resetToDefaults() async {
    await updateSettings(AppSetting());
  }
}
