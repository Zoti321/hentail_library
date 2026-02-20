import 'dart:async';

import 'package:hentai_library/domain/entity/entities.dart'
    show AppSetting, AppThemePreference;
import 'package:hentai_library/presentation/providers/deps/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const double _readerDimLevelMin = 0.0;
  static const double _readerDimLevelMax = 0.8;
  static const int _readerAutoPlayIntervalMin = 1;
  static const int _readerAutoPlayIntervalMax = 60;
  static const Duration _readerDimLevelPersistDebounce = Duration(
    milliseconds: 400,
  );
  Timer? _readerDimLevelPersistDebounceTimer;
  bool _hasPendingReaderDimPersist = false;

  @override
  Future<AppSetting> build() async {
    ref.onDispose(() {
      _readerDimLevelPersistDebounceTimer?.cancel();
      if (_hasPendingReaderDimPersist) {
        unawaited(_persistReaderDimLevelIfNeeded());
      }
    });
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

  Future<void> setLibraryHideComicsInSeries(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(libraryHideComicsInSeries: value));
  }

  Future<void> setArchiveCoverDiskCacheEnabled(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    await updateSettings(current.copyWith(archiveCoverDiskCacheEnabled: value));
  }

  Future<void> setReaderDimLevel(double value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final double normalizedValue = value.clamp(
      _readerDimLevelMin,
      _readerDimLevelMax,
    );
    final AppSetting newSetting = current.copyWith(
      readerDimLevel: normalizedValue,
    );
    state = AsyncData(newSetting);
    _hasPendingReaderDimPersist = true;
    _readerDimLevelPersistDebounceTimer?.cancel();
    _readerDimLevelPersistDebounceTimer = Timer(
      _readerDimLevelPersistDebounce,
      () => unawaited(_persistReaderDimLevelIfNeeded()),
    );
  }

  Future<void> setReaderIsVertical(bool value) async {
    final AppSetting? current = state.asData?.value;
    if (current == null) return;
    final AppSetting newSetting = current.copyWith(readerIsVertical: value);
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

  Future<void> _persistReaderDimLevelIfNeeded() async {
    if (!_hasPendingReaderDimPersist) {
      return;
    }
    if (state.isLoading) {
      _readerDimLevelPersistDebounceTimer?.cancel();
      _readerDimLevelPersistDebounceTimer = Timer(
        const Duration(milliseconds: 100),
        () => unawaited(_persistReaderDimLevelIfNeeded()),
      );
      return;
    }
    final AppSetting? current = state.asData?.value;
    if (current == null) {
      return;
    }
    _hasPendingReaderDimPersist = false;
    try {
      await ref.read(appSettingRepoProvider).save(current);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
