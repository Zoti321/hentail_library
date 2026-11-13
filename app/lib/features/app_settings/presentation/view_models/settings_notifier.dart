import 'dart:async';

import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  Future<void>? _saveTail;
  AppSetting? _lastSuccessful;
  int _saveRevision = 0;

  @override
  Future<AppSetting> build() async {
    return ref.read(appSettingRepositoryProvider).load();
  }

  Future<void> updateSettings(AppSetting newSetting) =>
      _saveSettings(newSetting);

  Future<void> _saveSettings(
    AppSetting newSetting, {
    bool rollbackOnError = true,
  }) {
    final Future<void>? previous = _saveTail;
    final bool canRollback = state.asData != null;
    if (previous == null) {
      _lastSuccessful = state.asData?.value;
    }
    late final Future<void> Function() save;
    try {
      final repository = ref.read(appSettingRepositoryProvider);
      save = () => repository.save(newSetting);
    } catch (error, stackTrace) {
      save = () => Error.throwWithStackTrace(error, stackTrace);
    }
    final int revision = ++_saveRevision;
    final Completer<void> completion = Completer<void>();
    final Future<void> pending = completion.future;
    _saveTail = pending;
    state = AsyncData<AppSetting>(newSetting);
    completion.complete(() async {
      try {
        if (previous != null) {
          await previous;
        }
        await save();
        _lastSuccessful = newSetting;
      } catch (error, stackTrace) {
        if (ref.mounted && revision == _saveRevision) {
          final AppSetting? rollback = _lastSuccessful;
          state = rollbackOnError && canRollback && rollback != null
              ? AsyncData<AppSetting>(rollback)
              : AsyncError<AppSetting>(error, stackTrace);
        }
      } finally {
        if (identical(_saveTail, pending)) {
          _saveTail = null;
        }
      }
    }());
    return pending;
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
    await _saveSettings(newSetting, rollbackOnError: false);
  }

  Future<void> setWebtoonMarginPercent(int value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.withWebtoonMarginPercent(value);
    await _saveSettings(newSetting, rollbackOnError: false);
  }

  Future<void> setWebtoonZoomModeId(String id) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(webtoonZoomModeId: id);
    await _saveSettings(newSetting, rollbackOnError: false);
  }

  Future<void> setReaderAutoPlayIntervalSeconds(int value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.withReaderAutoPlayIntervalSeconds(
      value,
    );
    await _saveSettings(newSetting, rollbackOnError: false);
  }

  Future<void> setAutoPlayModeId(String id) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(autoPlayModeId: id);
    await _saveSettings(newSetting, rollbackOnError: false);
  }

  Future<void> setDesktopSidebarExpanded(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(
      desktopSidebarExpanded: value,
    );
    await _saveSettings(newSetting, rollbackOnError: false);
  }

  Future<void> resetToDefaults() async {
    await updateSettings(AppSetting());
  }
}
