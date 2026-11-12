import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/features/app_settings/public/presentation/settings_view_model_exports.dart';

export 'package:hentai_library/features/app_settings/public/di/app_setting_repository_factory.dart'
    show appSettingRepositoryProvider;

/// 应用设置（唯一读入口，ADR-0046）。
///
/// 取代 `shared/di` 的 `appSettingsStateProvider` / `appSettingsFutureProvider`：
/// 需要 future 时用 `.future`，需要写入口时用 `.notifier`。
/// 用别名而非包装 provider，保证 `.future` / `.select` 形态与 owner 一致。
final appSettingsProvider = settingsProvider;

/// L1 传输记录：持久化原语投影；`null` 表示设置尚未加载完成。
final Provider<ReadingPreferencesRecord?> readingPreferencesRecordProvider =
    Provider<ReadingPreferencesRecord?>((Ref ref) {
      final AppSetting? setting = ref.watch(appSettingsProvider).asData?.value;
      return setting == null ? null : readingPreferencesRecordOf(setting);
    });

/// [AppSetting] → L1 记录（唯一投影点）。
ReadingPreferencesRecord readingPreferencesRecordOf(AppSetting setting) {
  return (
    readingModeId: setting.readingModeId,
    webtoonZoomModeId: setting.webtoonZoomModeId,
    webtoonMarginPercent: setting.webtoonMarginPercent,
    autoPlayModeId: setting.autoPlayModeId,
    autoPlayIntervalSeconds: setting.readerAutoPlayIntervalSeconds,
  );
}

/// 阅读偏好**唯一写入口**（ADR-0046）。
///
/// 只有五个按字段写入的方法，参数是持久化原语；不提供整条 record 的整体写入，
/// 避免并发覆盖。设置页「阅读」分区与阅读器内面板都必须经本 controller。
final Provider<ReadingPreferencesController>
readingPreferencesControllerProvider = Provider<ReadingPreferencesController>(
  ReadingPreferencesController.new,
);

final class ReadingPreferencesController {
  ReadingPreferencesController(this._ref);

  final Ref _ref;

  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);

  Future<void> setReadingModeId(String id) => _settings.setReadingModeId(id);

  Future<void> setWebtoonZoomModeId(String id) =>
      _settings.setWebtoonZoomModeId(id);

  Future<void> setWebtoonMarginPercent(int percent) =>
      _settings.setWebtoonMarginPercent(percent);

  Future<void> setAutoPlayModeId(String id) => _settings.setAutoPlayModeId(id);

  Future<void> setAutoPlayIntervalSeconds(int seconds) =>
      _settings.setReaderAutoPlayIntervalSeconds(seconds);
}
