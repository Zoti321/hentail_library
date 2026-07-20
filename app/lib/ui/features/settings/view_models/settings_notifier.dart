import 'dart:async';

import 'package:hentai_library/domain/models/models.dart'
    show AppLocalePreference, AppSetting, AppThemePreference;
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const int _readerAutoPlayIntervalMin = 1;
  static const int _readerAutoPlayIntervalMax = 60;

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

  Future<void> setLocalePreference(AppLocalePreference value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(localePreference: value));
  }

  Future<void> setAutoScan(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(autoScan: value));
  }

  Future<void> setAutoUpdate(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(autoUpdate: value));
  }

  Future<void> setDismissedUpdateVersion(String value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(dismissedUpdateVersion: value));
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

  Future<void> setReaderAutoPlayEnabled(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(
      readerAutoPlayEnabled: value,
    );
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
    final int normalizedValue = value.clamp(
      _readerAutoPlayIntervalMin,
      _readerAutoPlayIntervalMax,
    );
    final AppSetting newSetting = current.copyWith(
      readerAutoPlayIntervalSeconds: normalizedValue,
    );
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
